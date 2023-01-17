package main

import (
	"flag"
	"fmt"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"sync"
	"sync/atomic"

	"github.com/aspect-build/bazel-lib/tools/common"
)

var srcPaths = make(map[string]struct{})
var copyWaitGroup sync.WaitGroup
var hasErrors atomic.Bool

func copyDir(src string, dst string, hardlink bool, verbose bool, errors chan<- error) error {
	// filepath.WalkDir walks the file tree rooted at root, calling fn for each file or directory in
	// the tree, including root. See https://pkg.go.dev/path/filepath#WalkDir for more info.
	return filepath.WalkDir(src, func(p string, dirEntry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		// Gracefully stop the walking if an error has been reported.
		if hasErrors.Load() {
			return nil
		}

		copySrc := p

		r, err := filepath.Rel(src, p)
		if err != nil {
			return err
		}

		copyDst := filepath.Join(dst, r)

		if dirEntry.IsDir() {
			srcPaths[src] = struct{}{}
			return os.MkdirAll(copyDst, os.ModePerm)
		}

		info, err := dirEntry.Info()
		if err != nil {
			return err
		}

		if info.Mode()&os.ModeSymlink == os.ModeSymlink {
			// symlink to directories are intentionally never followed by filepath.Walk to avoid infinite recursion
			linkPath, err := os.Readlink(p)
			if err != nil {
				return err
			}
			if !path.IsAbs(linkPath) {
				linkPath = path.Join(path.Dir(p), linkPath)
			}
			if _, isRecursive := srcPaths[linkPath]; isRecursive {
				// recursive symlink; silently ignore
				return nil
			}
			stat, err := os.Stat(linkPath)
			if err != nil {
				return fmt.Errorf("failed to stat file %s pointed to by symlink %s: %w", linkPath, p, err)
			}
			if stat.IsDir() {
				// symlink points to a directory
				return copyDir(linkPath, copyDst, hardlink, verbose, errors)
			} else {
				// symlink points to a regular file
				copySrc = linkPath
			}
		}

		// a regular file
		copyWaitGroup.Add(1)
		go func() {
			if err := common.Copy(copySrc, copyDst, info, hardlink, verbose, &copyWaitGroup); err != nil {
				errors <- err
			}
		}()
		return nil
	})
}

func main() {
	args := os.Args[1:]
	if len(args) == 1 && (args[0] == "--version" || args[0] == "-v") {
		fmt.Printf("copy_directory %s\n", common.Version())
		return
	}

	var hardlink bool
	var verbose bool

	flag.BoolVar(&hardlink, "hardlink", false, "use hardlinks instead of copying files")
	flag.BoolVar(&verbose, "verbose", false, "print verbose output")
	flag.Parse()

	if flag.NArg() < 2 {
		fmt.Println("Usage: copy_directory src dst [--hardlink] [--verbose]")
		os.Exit(1)
	}

	src := flag.Arg(0)
	dst := flag.Arg(1)

	errors := make(chan error, 100)

	go func() {
		if err := copyDir(src, dst, hardlink, verbose, errors); err != nil {
			errors <- err
		}
		copyWaitGroup.Wait()
		close(errors)
	}()

	for err := range errors {
		hasErrors.Store(true)
		fmt.Fprintln(os.Stderr, err)
	}

	if hasErrors.Load() {
		os.Exit(1)
	}
}
