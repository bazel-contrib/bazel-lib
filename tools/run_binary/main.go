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
	"context"
	"fmt"
	"os"

	"github.com/tetratelabs/wazero"
	"github.com/tetratelabs/wazero/imports/wasi_snapshot_preview1"
)

func main() {
	wasmCode, err := os.ReadFile("/Users/alexeagle/Projects/bazel-lib/bazel-bin/path/to/package/wasm_tool_/wasm_tool.wasm")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to read wasm code: %v\n", err)
		os.Exit(1)
	}

	// Choose the context to use for function calls.
	ctx := context.Background()
	r := wazero.NewRuntime(ctx)
	defer r.Close(ctx)

	wasi_snapshot_preview1.MustInstantiate(ctx, r)

	module, err := r.Instantiate(ctx, wasmCode)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to instantiate module: %v\n", err)
		os.Exit(1)
	}

	// Call the exported spawn function with the output path
	// Go's wasmexport handles string parameter marshalling automatically
	spawn := module.ExportedFunction("spawn")
	if spawn == nil {
		fmt.Fprintf(os.Stderr, "Failed to get spawn function\n")
		os.Exit(1)
	}
	_, err = spawn.Call(ctx)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to call spawn: %v\n", err)
		os.Exit(1)
	}
}
