package main

import (
	"fmt"
	"log"
	"os"

	"github.com/bazel-contrib/bazel-lib/tools/common"
)

func main() {
	args := os.Args[1:]

	if len(args) < 2 {
		fmt.Println("Usage: copy_directory src dst [--hardlink] [--verbose] [--preserve-mtime]")
		os.Exit(1)
	}

	src := args[0]
	dst := args[1]

	var opts common.CopyOpts
	if len(args) > 2 {
		for _, a := range os.Args[2:] {
			switch a {
			case "--hardlink":
				opts.Hardlink = true
			case "--verbose":
				opts.Verbose = true
			case "--preserve-mtime":
				opts.PreserveMTime = true
			}
		}
	}

	walker := common.NewWalker(100, 10)
	if err := walker.CopyDir(src, dst, opts); err != nil {
		log.Fatal(err)
	}
	walker.Close()
}
