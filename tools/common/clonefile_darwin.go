//go:build darwin

package common

import (
	"golang.org/x/sys/unix"
	"os"
)

// https://keith.github.io/xcode-man-pages/clonefile.2.html
func cloneFile(src, dst string) (supported bool, err error) {
	if err = unix.Clonefile(src, dst, 0); err != nil {
		return true, &os.LinkError{
			Op:  "clonefile",
			Old: src,
			New: dst,
			Err: err,
		}
	}
	return true, nil
}
