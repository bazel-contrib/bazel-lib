package common

import (
	"path/filepath"
)

// Same as filepath.Rel except that it normalizes result to forward slashes
// slashes since filepath.Rel will convert to system slashes
func FileRel(basepath, targpath string) (string, error) {
	r, err := filepath.Rel(basepath, targpath)
	if err != nil {
		return "", err
	}

	return filepath.ToSlash(r), nil
}
