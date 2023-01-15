package common

import (
	"fmt"
	"io"
	"io/fs"
	"log"
	"os"
	"sync"
)

// From https://opensource.com/article/18/6/copying-files-go
func CopyFile(src string, dst string) error {
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

func Copy(src string, dst string, info fs.FileInfo, link bool, verbose bool, wg *sync.WaitGroup) {
	if wg != nil {
		defer wg.Done()
	}
	if !info.Mode().IsRegular() {
		log.Fatalf("%s is not a regular file", src)
	}
	if link {
		// hardlink this file
		if verbose {
			fmt.Printf("hardlink %v => %v\n", src, dst)
		}
		err := os.Link(src, dst)
		if err != nil {
			// fallback to copy
			if verbose {
				fmt.Printf("hardlink failed: %v\n", err)
				fmt.Printf("copy (fallback) %v => %v\n", src, dst)
			}
			err = CopyFile(src, dst)
			if err != nil {
				log.Fatal(err)
			}
		}
	} else {
		// copy this file
		if verbose {
			fmt.Printf("copy %v => %v\n", src, dst)
		}
		err := CopyFile(src, dst)
		if err != nil {
			log.Fatal(err)
		}
	}
}
