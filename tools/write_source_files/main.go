package main

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"syscall"
)

const (
	maxConcurrency = 16
	bufSize        = 128 * 1024 // 128 KB
)

var bufPool = sync.Pool{
	New: func() any {
		return make([]byte, bufSize)
	},
}

type copyAction struct {
	srcPath, dstPath string
	executable       bool
}

// openDst tries to create dst (0755 if exec, default otherwise).
// On ENOENT it will mkdir parent and retry once.
func openDst(dst string, exec bool) (*os.File, error) {
	try := func() (*os.File, error) {
		if exec {
			return os.OpenFile(dst, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0755)
		}
		return os.Create(dst)
	}

	out, err := try()
	if err == nil {
		return out, nil
	}
	if os.IsNotExist(err) {
		// parent missing → create and retry
		if mkErr := os.MkdirAll(filepath.Dir(dst), 0755); mkErr != nil {
			return nil, fmt.Errorf("mkdir parent of %s: %w", dst, mkErr)
		}
		return try()
	}
	return nil, fmt.Errorf("create %s: %w", dst, err)
}

// copyRegularFile opens src, creates dst via openDst, and streams the copy.
func copyFile(src, dst string, exec bool) error {
	in, err := os.Open(src)
	if err != nil {
		return fmt.Errorf("open %s: %w", src, err)
	}
	defer in.Close()

	out, err := openDst(dst, exec)
	if err != nil {
		return err
	}
	defer out.Close()

	buf := bufPool.Get().([]byte)
	defer bufPool.Put(buf)
	if _, err := io.CopyBuffer(out, in, buf); err != nil {
		return fmt.Errorf("copy %s → %s: %w", src, dst, err)
	}
	return nil
}

// copyDir walks srcDir and for each entry creates dirs or delegates to copyRegularFile.
func copyDir(srcDir, dstDir string, exec bool) error {
	realSrc, err := filepath.EvalSymlinks(srcDir)
	if err != nil {
		return fmt.Errorf("resolving %q: %w", srcDir, err)
	}
	return filepath.Walk(realSrc, func(curr string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(realSrc, curr)
		if err != nil {
			return err
		}
		target := filepath.Join(dstDir, rel)

		if info.IsDir() {
			return os.MkdirAll(target, 0755)
		}
		return copyFile(curr, target, exec)
	})
}

func doCopy(action copyAction) error {
	// first, try to copy as a file
	if err := copyFile(action.srcPath, action.dstPath, action.executable); err != nil {
		// if srcPath is actually a directory, copyFile should fail with EISDIR
		if errors.Is(err, syscall.EISDIR) {
			fmt.Println("Copying directory", action.srcPath, "to", action.dstPath)
			err = os.RemoveAll(action.dstPath)
			if err != nil {
				return err
			}
			return copyDir(action.srcPath, action.dstPath, action.executable)
		}
		// otherwise propogate the real error
		return err
	}
	fmt.Println("Copying file", action.srcPath, "to", action.dstPath)
	return nil
}

func copyAll(actions []copyAction) error {
	sem := make(chan struct{}, maxConcurrency)
	errCh := make(chan error, len(actions))
	var wg sync.WaitGroup

	for _, action := range actions {
		wg.Add(1)
		go func() {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			if err := doCopy(action); err != nil {
				errCh <- err
			}
		}()
	}

	wg.Wait()
	close(errCh)
	for err := range errCh {
		return err
	}
	return nil
}

func main() {
	argsPath := os.Getenv("ARGS_PATH")
	repoRoot := os.Getenv("BUILD_WORKSPACE_DIRECTORY")

	args, err := os.ReadFile(argsPath)
	if err != nil {
		panic(err)
	}

	items := strings.Split(string(args), "\n")

	actions := make([]copyAction, len(items)/3)
	for i := range actions {
		srcPath := items[i*3]
		dstPath := filepath.Join(repoRoot, items[i*3+1])
		executable, err := strconv.ParseBool(items[i*3+2])
		if err != nil {
			panic(err)
		}

		actions[i] = copyAction{srcPath, dstPath, executable}
	}

	err = copyAll(actions)
	if err != nil {
		panic(err)
	}
}
