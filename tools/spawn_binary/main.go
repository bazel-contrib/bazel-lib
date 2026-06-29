// spawn_binary is a thin wrapper around an arbitrary POSIX process, used by the
// run_binary rule to add features that require interposing on the spawned
// program.
//
// Usage:
//
//	spawn_binary [flags] -- <tool> [args...]
//
// Flags:
//
//	--stdout=FILE         capture the program's stdout into FILE
//	--stderr=FILE         capture the program's stderr into FILE
//	--exit-code-out=FILE  write the program's exit code into FILE and exit 0
//	--chdir=DIR           run the program with DIR as its working directory
//	--silent-on-success   only forward non-captured stdout/stderr to the console
//	                      when the program exits non-zero
//
// Design goals (see also the run_binary documentation):
//   - The spawned program must behave as if Bazel had launched it directly.
//     Environment and stdin are passed through verbatim; a stream is only
//     redirected when the corresponding feature is requested.
//   - Termination signals are relayed to the child so that Bazel cancelling or
//     timing out the action tears down the whole process tree.
//   - The child's exit status is reported faithfully, including death by signal.
package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strconv"
	"strings"
)

const separator = "--"

type options struct {
	stdoutPath      string
	stderrPath      string
	exitCodePath    string
	chdir           string
	silentOnSuccess bool
}

func main() {
	os.Exit(run(os.Args[1:]))
}

func run(args []string) int {
	opts, cmdArgs, err := parseArgs(args)
	if err != nil {
		return fatalf("%v", err)
	}
	if len(cmdArgs) == 0 {
		return fatalf("no command specified; expected: spawn_binary [flags] -- <tool> [args...]")
	}

	// When changing the child's working directory, resolve a relative tool path to
	// an absolute one first, so it still refers to the same file (the wrapper itself
	// keeps running in the original working directory, so the capture output paths,
	// which it opens, do not need adjusting).
	if opts.chdir != "" && strings.ContainsRune(cmdArgs[0], '/') {
		abs, aerr := filepath.Abs(cmdArgs[0])
		if aerr != nil {
			return fatalf("failed to resolve tool path %q: %v", cmdArgs[0], aerr)
		}
		cmdArgs[0] = abs
	}

	// Set up the stdout and stderr handling. Each stream is either written straight
	// to a declared output file, buffered (revealed only on failure when
	// --silent-on-success is set), or passed through to our own fd verbatim.
	stdout, finalizeStdout, err := newStream(opts.stdoutPath, opts.silentOnSuccess, os.Stdout)
	if err != nil {
		return fatalf("%v", err)
	}
	stderr, finalizeStderr, err := newStream(opts.stderrPath, opts.silentOnSuccess, os.Stderr)
	if err != nil {
		_ = finalizeStdout(1)
		return fatalf("%v", err)
	}

	// #nosec G204 -- spawning an arbitrary tool is the entire purpose of this wrapper.
	cmd := exec.Command(cmdArgs[0], cmdArgs[1:]...)
	cmd.Env = os.Environ()
	cmd.Stdin = os.Stdin
	cmd.Stdout = stdout
	cmd.Stderr = stderr
	cmd.Dir = opts.chdir

	if serr := cmd.Start(); serr != nil {
		_ = finalizeStdout(1)
		_ = finalizeStderr(1)
		return fatalf("failed to start %q: %v", cmdArgs[0], serr)
	}

	// Relay termination signals to the child. Without this, the default disposition
	// would kill the wrapper and orphan the child.
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

	code := 0
	if werr != nil {
		if exitErr, ok := werr.(*exec.ExitError); ok {
			code = exitCode(exitErr)
		} else {
			_ = finalizeStdout(1)
			_ = finalizeStderr(1)
			return fatalf("failed to run %q: %v", cmdArgs[0], werr)
		}
	}

	// Flush capture files and reveal any buffered output, based on the child's exit
	// code.
	if ferr := finalizeStdout(code); ferr != nil {
		return fatalf("%v", ferr)
	}
	if ferr := finalizeStderr(code); ferr != nil {
		return fatalf("%v", ferr)
	}

	if opts.exitCodePath != "" {
		if werr := os.WriteFile(opts.exitCodePath, []byte(strconv.Itoa(code)), 0o644); werr != nil {
			return fatalf("failed to write exit code file %q: %v", opts.exitCodePath, werr)
		}
		// The exit code has been captured as an output, so the wrapper (and thus the
		// build action) succeeds regardless of the child's exit code.
		return 0
	}

	return code
}

// newStream returns the writer to hand to the child for one output stream, plus a
// finalize callback to run after the child exits with its exit code.
//
//   - path != "":         the child writes directly to the declared output file.
//   - silentOnSuccess:    the stream is buffered and only written to console when
//     the child exits non-zero.
//   - otherwise:          the stream passes through to console (our own fd) verbatim.
func newStream(path string, silentOnSuccess bool, console *os.File) (io.Writer, func(code int) error, error) {
	if path != "" {
		// Handing the child an *os.File passes the file descriptor directly, so it
		// writes straight to the output file with no intermediate copy.
		f, err := os.Create(path)
		if err != nil {
			return nil, nil, fmt.Errorf("failed to create output file %q: %w", path, err)
		}
		return f, func(int) error { return f.Close() }, nil
	}
	if silentOnSuccess {
		buf := &bytes.Buffer{}
		return buf, func(code int) error {
			if code == 0 {
				return nil
			}
			_, err := console.Write(buf.Bytes())
			return err
		}, nil
	}
	return console, func(int) error { return nil }, nil
}

// parseArgs separates the wrapper's own flags (everything before the "--"
// separator) from the command to run (everything after it).
func parseArgs(args []string) (options, []string, error) {
	var opts options
	for i := 0; i < len(args); i++ {
		arg := args[i]
		if arg == separator {
			return opts, args[i+1:], nil
		}
		if v, ok, err := valueFlag("--stdout", arg, args, &i); err != nil {
			return opts, nil, err
		} else if ok {
			opts.stdoutPath = v
			continue
		}
		if v, ok, err := valueFlag("--stderr", arg, args, &i); err != nil {
			return opts, nil, err
		} else if ok {
			opts.stderrPath = v
			continue
		}
		if v, ok, err := valueFlag("--exit-code-out", arg, args, &i); err != nil {
			return opts, nil, err
		} else if ok {
			opts.exitCodePath = v
			continue
		}
		if v, ok, err := valueFlag("--chdir", arg, args, &i); err != nil {
			return opts, nil, err
		} else if ok {
			opts.chdir = v
			continue
		}
		if arg == "--silent-on-success" {
			opts.silentOnSuccess = true
			continue
		}
		return opts, nil, fmt.Errorf("unrecognized flag %q before the %q separator", arg, separator)
	}
	return opts, nil, fmt.Errorf("missing %q separator before the command to run", separator)
}

// valueFlag matches either "--name value" or "--name=value". It advances *i past a
// consumed value in the "--name value" form.
func valueFlag(name, arg string, args []string, i *int) (string, bool, error) {
	if arg == name {
		if *i+1 >= len(args) {
			return "", false, fmt.Errorf("%s requires a value", name)
		}
		*i++
		return args[*i], true, nil
	}
	if prefix := name + "="; strings.HasPrefix(arg, prefix) {
		return strings.TrimPrefix(arg, prefix), true, nil
	}
	return "", false, nil
}

func fatalf(format string, a ...interface{}) int {
	fmt.Fprintf(os.Stderr, "spawn_binary: "+format+"\n", a...)
	return 1
}
