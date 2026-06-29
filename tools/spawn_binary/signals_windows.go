//go:build windows

package main

import (
	"os"
	"os/exec"
	"syscall"
)

// forwardedSignals are relayed to the child process. Windows only meaningfully
// supports interrupt and termination.
var forwardedSignals = []os.Signal{
	os.Interrupt,
	syscall.SIGTERM,
}

// exitCode returns the child's exit code. Windows has no signal-death concept
// equivalent to POSIX, so the raw exit code is returned as-is.
func exitCode(exitErr *exec.ExitError) int {
	return exitErr.ExitCode()
}
