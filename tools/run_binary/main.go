// This is a wrapper/host process for running tools under a Bazel action.
// The environment it runs in is specified by Bazel:
// - the working directory is the execution root
// - args/env are dropped since the tool is not run directly by the user under Bazel run
//
// It also supports WASM tools. It hosts a WASM runtime and loads the WASM module into it.
// This makes it easier to ship tools from Bazel rules without having to build lots of different target-triple pre-compiled versions.
//
// In the future, this tool can also strace the tool we run to collect telemetry data.
// That would be great for:
// - The tool wrote to a different output path than expected, where did it go?
// - What's making the tool slow? Maybe we can get eBPF timing data under Linux at least - and stitch the profiling into the Bazel profile.
//
// The tool we run can do things like:
// - write output files and output directories under bazel-bin/path/to/package
package main

import (
	"fmt"
	"os"

	// add a high-performance WASM runtime
	"github.com/bytecodealliance/wasmtime-go"
)

func main() {

	engine := wasmtime.NewEngine()
	store := wasmtime.NewStore(engine)
	// Load wasm code by reading /Users/alexeagle/Projects/bazel-lib/bazel-bin/path/to/package/tool_/tool.wasm
	wasmCode, err := os.ReadFile("/Users/alexeagle/Projects/bazel-lib/bazel-bin/path/to/package/tool_/tool.wasm")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to read wasm code: %v\n", err)
		os.Exit(1)
	}
	module, err := wasmtime.NewModule(engine, []byte(wasmCode))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to create module: %v\n", err)
		os.Exit(1)
	}
	instance, err := wasmtime.NewInstance(store, module, []wasmtime.AsExtern{})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to create instance: %v\n", err)
		os.Exit(1)
	}
	spawnFunc := instance.GetFunc(store, "spawn")
	if spawnFunc == nil {
		fmt.Fprintf(os.Stderr, "Failed to get spawn function\n")
		os.Exit(1)
	}
	_, err = spawnFunc.Call(store, "bazel-out/darwin_arm64-fastbuild/bin/path/to/package/output.txt")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to call spawn function: %v\n", err)
		os.Exit(1)
	}

	// // writes to bazel-bin/path/to/package/output.txt
	// f, err := os.Create("bazel-out/darwin_arm64-fastbuild/bin/path/to/package/output.txt")
	// if err != nil {
	// 	fmt.Fprintf(os.Stderr, "Failed to create output.txt: %v\n", err)
	// 	os.Exit(1)
	// }
	// defer f.Close()
	// _, err = f.Write([]byte("[DEBUG] Hello from the tool launcher!\n"))
	// if err != nil {
	// 	fmt.Fprintf(os.Stderr, "Failed to write to output.txt: %v\n", err)
	// 	os.Exit(1)
	// }
}
