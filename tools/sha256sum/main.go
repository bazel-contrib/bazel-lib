package main

import (
	"crypto/sha256"
	"fmt"
	"io"
	"log"
	"os"
)

func main() {
	var input io.Reader
	var filename string
	if len(os.Args) == 1 {
		input = os.Stdin
		filename = "-"
	} else {
		f, err := os.Open(os.Args[1])
		if err != nil {
			log.Fatal(err)
		}
		defer f.Close()
		input = f
		filename = os.Args[1]
	}

	hash := sha256.New()
	if _, err := io.Copy(hash, input); err != nil {
		log.Fatal(err)
	}
	fmt.Printf("%x  %s\n", hash.Sum(nil), filename)
}
