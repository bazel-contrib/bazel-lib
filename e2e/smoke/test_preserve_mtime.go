package smoketest

import (
	"os"
	"path/filepath"
	"time"
	"testing"
)

func mtime(path string) (time.Time, error) {
	info, err := os.Stat(path)
	if err != nil {
		return time.Time{}, err
	}

	return info.ModTime(), nil
}

func TestPreserveMTime(t *testing.T) {
	cases := map[string]struct{
		originalPath string
		copiedPath string
	}{
		"copy_directory": {
			originalPath: filepath.Join("d", "1"),
			copiedPath: filepath.Join("copy_directory_mtime_out", "1"),
		},
		"copy_to_directory": {
			originalPath: filepath.Join("d", "1"),
			copiedPath: filepath.Join("copy_to_directory_mtime_out", "d", "1"),
		},
	}

	for name, test := range cases {
		t.Run(name, func(t *testing.T) {
			originalMTime, err := mtime(test.originalPath)
			if err != nil {
				t.Fatal(err.Error())
			}
			copiedMTime, err := mtime(test.copiedPath)
			if err != nil {
				t.Fatal(err.Error())
			}

			if originalMTime != copiedMTime {
				t.Fatalf(`Modify times do not match for %s and %s:
  Original modify time: %s
  Copied modify time:   %s`, test.originalPath, test.copiedPath, originalMTime, copiedMTime)
			}
		})
	}
}
