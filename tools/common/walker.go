package common

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sync"
)

type Walker struct {
	queue chan<- CopyFileOpts
	wg    sync.WaitGroup
}

func NewWalker(queueDepth int, numWorkers int) *Walker {
	queue := make(chan CopyFileOpts, 100)
	var wg sync.WaitGroup

	wg.Add(numWorkers)
	for i := 0; i < numWorkers; i++ {
		go NewCopyWorker(queue).Run(&wg)
	}

	return &Walker{queue, wg}
}

func (w *Walker) Close() {
	close(w.queue)
	w.wg.Wait()
}

func (w *Walker) CopyFile(src string, dst string, info fs.FileInfo, opts CopyOpts) {
	w.queue <- NewCopyFileOpts(src, dst, info, opts)
}

func (w *Walker) CopyDir(src string, dst string, opts CopyOpts) error {
	srcPaths := map[string]bool{}
	// filepath.WalkDir walks the file tree rooted at root, calling fn for each file or directory in
	// the tree, including root. See https://pkg.go.dev/path/filepath#WalkDir for more info.
	return filepath.WalkDir(src, func(p string, dirEntry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		r, err := FileRel(src, p)
		if err != nil {
			return err
		}

		d := filepath.Join(dst, r)

		if dirEntry.IsDir() {
			srcPaths[src] = true
			return os.MkdirAll(d, os.ModePerm)
		}

		info, err := dirEntry.Info()
		if err != nil {
			return err
		}

		if info.Mode()&os.ModeSymlink == os.ModeSymlink {
			// symlink to directories are intentionally never followed by filepath.Walk to avoid infinite recursion
			linkPath, err := Realpath(p)
			if err != nil {
				if os.IsNotExist(err) {
					return fmt.Errorf("failed to get realpath of dangling symlink %s: %w", p, err)
				}
				return fmt.Errorf("failed to get realpath of %s: %w", p, err)
			}
			if srcPaths[linkPath] {
				// recursive symlink; silently ignore
				return nil
			}
			stat, err := os.Stat(linkPath)
			if err != nil {
				return fmt.Errorf("failed to stat file %s pointed to by symlink %s: %w", linkPath, p, err)
			}
			if stat.IsDir() {
				// symlink points to a directory
				return w.CopyDir(linkPath, d, opts)
			} else {
				// symlink points to a regular file
				w.queue <- NewCopyFileOpts(linkPath, d, stat, opts)
				return nil
			}
		}

		// a regular file
		w.queue <- NewCopyFileOpts(p, d, info, opts)
		return nil
	})
}
