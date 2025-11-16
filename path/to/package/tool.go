// This is a WASM tool that prints "Hello from a WASM tool!" to a file path passed in as an argument.
// It is compiled to WASM using Bazel.
package main

import (
	"fmt"
	"os"
)

//go:wasmexport spawn
func spawn(path string) {
	f, err := os.Create(path)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to create file: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()
	_, err = f.Write([]byte("Hello from a WASM tool!\n"))
}

func main() {
	panic("Should be called by WASM runtime")
}
