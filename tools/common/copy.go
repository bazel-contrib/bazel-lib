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

func Copy(opts CopyOpts) {
	if !opts.info.Mode().IsRegular() {
		log.Fatalf("%s is not a regular file", opts.src)
	}
	if opts.hardlink {
		// hardlink this file
		if opts.verbose {
			fmt.Printf("hardlink %v => %v\n", opts.src, opts.dst)
		}
		err := os.Link(opts.src, opts.dst)
		if err != nil {
			// fallback to copy
			if opts.verbose {
				fmt.Printf("hardlink failed: %v\n", err)
				fmt.Printf("copy (fallback) %v => %v\n", opts.src, opts.dst)
			}
			err = CopyFile(opts.src, opts.dst)
			if err != nil {
				log.Fatal(err)
			}
		}
	} else {
		// copy this file
		if opts.verbose {
			fmt.Printf("copy %v => %v\n", opts.src, opts.dst)
		}
		err := CopyFile(opts.src, opts.dst)
		if err != nil {
			log.Fatal(err)
		}
	}
}

type CopyWorker struct {
	queue <-chan CopyOpts
}

func NewCopyWorker(queue <-chan CopyOpts) *CopyWorker {
	return &CopyWorker{queue: queue}
}

func (w *CopyWorker) Run(wg *sync.WaitGroup) {
	defer wg.Done()
	for opts := range w.queue {
		Copy(opts)
	}
}

type CopyOpts struct {
	src, dst string
	info     fs.FileInfo
	hardlink bool
	verbose  bool
}

func NewCopyOpts(src string, dst string, info fs.FileInfo, hardlink bool, verbose bool) CopyOpts {
	return CopyOpts{src: src, dst: dst, info: info, hardlink: hardlink, verbose: verbose}
}
