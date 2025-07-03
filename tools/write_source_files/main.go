package main

import (
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/bazel-contrib/bazel-lib/tools/common"
)

type copyAction struct {
	srcPath, dstPath string
	executable       bool
}

func copyAll(actions []copyAction) error {
	walker := common.NewWalker(100, 16)
	opts := common.CopyOpts{Verbose: true}

	for _, action := range actions {
		info, err := os.Stat(action.srcPath)
		if err != nil {
			return err
		}

		if info.IsDir() {
			walker.CopyDir(action.srcPath, action.dstPath, opts)
		} else {
			walker.CopyFile(action.srcPath, action.dstPath, info, opts)
		}
	}

	walker.Close()

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
