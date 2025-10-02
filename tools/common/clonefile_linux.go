//go:build linux

package common

import (
	"os"

	"golang.org/x/sys/unix"
)

// FICLONE clones the contents of srcFd into the file referred to by dstFd.
// #define FICLONE _IOW(0x94, 9, int)  /* 0x40049409 */
const _FICLONE = 0x40049409

func CloneFile(src, dst string) error {
	source, err := os.Open(src)
	if err != nil {
		return err
	}
	defer source.Close()

	destination, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destination.Close()

	// Perform ioctl on the destination FD, passing the source FD as the arg.
	// int ioctl(int dst_fd, FICLONE, int src_fd);
	if err := unix.IoctlSetInt(int(destination.Fd()), _FICLONE, int(source.Fd())); err != nil {
		return &os.LinkError{
			Op:  "clonefile",
			Old: src,
			New: dst,
			Err: err,
		}
	}

	return nil
}
