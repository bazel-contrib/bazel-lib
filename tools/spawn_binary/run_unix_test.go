//go:build !windows

package main

import (
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func writeScript(t *testing.T, path, body string) {
	t.Helper()
	if err := os.WriteFile(path, []byte("#!/usr/bin/env bash\n"+body), 0o755); err != nil {
		t.Fatal(err)
	}
}

// A tool referenced by a bare, separator-less path (as Bazel passes for a tool at
// the workspace root) must be executed as a file, not looked up on PATH.
func TestRunResolvesBareToolPath(t *testing.T) {
	dir := t.TempDir()
	writeScript(t, filepath.Join(dir, "bare.sh"), "echo ran\n")
	t.Chdir(dir)

	out := filepath.Join(dir, "out.txt")
	if code := run([]string{"--stdout", out, "--", "bare.sh"}); code != 0 {
		t.Fatalf("run() = %d, want 0", code)
	}
	if got, _ := os.ReadFile(out); string(got) != "ran\n" {
		t.Fatalf("captured stdout = %q, want %q", got, "ran\n")
	}
}

// A bare tool path must keep working when --chdir changes the child's working
// directory: the tool is resolved against the original directory, while the child
// runs in (and reads relative paths from) the chdir directory.
func TestRunChdirWithBareToolPath(t *testing.T) {
	dir := t.TempDir()
	writeScript(t, filepath.Join(dir, "bare.sh"), "cat data.txt\n")
	sub := filepath.Join(dir, "sub")
	if err := os.MkdirAll(sub, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(sub, "data.txt"), []byte("in-sub\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	t.Chdir(dir)

	out := filepath.Join(dir, "out.txt")
	if code := run([]string{"--chdir", "sub", "--stdout", out, "--", "bare.sh"}); code != 0 {
		t.Fatalf("run() = %d, want 0", code)
	}
	if got, _ := os.ReadFile(out); string(got) != "in-sub\n" {
		t.Fatalf("captured stdout = %q, want %q", got, "in-sub\n")
	}
}

// exit_code_out captures the child's non-zero exit code and lets the wrapper exit 0.
func TestExitCodeOutForcesSuccess(t *testing.T) {
	dir := t.TempDir()
	writeScript(t, filepath.Join(dir, "fail.sh"), "exit 7\n")
	t.Chdir(dir)

	codeFile := filepath.Join(dir, "code.txt")
	if code := run([]string{"--exit-code-out", codeFile, "--", "fail.sh"}); code != 0 {
		t.Fatalf("run() = %d, want 0 (exit code captured)", code)
	}
	if got, _ := os.ReadFile(codeFile); string(got) != "7" {
		t.Fatalf("exit code file = %q, want %q", got, "7")
	}
}

// Without exit_code_out, the child's non-zero exit code propagates.
func TestExitCodePropagates(t *testing.T) {
	dir := t.TempDir()
	writeScript(t, filepath.Join(dir, "fail.sh"), "exit 7\n")
	t.Chdir(dir)

	if code := run([]string{"--", "fail.sh"}); code != 7 {
		t.Fatalf("run() = %d, want 7", code)
	}
}

// fail_on allows listed codes to fail the action while other non-zero codes succeed.
func TestFailOnAllowsNonListedExit(t *testing.T) {
	dir := t.TempDir()
	writeScript(t, filepath.Join(dir, "tool.sh"), "exit 1\n")
	t.Chdir(dir)

	if code := run([]string{"--fail-on=2", "--", "tool.sh"}); code != 0 {
		t.Fatalf("run() = %d, want 0", code)
	}
}

func TestFailOnRejectsListedExit(t *testing.T) {
	dir := t.TempDir()
	writeScript(t, filepath.Join(dir, "tool.sh"), "exit 2\n")
	t.Chdir(dir)

	if code := run([]string{"--fail-on=2", "--", "tool.sh"}); code != 2 {
		t.Fatalf("run() = %d, want 2", code)
	}
}

// fail_on takes precedence over exit_code_out: the code is written, but listed codes
// still fail the action.
func TestFailOnWithExitCodeOut(t *testing.T) {
	dir := t.TempDir()
	writeScript(t, filepath.Join(dir, "exit2.sh"), "exit 2\n")
	writeScript(t, filepath.Join(dir, "exit1.sh"), "exit 1\n")
	t.Chdir(dir)

	codeFile := filepath.Join(dir, "code.txt")
	if code := run([]string{"--exit-code-out", codeFile, "--fail-on=2", "--", "exit2.sh"}); code != 2 {
		t.Fatalf("run() = %d, want 2", code)
	}
	if got, _ := os.ReadFile(codeFile); string(got) != "2" {
		t.Fatalf("exit code file = %q, want %q", got, "2")
	}

	codeFile = filepath.Join(dir, "code_ok.txt")
	if code := run([]string{"--exit-code-out", codeFile, "--fail-on=2", "--", "exit1.sh"}); code != 0 {
		t.Fatalf("run() = %d, want 0 for exit 1", code)
	}
	if got, _ := os.ReadFile(codeFile); string(got) != "1" {
		t.Fatalf("exit code file = %q, want %q", got, "1")
	}
}

// silent_on_success uses the same success/failure decision as fail_on.
func TestSilentOnSuccessRespectsFailOn(t *testing.T) {
	dir := t.TempDir()
	writeScript(t, filepath.Join(dir, "tool.sh"), "echo noisy >&2\nexit \"$1\"\n")
	t.Chdir(dir)

	readStderr := func(args []string) string {
		t.Helper()
		r, w, err := os.Pipe()
		if err != nil {
			t.Fatal(err)
		}
		old := os.Stderr
		os.Stderr = w
		code := run(args)
		w.Close()
		os.Stderr = old
		out, _ := io.ReadAll(r)
		r.Close()
		if code != 0 {
			t.Fatalf("run(%v) = %d, want 0", args, code)
		}
		return string(out)
	}

	if got := readStderr([]string{"--silent-on-success", "--fail-on=2", "--", "tool.sh", "1"}); got != "" {
		t.Fatalf("stderr on successful exit 1 = %q, want empty", got)
	}

	r, w, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	old := os.Stderr
	os.Stderr = w
	code := run([]string{"--silent-on-success", "--fail-on=2", "--", "tool.sh", "2"})
	w.Close()
	os.Stderr = old
	out, _ := io.ReadAll(r)
	r.Close()
	if code != 2 {
		t.Fatalf("run() = %d, want 2", code)
	}
	if !strings.Contains(string(out), "noisy") {
		t.Fatalf("stderr on failed exit 2 = %q, want noisy output", out)
	}
}
