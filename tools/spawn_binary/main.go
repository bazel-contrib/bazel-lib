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
//	--exit-code-out=FILE  write the program's exit code into FILE
//	--fail-on=CODE       treat CODE as an action failure (repeatable; comma-separated
//	                     values in one flag are also accepted)
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
	failOn          []int
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

	// The tool is always a declared input file, referenced by its execroot-relative
	// path, never a command to look up on PATH. Resolve it to an absolute path
	// (relative to the wrapper's working directory, the execution root) so that:
	//   - a separator-less execpath (e.g. a tool at the workspace root, passed as
	//     "tool.sh") is executed as a file rather than mistaken for a PATH lookup by
	//     exec.Command, and
	//   - it still refers to the same file when --chdir changes the child's working
	//     directory. The wrapper itself stays in the original working directory, so
	//     the capture output paths it opens do not need adjusting.
	abs, aerr := filepath.Abs(cmdArgs[0])
	if aerr != nil {
		return fatalf("failed to resolve tool path %q: %v", cmdArgs[0], aerr)
	}
	cmdArgs[0] = abs

	// Set up the stdout and stderr handling. Each stream is either written straight
	// to a declared output file, buffered (revealed only on action failure when
	// --silent-on-success is set), or passed through to our own fd verbatim.
	stdout, finalizeStdout, err := newStream(opts.stdoutPath, opts.silentOnSuccess, os.Stdout)
	if err != nil {
		return fatalf("%v", err)
	}
	stderr, finalizeStderr, err := newStream(opts.stderrPath, opts.silentOnSuccess, os.Stderr)
	if err != nil {
		_ = finalizeStdout(true)
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
		_ = finalizeStdout(true)
		_ = finalizeStderr(true)
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
			_ = finalizeStdout(true)
			_ = finalizeStderr(true)
			return fatalf("failed to run %q: %v", cmdArgs[0], werr)
		}
	}

	failed := actionFailed(code, opts)

	// Flush capture files and reveal any buffered output when the action failed.
	if ferr := finalizeStdout(failed); ferr != nil {
		return fatalf("%v", ferr)
	}
	if ferr := finalizeStderr(failed); ferr != nil {
		return fatalf("%v", ferr)
	}

	if opts.exitCodePath != "" {
		if werr := os.WriteFile(opts.exitCodePath, []byte(strconv.Itoa(code)), 0o644); werr != nil {
			return fatalf("failed to write exit code file %q: %v", opts.exitCodePath, werr)
		}
	}

	if !failed {
		return 0
	}
	return code
}

// actionFailed reports whether the build action should fail for the child's exit
// code. When --fail-on is set it takes precedence; otherwise exit_code_out forces
// success and the default is to fail on any non-zero exit.
func actionFailed(code int, opts options) bool {
	if len(opts.failOn) > 0 {
		for _, c := range opts.failOn {
			if code == c {
				return true
			}
		}
		return false
	}
	if opts.exitCodePath != "" {
		return false
	}
	return code != 0
}

// newStream returns the writer to hand to the child for one output stream, plus a
// finalize callback to run after the child exits with its exit code.
//
//   - path != "":         the child writes directly to the declared output file.
//   - silentOnSuccess:    the stream is buffered and only written to console when
//     the action is treated as a failure (see actionFailed).
//   - otherwise:          the stream passes through to console (our own fd) verbatim.
func newStream(path string, silentOnSuccess bool, console *os.File) (io.Writer, func(failed bool) error, error) {
	if path != "" {
		// Handing the child an *os.File passes the file descriptor directly, so it
		// writes straight to the output file with no intermediate copy.
		f, err := os.Create(path)
		if err != nil {
			return nil, nil, fmt.Errorf("failed to create output file %q: %w", path, err)
		}
		return f, func(bool) error { return f.Close() }, nil
	}
	if silentOnSuccess {
		buf := &bytes.Buffer{}
		return buf, func(failed bool) error {
			if !failed {
				return nil
			}
			_, err := console.Write(buf.Bytes())
			return err
		}, nil
	}
	return console, func(bool) error { return nil }, nil
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
		if v, ok, err := valueFlag("--fail-on", arg, args, &i); err != nil {
			return opts, nil, err
		} else if ok {
			codes, err := parseFailOn(v)
			if err != nil {
				return opts, nil, err
			}
			opts.failOn = append(opts.failOn, codes...)
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

func parseFailOn(s string) ([]int, error) {
	var codes []int
	for _, part := range strings.Split(s, ",") {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		n, err := strconv.Atoi(part)
		if err != nil {
			return nil, fmt.Errorf("invalid exit code %q in --fail-on", part)
		}
		codes = append(codes, n)
	}
	if len(codes) == 0 {
		return nil, fmt.Errorf("--fail-on requires at least one exit code")
	}
	return codes, nil
}

func fatalf(format string, a ...interface{}) int {
	fmt.Fprintf(os.Stderr, "spawn_binary: "+format+"\n", a...)
	return 1
}
