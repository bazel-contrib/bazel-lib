//go:build !windows

package main

import (
	"os"
	"path/filepath"
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
