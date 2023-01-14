package main

import (
	"fmt"
	"io"
	"io/fs"
	"log"
	"os"
	"path"
	"path/filepath"
	"strings"
)

type copyFile struct {
	Src      string
	Dst      string
	FileInfo fs.FileInfo
}

type copySet []copyFile
type dirSet []string
type pathSet map[string]bool

var copyPaths = make(copySet, 0, 10*1024)
var dstDirs = make(dirSet, 0, 1024)
var srcPaths = pathSet{}

func scanDir(src string, dst string) error {
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
			dstDirs = append(dstDirs, d)
			return nil
		} else {
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
					return scanDir(linkPath, d)
				} else {
					// symlink points to a regular file
					copyPaths = append(copyPaths, copyFile{
						Src:      linkPath,
						Dst:      d,
						FileInfo: stat,
					})
					return nil
				}
			}

			// a regular file
			copyPaths = append(copyPaths, copyFile{
				Src:      p,
				Dst:      d,
				FileInfo: info,
			})
			return nil
		}
	})
}

// From https://opensource.com/article/18/6/copying-files-go
func copy(src string, dst string) error {
	source, err := os.Open(src)
	if err != nil {
		return err
	}
	defer source.Close()

	destination, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destination.Close()
	_, err = io.Copy(destination, source)
	return err
}

func version() string {
	var versionBuilder strings.Builder
	if Release != "" && Release != PreStampRelease {
		versionBuilder.WriteString(Release)
		if GitStatus != CleanGitStatus {
			versionBuilder.WriteString(NotCleanVersionSuffix)
		}
	} else {
		versionBuilder.WriteString(NoReleaseVersion)
	}
	return versionBuilder.String()
}

func main() {
	args := os.Args[1:]

	if len(args) == 1 {
		if args[0] == "--version" || args[0] == "-v" {
			fmt.Printf("copy_directory %s\n", version())
			return
		}
	}

	if len(args) < 2 {
		fmt.Println("Usage: copy_directory [src] [dst]")
		os.Exit(1)
	}

	src := args[0]
	dst := args[1]

	hardlink := false
	verbose := false

	if len(args) > 2 {
		for _, a := range os.Args[2:] {
			if a == "--hardlink" {
				hardlink = true
			} else if a == "--verbose" {
				verbose = true
			}
		}
	}

	// Gather list of files to copy
	if err := scanDir(src, dst); err != nil {
		log.Fatal(err)
	}

	// Create all destination directories
	for _, d := range dstDirs {
		err := os.MkdirAll(d, os.ModePerm)
		if err != nil {
			log.Fatal(err)
		}
	}

	// Perform copies or create hardlinks
	// TODO: split out into parallel go routines?
	for _, c := range copyPaths {
		if !c.FileInfo.Mode().IsRegular() {
			log.Fatalf("%s is not a regular file", c.Src)
		}
		if hardlink {
			// hardlink this file
			if verbose {
				fmt.Printf("hardlink %v => %v\n", c.Src, c.Dst)
			}
			err := os.Link(c.Src, c.Dst)
			if err != nil {
				// fallback to copy
				if verbose {
					fmt.Printf("hardlink failed: %v\n", err)
					fmt.Printf("copy (fallback) %v => %v\n", c.Src, c.Dst)
				}
				err = copy(c.Src, c.Dst)
				if err != nil {
					log.Fatal(err)
				}
			}
		} else {
			// copy this file
			if verbose {
				fmt.Printf("copy %v => %v\n", c.Src, c.Dst)
			}
			err := copy(c.Src, c.Dst)
			if err != nil {
				log.Fatal(err)
			}
		}
	}
}
