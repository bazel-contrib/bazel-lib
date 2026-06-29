// spawn_binary is a thin wrapper around an arbitrary POSIX process, used by the
// run_binary rule to add features that require interposing on the spawned
// program. Today the only feature is capturing the program's stdout into a file.
//
// Usage:
//
//	spawn_binary [--stdout=<file>] -- <tool> [args...]
//
// Design goals (see also the run_binary documentation):
//   - The spawned program must behave as if Bazel had launched it directly.
//     Environment, stdin and stderr are passed through verbatim; only stdout is
//     redirected, and only when --stdout is given.
//   - Termination signals are relayed to the child so that Bazel cancelling or
//     timing out the action tears down the whole process tree.
//   - The child's exit status is reported faithfully, including death by signal.
package main

import (
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"strings"
)

const separator = "--"

func main() {
	os.Exit(run(os.Args[1:]))
}

func run(args []string) int {
	stdoutPath, cmdArgs, err := parseArgs(args)
	if err != nil {
		return fatalf("%v", err)
	}
	if len(cmdArgs) == 0 {
		return fatalf("no command specified; expected: spawn_binary [flags] -- <tool> [args...]")
	}

	// #nosec G204 -- spawning an arbitrary tool is the entire purpose of this wrapper.
	cmd := exec.Command(cmdArgs[0], cmdArgs[1:]...)

	// Pass the environment, stdin and stderr through verbatim so the spawned
	// program cannot tell it is wrapped and streams we do not intercept are
	// unaffected.
	cmd.Env = os.Environ()
	cmd.Stdin = os.Stdin
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout

	if stdoutPath != "" {
		// Assigning an *os.File hands the file descriptor directly to the child, so
		// it writes straight to the output file with no intermediate copy.
		f, ferr := os.Create(stdoutPath)
		if ferr != nil {
			return fatalf("failed to create stdout file %q: %v", stdoutPath, ferr)
		}
		defer f.Close()
		cmd.Stdout = f
	}

	if serr := cmd.Start(); serr != nil {
		return fatalf("failed to start %q: %v", cmdArgs[0], serr)
	}

	// Relay termination signals to the child. Without this, the default
	// disposition would kill the wrapper and orphan the child.
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, forwardedSignals...)
	go func() {
		for sig := range sigs {
			// Best-effort: the child may already have exited.
			_ = cmd.Process.Signal(sig)
		}
	}()

	werr := cmd.Wait()
	signal.Stop(sigs)
	close(sigs)

	if werr == nil {
		return 0
	}
	if exitErr, ok := werr.(*exec.ExitError); ok {
		return exitCode(exitErr)
	}
	return fatalf("failed to run %q: %v", cmdArgs[0], werr)
}

// parseArgs separates the wrapper's own flags (everything before the "--"
// separator) from the command to run (everything after it).
func parseArgs(args []string) (stdoutPath string, cmdArgs []string, err error) {
	for i := 0; i < len(args); i++ {
		arg := args[i]
		if arg == separator {
			return stdoutPath, args[i+1:], nil
		}
		switch {
		case arg == "--stdout":
			if i+1 >= len(args) {
				return "", nil, fmt.Errorf("--stdout requires a value")
			}
			i++
			stdoutPath = args[i]
		case strings.HasPrefix(arg, "--stdout="):
			stdoutPath = strings.TrimPrefix(arg, "--stdout=")
		default:
			return "", nil, fmt.Errorf("unrecognized flag %q before the %q separator", arg, separator)
		}
	}
	return "", nil, fmt.Errorf("missing %q separator before the command to run", separator)
}

func fatalf(format string, a ...interface{}) int {
	fmt.Fprintf(os.Stderr, "spawn_binary: "+format+"\n", a...)
	return 1
}
