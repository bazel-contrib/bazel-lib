//go:build darwin

package common

import (
	"os"

	"golang.org/x/sys/unix"
)

// https://keith.github.io/xcode-man-pages/clonefile.2.html
func CloneFile(src, dst string) error {
	if err := unix.Clonefile(src, dst, 0); err != nil {
		return &os.LinkError{
			Op:  "clonefile",
			Old: src,
			New: dst,
			Err: err,
		}
	}
	return nil
}
