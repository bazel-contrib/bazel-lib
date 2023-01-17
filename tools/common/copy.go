package common

import (
	"fmt"
	"io"
	"io/fs"
	"os"
	"sync"
)

func Copy(src string, dst string, info fs.FileInfo, link bool, verbose bool, wg *sync.WaitGroup) error {
	defer wg.Done()
	if !info.Mode().IsRegular() {
		return fmt.Errorf("failed to copy %q: not a regular file", src)
	}
	if link {
		// hardlink this file
		if verbose {
			fmt.Printf("hardlink %v => %v\n", src, dst)
		}
		if err := os.Link(src, dst); err != nil {
			// fallback to copy
			if verbose {
				fmt.Printf("hardlink failed: %v\n", err)
				fmt.Printf("copy (fallback) %v => %v\n", src, dst)
			}
			err = copyFile(src, dst)
			if err != nil {
				return fmt.Errorf("failed to copy %q: %w", src, err)
			}
		}
	} else {
		// copy this file
		if verbose {
			fmt.Printf("copy %v => %v\n", src, dst)
		}
		err := copyFile(src, dst)
		if err != nil {
			return fmt.Errorf("failed to copy %q: %w", src, err)
		}
	}

	return nil
}

// From https://opensource.com/article/18/6/copying-files-go
func copyFile(src string, dst string) error {
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

	if _, err := io.Copy(destination, source); err != nil {
		return err
	}

	return nil
}
