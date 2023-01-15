package main

import (
	"fmt"
	"io/fs"
	"log"
	"os"
	"path"
	"path/filepath"
	"sync"

	"github.com/aspect-build/bazel-lib/tools/common"
)

type pathSet map[string]bool

var srcPaths = pathSet{}
var copyWaitGroup sync.WaitGroup
var hardlink = false
var verbose = false

func copyDir(src string, dst string) error {
	// filepath.WalkDir walks the file tree rooted at root, calling fn for each file or directory in
	// the tree, including root. See https://pkg.go.dev/path/filepath#WalkDir for more info.
	return filepath.WalkDir(src, func(p string, dirEntry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		r, err := filepath.Rel(src, p)
		if err != nil {
			return err
		}

		d := filepath.Join(dst, r)

		if dirEntry.IsDir() {
			srcPaths[src] = true
			return os.MkdirAll(d, os.ModePerm)
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
			if srcPaths[linkPath] {
				// recursive symlink; silently ignore
				return nil
			}
			stat, err := os.Stat(linkPath)
			if err != nil {
				return fmt.Errorf("failed to stat file %s pointed to by symlink %s: %w", linkPath, p, err)
			}
			if stat.IsDir() {
				// symlink points to a directory
				return copyDir(linkPath, d)
			} else {
				// symlink points to a regular file
				copyWaitGroup.Add(1)
				go common.Copy(linkPath, d, stat, hardlink, verbose, &copyWaitGroup)
				return nil
			}
		}

		// a regular file
		copyWaitGroup.Add(1)
		go common.Copy(p, d, info, hardlink, verbose, &copyWaitGroup)
		return nil
	})
}

func main() {
	args := os.Args[1:]

	if len(args) == 1 {
		if args[0] == "--version" || args[0] == "-v" {
			fmt.Printf("copy_directory %s\n", common.Version())
			return
		}
	}

	if len(args) < 2 {
		fmt.Println("Usage: copy_directory src dst [--hardlink] [--verbose]")
		os.Exit(1)
	}

	src := args[0]
	dst := args[1]

	if len(args) > 2 {
		for _, a := range os.Args[2:] {
			if a == "--hardlink" {
				hardlink = true
			} else if a == "--verbose" {
				verbose = true
			}
		}
	}

	if err := copyDir(src, dst); err != nil {
		log.Fatal(err)
	}
	copyWaitGroup.Wait()
}
