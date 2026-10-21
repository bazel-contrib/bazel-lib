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
			cfg := map[string]any{
				"dst":                   dst,
				"include_srcs_packages": []string{"**"},
				"include_srcs_patterns": []string{"sdk/clang/include/**", "sdk/clang/share/**"},
				"exclude_srcs_patterns": []string{"sdk/clang/include/broken.h"},
				"replace_prefixes":      map[string]string{"sdk/clang/": "installed/"},
				"files": []map[string]string{
					{"path": src, "short_path": workspacePath, "workspace_path": workspacePath},
					{"path": excludedLink, "short_path": "excluded", "workspace_path": "excluded"},
				},
			}
			if output, err := runCopy(t, root, cfg); err != nil {
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
	cfg := map[string]any{
		"dst":                   filepath.Join(root, "out"),
		"include_srcs_packages": []string{"**"},
		"include_srcs_patterns": []string{"**"},
		"files": []map[string]string{{
			"path": src, "short_path": "broken", "workspace_path": "broken",
		}},
	}
	output, err := runCopy(t, root, cfg)
	if err == nil || !strings.Contains(string(output), "dangling symlink") {
		t.Fatalf("copy_to_directory = %v, %s; want dangling symlink error", err, output)
	}
}

func runCopy(t *testing.T, root string, cfg map[string]any) ([]byte, error) {
	t.Helper()
	contents, err := json.Marshal(cfg)
	if err != nil {
		t.Fatal(err)
	}
	configPath := filepath.Join(root, "config.json")
	if err := os.WriteFile(configPath, contents, 0644); err != nil {
		t.Fatal(err)
	}
	binary, err := runfiles.Rlocation(*copyTool)
	if err != nil {
		t.Fatal(err)
	}
	return exec.Command(binary, configPath).CombinedOutput()
}
