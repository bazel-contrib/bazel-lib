//go:build !windows

package main

import (
	"os"
	"os/exec"
	"syscall"
)

// forwardedSignals are relayed to the child process.
var forwardedSignals = []os.Signal{
	syscall.SIGINT,
	syscall.SIGTERM,
	syscall.SIGHUP,
	syscall.SIGQUIT,
}

// exitCode maps the child's wait status to the exit code this process returns:
// the child's own code for a normal exit, or 128+signum if the child was killed
// by a signal (matching the convention used by POSIX shells).
func exitCode(exitErr *exec.ExitError) int {
	if status, ok := exitErr.Sys().(syscall.WaitStatus); ok && status.Signaled() {
		return 128 + int(status.Signal())
	}
	return exitErr.ExitCode()
}
