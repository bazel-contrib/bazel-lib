package main

import (
	"encoding/json"
	"flag"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/bazelbuild/rules_go/go/runfiles"
)

var copyTool = flag.String("copy-tool", "", "copy_to_directory executable")

func TestDirectorySymlinkFilters(t *testing.T) {
	for _, kind := range []string{"directory", "directory_symlink", "nested_directory_symlink"} {
		t.Run(kind, func(t *testing.T) {
			root := t.TempDir()
			payload := filepath.Join(root, "payload")
			for _, dir := range []string{"include", "share"} {
				if err := os.MkdirAll(filepath.Join(payload, dir), 0755); err != nil {
					t.Fatal(err)
				}
			}
			for name, contents := range map[string]string{
				"include/header.h": "header",
				"share/data":       "data",
				"excluded":         "excluded",
			} {
				if err := os.WriteFile(filepath.Join(payload, name), []byte(contents), 0644); err != nil {
					t.Fatal(err)
				}
			}
			for name, target := range map[string]string{
				"include/alias.h":  "header.h",
				"include/broken.h": "missing",
				"include/loop":     ".",
			} {
				if err := os.Symlink(target, filepath.Join(payload, name)); err != nil {
					t.Fatal(err)
				}
			}

			src := payload
			workspacePath := "sdk/clang"
			switch kind {
			case "directory_symlink":
				src = filepath.Join(root, "source")
				if err := os.Symlink(payload, src); err != nil {
					t.Fatal(err)
				}
			case "nested_directory_symlink":
				src = filepath.Join(root, "source")
				workspacePath = "sdk"
				if err := os.Mkdir(src, 0755); err != nil {
					t.Fatal(err)
				}
				if err := os.Symlink(payload, filepath.Join(src, "clang")); err != nil {
					t.Fatal(err)
				}
			}
			excludedLink := filepath.Join(root, "excluded-link")
			if err := os.Symlink("missing", excludedLink); err != nil {
				t.Fatal(err)
			}

			dst := filepath.Join(root, "out")
			if output, err := runCopy(t, root,
				"--dst", dst,
				"--hardlink", "off",
				"--include_srcs_packages", "**",
				"--include_srcs_patterns", "sdk/clang/include/**",
				"--include_srcs_patterns", "sdk/clang/share/**",
				"--exclude_srcs_patterns", "sdk/clang/include/broken.h",
				"--replace_prefixes", `{"sdk/clang/": "installed/"}`,
				"--file", fileArg(t, src, workspacePath, false),
				"--file", fileArg(t, excludedLink, "excluded", false),
			); err != nil {
				t.Fatalf("copy_to_directory: %v\n%s", err, output)
			}

			got := map[string]string{}
			err := filepath.WalkDir(dst, func(p string, entry fs.DirEntry, err error) error {
				if err != nil {
					return err
				}
				if entry.IsDir() {
					return nil
				}
				contents, err := os.ReadFile(p)
				if err != nil {
					return err
				}
				rel, err := filepath.Rel(dst, p)
				if err != nil {
					return err
				}
				got[filepath.ToSlash(rel)] = string(contents)
				return nil
			})
			if err != nil && !os.IsNotExist(err) {
				t.Fatal(err)
			}
			want := map[string]string{
				"installed/include/header.h": "header",
				"installed/include/alias.h":  "header",
				"installed/share/data":       "data",
			}
			if !reflect.DeepEqual(got, want) {
				t.Errorf("copied files = %v, want %v", got, want)
			}
		})
	}
}

func TestIncludedDanglingSymlink(t *testing.T) {
	root := t.TempDir()
	src := filepath.Join(root, "broken")
	if err := os.Symlink("missing", src); err != nil {
		t.Fatal(err)
	}
	output, err := runCopy(t, root,
		"--dst", filepath.Join(root, "out"),
		"--hardlink", "off",
		"--include_srcs_packages", "**",
		"--include_srcs_patterns", "**",
		"--file", fileArg(t, src, "broken", false),
	)
	if err == nil || !strings.Contains(string(output), "dangling symlink") {
		t.Fatalf("copy_to_directory = %v, %s; want dangling symlink error", err, output)
	}
}

func TestParamsFile(t *testing.T) {
	root := t.TempDir()
	for name, contents := range map[string]string{
		"src/pkg/a.txt":          "a",
		"tree/pkg/dir/sub/b.txt": "b",
		"tree/pkg/dir/c.txt":     "c",
	} {
		p := filepath.Join(root, name)
		if err := os.MkdirAll(filepath.Dir(p), 0755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(p, []byte(contents), 0644); err != nil {
			t.Fatal(err)
		}
	}

	dst := filepath.Join(root, "out")
	if output, err := runCopy(t, root,
		"--workspace", "",
		"--dst", dst,
		"--hardlink", "auto",
		"--include_srcs_packages", "**",
		"--include_srcs_patterns", "**",
		"--root_paths", "pkg",
		// A source file.
		"--file", fileArg(t, filepath.Join(root, "src/pkg/a.txt"), "pkg/a.txt", true),
		// A path within a directory, as provided by DirectoryPathInfo.
		"--file", fileArg(t, filepath.Join(root, "tree/pkg/dir/sub"), "pkg/dir/sub", false),
	); err != nil {
		t.Fatalf("copy_to_directory: %v\n%s", err, output)
	}

	got := map[string]string{}
	err := filepath.WalkDir(dst, func(p string, entry fs.DirEntry, err error) error {
		if err != nil || entry.IsDir() {
			return err
		}
		contents, err := os.ReadFile(p)
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(dst, p)
		if err != nil {
			return err
		}
		got[filepath.ToSlash(rel)] = string(contents)
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]string{
		"a.txt":         "a",
		"dir/sub/b.txt": "b",
	}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("copied files = %v, want %v", got, want)
	}
}

func TestInvalidParams(t *testing.T) {
	for _, tc := range []struct {
		name string
		args []string
		want string
	}{
		{"missing dst", []string{"--hardlink", "off"}, "missing --dst"},
		{"unknown flag", []string{"--dst", "out", "--unknown", "value"}, "flag provided but not defined: -unknown"},
		{"invalid boolean", []string{"--dst", "out", "--verbose", "maybe"}, `invalid value "maybe" for flag -verbose`},
		{"invalid file", []string{"--dst", "out", "--file", "{"}, `invalid value "{" for flag -file`},
		{"unexpected argument", []string{"--dst", "out", "extra"}, "unexpected arguments [extra]"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			output, err := runCopy(t, t.TempDir(), tc.args...)
			if err == nil || !strings.Contains(string(output), tc.want) {
				t.Fatalf("copy_to_directory = %v, %s; want error containing %q", err, output, tc.want)
			}
			if strings.Contains(string(output), "Usage of") {
				t.Errorf("copy_to_directory printed the usage of its flags:\n%s", output)
			}
		})
	}
}

// runCopy runs copy_to_directory with args in a params file, as
// copy_to_directory_bin_action does.
func runCopy(t *testing.T, root string, args ...string) ([]byte, error) {
	t.Helper()
	paramsPath := filepath.Join(root, "params")
	if err := os.WriteFile(paramsPath, []byte(strings.Join(args, "\n")+"\n"), 0644); err != nil {
		t.Fatal(err)
	}
	binary, err := runfiles.Rlocation(*copyTool)
	if err != nil {
		t.Fatal(err)
	}
	return exec.Command(binary, "@"+paramsPath).CombinedOutput()
}

// fileArg returns the value of a --file flag, for a file of the main
// repository at path, whose short and workspace paths are workspacePath.
func fileArg(t *testing.T, path, workspacePath string, isSource bool) string {
	t.Helper()
	contents, err := json.Marshal(map[string]any{
		"path":           path,
		"short_path":     workspacePath,
		"workspace_path": workspacePath,
		"package":        "pkg",
		"workspace":      "",
		"is_source":      isSource,
	})
	if err != nil {
		t.Fatal(err)
	}
	return string(contents)
}
