package main

import (
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"log"
	"os"
	"path"
	"path/filepath"
	"strings"
	"sync"

	"github.com/aspect-build/bazel-lib/tools/common"
	"github.com/bmatcuk/doublestar/v4"
	"golang.org/x/exp/maps"
)

type fileInfo struct {
	Package       string `json:"package"`
	Path          string `json:"path"`
	RootPath      string `json:"root_path"`
	ShortPath     string `json:"short_path"`
	Workspace     string `json:"workspace"`
	WorkspacePath string `json:"workspace_path"`
	Hardlink      bool   `json:"hardlink"`

	Realpath string
	FileInfo fs.FileInfo
}

type config struct {
	AllowOverwrites             bool              `json:"allow_overwrites"`
	Dst                         string            `json:"dst"`
	ExcludeSrcsPackages         []string          `json:"exclude_srcs_packages"`
	ExcludeSrcsPatterns         []string          `json:"exclude_srcs_patterns"`
	Files                       []fileInfo        `json:"files"`
	IncludeExternalRepositories []string          `json:"include_external_repositories"`
	IncludeSrcsPackages         []string          `json:"include_srcs_packages"`
	IncludeSrcsPatterns         []string          `json:"include_srcs_patterns"`
	ReplacePrefixes             map[string]string `json:"replace_prefixes"`
	RootPaths                   []string          `json:"root_paths"`
	Verbose                     bool              `json:"verbose"`

	ReplacePrefixesKeys []string
	TargetWorkspace     *string
}

type copyMap map[string]fileInfo
type pathSet map[string]bool

var copySet = copyMap{}
var mkdirSet = pathSet{}

func parseConfig(configPath string, wkspName *string) (*config, error) {
	f, err := os.Open(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open config file: %w", err)
	}
	defer f.Close()

	byteValue, err := io.ReadAll(f)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var cfg config
	if err := json.Unmarshal([]byte(byteValue), &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	cfg.ReplacePrefixesKeys = maps.Keys(cfg.ReplacePrefixes)
	cfg.TargetWorkspace = wkspName

	return &cfg, nil
}

func anyGlobsMatch(globs []string, test string) (bool, error) {
	for _, g := range globs {
		match, err := doublestar.Match(g, test)
		if err != nil {
			return false, err
		}
		if match {
			return true, nil
		}
	}
	return false, nil
}

func longestGlobsMatch(globs []string, test string) (string, int, error) {
	result := ""
	index := 0
	for i, g := range globs {
		match, err := longestGlobMatch(g, test)
		if err != nil {
			return "", 0, err
		}
		if len(match) > len(result) {
			result = match
			index = i
		}
	}
	return result, index, nil
}

func longestGlobMatch(g string, test string) (string, error) {
	for i := 0; i < len(test); i++ {
		t := test[:len(test)-i]
		match, err := doublestar.Match(g, t)
		if err != nil {
			return "", err
		}
		if match {
			return t, nil
		}
	}
	return "", nil
}

type walker struct {
	queue chan<- common.CopyOpts
}

func (w *walker) copyDir(cfg *config, srcPaths pathSet, file fileInfo) error {
	if srcPaths == nil {
		srcPaths = pathSet{}
	}
	srcPaths[file.Path] = true
	// filepath.WalkDir walks the file tree rooted at root, calling fn for each file or directory in
	// the tree, including root. See https://pkg.go.dev/path/filepath#WalkDir for more info.
	walkPath := file.Path
	if file.Realpath != "" {
		walkPath = file.Realpath
	}
	return filepath.WalkDir(walkPath, func(p string, dirEntry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if dirEntry.IsDir() {
			// remember that this directory was visited to prevent infinite recursive symlink loops and
			// then short-circuit by returning nil since filepath.Walk will visit files contained within
			// this directory automatically
			srcPaths[p] = true
			return nil
		}

		info, err := dirEntry.Info()
		if err != nil {
			return err
		}

		r, err := common.FileRel(walkPath, p)
		if err != nil {
			return err
		}

		if info.Mode()&os.ModeSymlink == os.ModeSymlink {
			// symlink to directories are intentionally never followed by filepath.Walk to avoid infinite recursion
			linkPath, err := common.Realpath(p)
			if err != nil {
				return err
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
				f := fileInfo{
					Package:       file.Package,
					Path:          linkPath,
					RootPath:      file.RootPath,
					ShortPath:     path.Join(file.ShortPath),
					Workspace:     file.Workspace,
					WorkspacePath: path.Join(file.WorkspacePath),
					Hardlink:      file.Hardlink,
					FileInfo:      stat,
				}
				return w.copyDir(cfg, srcPaths, f)
			} else {
				// symlink points to a regular file
				f := fileInfo{
					Package:       file.Package,
					Path:          linkPath,
					RootPath:      file.RootPath,
					ShortPath:     path.Join(file.ShortPath, r),
					Workspace:     file.Workspace,
					WorkspacePath: path.Join(file.WorkspacePath, r),
					Hardlink:      file.Hardlink,
					FileInfo:      stat,
				}
				return w.copyPath(cfg, f)
			}
		}

		// a regular file
		f := fileInfo{
			Package:       file.Package,
			Path:          p,
			RootPath:      file.RootPath,
			ShortPath:     path.Join(file.ShortPath, r),
			Workspace:     file.Workspace,
			WorkspacePath: path.Join(file.WorkspacePath, r),
			Hardlink:      file.Hardlink,
			FileInfo:      info,
		}
		return w.copyPath(cfg, f)
	})
}

func (w *walker) copyPath(cfg *config, file fileInfo) error {
	// Apply filters and transformations in the following order:
	//
	// - `include_external_repositories`
	// - `include_srcs_packages`
	// - `exclude_srcs_packages`
	// - `root_paths`
	// - `include_srcs_patterns`
	// - `exclude_srcs_patterns`
	// - `replace_prefixes`
	//
	// If you change this order please update the docstrings in the copy_to_directory rule.

	outputPath := file.WorkspacePath
	outputRoot := path.Dir(outputPath)

	// apply include_external_repositories (if the file is from an external repository)
	// automatically include files from the same workspace as this target, even if
	// that is an external workspace with respect to `__main__`
	if file.Workspace != "" && (cfg.TargetWorkspace == nil || file.Workspace != *cfg.TargetWorkspace) {
		match, err := anyGlobsMatch(cfg.IncludeExternalRepositories, file.Workspace)
		if err != nil {
			return err
		}
		if !match {
			return nil // external workspace is not included
		}
	}

	// apply include_srcs_packages
	match, err := anyGlobsMatch(cfg.IncludeSrcsPackages, file.Package)
	if err != nil {
		return err
	}
	if !match {
		return nil // package is not included
	}

	// apply exclude_srcs_packages
	match, err = anyGlobsMatch(cfg.ExcludeSrcsPackages, file.Package)
	if err != nil {
		return err
	}
	if match {
		return nil // package is excluded
	}

	// apply root_paths
	rootPathMatch, _, err := longestGlobsMatch(cfg.RootPaths, outputRoot)
	if err != nil {
		return err
	}
	if rootPathMatch != "" {
		outputPath = strings.TrimPrefix(outputPath[len(rootPathMatch):], "/")
	}

	// apply include_srcs_patterns
	match, err = anyGlobsMatch(cfg.IncludeSrcsPatterns, outputPath)
	if err != nil {
		return err
	}
	if !match {
		return nil // outputPath is not included
	}

	// apply exclude_srcs_patterns
	match, err = anyGlobsMatch(cfg.ExcludeSrcsPatterns, outputPath)
	if err != nil {
		return err
	}
	if match {
		return nil // outputPath is excluded
	}

	// apply replace_prefixes
	replacePrefixMatch, replacePrefixIndex, err := longestGlobsMatch(cfg.ReplacePrefixesKeys, outputPath)
	if err != nil {
		return err
	}
	if replacePrefixMatch != "" {
		replaceWith := cfg.ReplacePrefixes[cfg.ReplacePrefixesKeys[replacePrefixIndex]]
		outputPath = replaceWith + outputPath[len(replacePrefixMatch):]
	}

	outputPath = path.Join(cfg.Dst, outputPath)

	// add this file to the copy Paths
	dup, exists := copySet[outputPath]
	if exists {
		if dup.ShortPath == file.ShortPath && file.FileInfo.Size() == dup.FileInfo.Size() {
			// this is likely the same file listed twice: the original in the source tree and the copy in the output tree
			return nil
		} else if !cfg.AllowOverwrites {
			return fmt.Errorf("duplicate output file '%s' configured from source files '%s' and '%s'; set 'allow_overwrites' to True to allow this overwrites but keep in mind that order matters when this is set", outputPath, dup.Path, file.Path)
		}
	}
	copySet[outputPath] = file

	outputDir := path.Dir(outputPath)
	if !mkdirSet[outputDir] {
		if err = os.MkdirAll(outputDir, os.ModePerm); err != nil {
			return err
		}
		// https://pkg.go.dev/path#Dir
		for len(outputDir) > 0 && outputDir != "/" && outputDir != "." {
			mkdirSet[outputDir] = true
			outputDir = path.Dir(outputDir)
		}
	}

	if !cfg.AllowOverwrites {
		// if we don't allow overwrites then we can start copying as soon as a copy is calculated
		w.queue <- common.NewCopyOpts(file.Path, outputPath, file.FileInfo, file.Hardlink, cfg.Verbose)
	}

	return nil
}

func (w *walker) copyPaths(cfg *config) error {
	for _, file := range cfg.Files {
		info, err := os.Lstat(file.Path)
		if err != nil {
			return fmt.Errorf("failed to lstat file %s: %w", file.Path, err)
		}

		if info.Mode()&os.ModeSymlink == os.ModeSymlink {
			// On Windows, filepath.WalkDir doesn't like directory symlinks so we must
			// call filepath.WalkDir on the realpath
			realpath, err := common.Realpath(file.Path)
			if err != nil {
				return err
			}
			stat, err := os.Stat(realpath)
			if err != nil {
				return fmt.Errorf("failed to stat file %s pointed to by symlink %s: %w", realpath, file.Path, err)
			}
			file.Realpath = realpath
			file.FileInfo = stat
		} else {
			file.FileInfo = info
		}

		if file.FileInfo.IsDir() {
			if err := w.copyDir(cfg, nil, file); err != nil {
				return err
			}
		} else {
			if err := w.copyPath(cfg, file); err != nil {
				return err
			}
		}
	}
	return nil
}

func main() {
	args := os.Args[1:]

	if len(args) != 1 && len(args) != 2 {
		fmt.Println("Usage: copy_to_directory config_file [workspace_name]")
		os.Exit(1)
	}

	configFile := args[0]

	// Read workspace arg if present.
	var wksp *string = nil
	if len(args) >= 2 {
		wksp = &args[1]
	}

	cfg, err := parseConfig(configFile, wksp)
	if err != nil {
		log.Fatal(err)
	}

	queue := make(chan common.CopyOpts, 100)
	var wg sync.WaitGroup

	const numWorkers = 10
	wg.Add(numWorkers)
	for i := 0; i < numWorkers; i++ {
		go common.NewCopyWorker(queue).Run(&wg)
	}

	walker := &walker{queue}
	if err = walker.copyPaths(cfg); err != nil {
		log.Fatal(err)
	}

	if cfg.AllowOverwrites {
		// if we allow overwrites then we must wait until all copy paths are calculated before starting
		// any copy operations
		for outputPath, file := range copySet {
			queue <- common.NewCopyOpts(file.Path, outputPath, file.FileInfo, file.Hardlink, cfg.Verbose)
		}
	}

	close(queue)
	wg.Wait()
}
