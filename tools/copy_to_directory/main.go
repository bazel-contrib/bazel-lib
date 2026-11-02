package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log"
	"os"
	"path"
	"path/filepath"
	"strconv"
	"strings"
	"sync"

	"github.com/bazel-contrib/bazel-lib/tools/common"
	"github.com/bmatcuk/doublestar/v4"
	"golang.org/x/exp/maps"
)

type fileInfo struct {
	Package       string `json:"package"`
	Path          string `json:"path"`
	ShortPath     string `json:"short_path"`
	Workspace     string `json:"workspace"`
	WorkspacePath string `json:"workspace_path"`
	Hardlink      bool   `json:"hardlink"`

	FileInfo fs.FileInfo
}

type config struct {
	AllowOverwrites             bool
	Dst                         string
	ExcludeSrcsPackages         []string
	ExcludeSrcsPatterns         []string
	Files                       []fileInfo
	IncludeExternalRepositories []string
	IncludeSrcsPackages         []string
	IncludeSrcsPatterns         []string
	ReplacePrefixes             map[string]string
	RootPaths                   []string
	PreserveMTime               bool
	Verbose                     bool

	ReplacePrefixesKeys []string
	TargetWorkspace     *string
}

type (
	copyMap map[string]fileInfo
	pathSet map[string]bool
)

var (
	copySet  = copyMap{}
	mkdirSet = pathSet{}
)

// paramsFile is a file to copy, as given by a --file flag.
type paramsFile struct {
	fileInfo
	IsSource bool `json:"is_source"`
}

// parseParams parses the params file written by copy_to_directory_bin_action,
// with one argument per line, in Bazel's "multiline" format. The paths in it
// are passed as arguments so that Bazel can path-map them.
func parseParams(paramsPath string) (*config, error) {
	contents, err := os.ReadFile(paramsPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read params file: %w", err)
	}
	args := strings.Split(strings.TrimSuffix(string(contents), "\n"), "\n")

	var cfg config
	var hardlink string
	var files []paramsFile

	// Errors are returned rather than printed, with the usage, by the flag set.
	flags := flag.NewFlagSet("copy_to_directory", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	workspace := flags.String("workspace", "", "the workspace of the target the directory is for")
	flags.StringVar(&cfg.Dst, "dst", "", "the directory to copy to")
	flags.StringVar(&hardlink, "hardlink", "auto", "whether to hardlink files: on, off, or auto for generated files only")
	boolFlag(flags, &cfg.AllowOverwrites, "allow_overwrites", "whether files may overwrite each other in the directory")
	boolFlag(flags, &cfg.PreserveMTime, "preserve_mtime", "whether to preserve the modification times of files")
	boolFlag(flags, &cfg.Verbose, "verbose", "whether to log the files copied")
	flags.Func("replace_prefixes", "the prefixes of output paths to replace, as a JSON object", func(value string) error {
		return json.Unmarshal([]byte(value), &cfg.ReplacePrefixes)
	})
	listFlag(flags, &cfg.RootPaths, "root_paths", "a root path of output paths")
	listFlag(flags, &cfg.IncludeExternalRepositories, "include_external_repositories", "an external repository to include files of")
	listFlag(flags, &cfg.IncludeSrcsPackages, "include_srcs_packages", "a glob of packages to include files of")
	listFlag(flags, &cfg.ExcludeSrcsPackages, "exclude_srcs_packages", "a glob of packages to exclude files of")
	listFlag(flags, &cfg.IncludeSrcsPatterns, "include_srcs_patterns", "a glob of output paths to include")
	listFlag(flags, &cfg.ExcludeSrcsPatterns, "exclude_srcs_patterns", "a glob of output paths to exclude")
	flags.Func("file", "a file to copy: its path, short_path, workspace_path, package, workspace, and is_source, as JSON", func(value string) error {
		var file paramsFile
		if err := json.Unmarshal([]byte(value), &file); err != nil {
			return err
		}
		files = append(files, file)
		return nil
	})
	if err := flags.Parse(args); err != nil {
		return nil, fmt.Errorf("failed to parse params file: %w", err)
	}
	if flags.NArg() > 0 {
		return nil, fmt.Errorf("failed to parse params file: unexpected arguments %v", flags.Args())
	}
	if cfg.Dst == "" {
		return nil, fmt.Errorf("failed to parse params file: missing --dst")
	}

	for _, file := range files {
		file.Hardlink = hardlink == "on" || (hardlink == "auto" && !file.IsSource)
		cfg.Files = append(cfg.Files, file.fileInfo)
	}
	cfg.ReplacePrefixesKeys = maps.Keys(cfg.ReplacePrefixes)
	cfg.TargetWorkspace = workspace

	return &cfg, nil
}

// boolFlag defines a flag taking a boolean value as a separate argument, unlike
// flag.Bool.
func boolFlag(flags *flag.FlagSet, p *bool, name, usage string) {
	flags.Func(name, usage, func(value string) error {
		b, err := strconv.ParseBool(value)
		*p = b
		return err
	})
}

// listFlag defines a flag that may be repeated, each value appended to the list.
func listFlag(flags *flag.FlagSet, p *[]string, name, usage string) {
	flags.Func(name, usage+"; may be repeated", func(value string) error {
		*p = append(*p, value)
		return nil
	})
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

		f := fileInfo{
			Package:       file.Package,
			Path:          p,
			ShortPath:     path.Join(file.ShortPath, r),
			Workspace:     file.Workspace,
			WorkspacePath: path.Join(file.WorkspacePath, r),
			Hardlink:      file.Hardlink,
			FileInfo:      info,
		}

		outputPath, err := w.calculateOutputPath(cfg, f)
		if err != nil {
			return fmt.Errorf("failed to calculate output path for %s: %w", file.WorkspacePath, err)
		}
		if outputPath == "" {
			// A directory link may contain matching descendants even when the
			// link itself is excluded. Still ignore excluded dangling/file links.
			if info.Mode()&os.ModeSymlink == 0 {
				return nil
			}
			stat, err := os.Stat(p)
			if err != nil || !stat.IsDir() {
				return nil
			}
		}

		// if file is a symlink, resolve its realpath
		if info.Mode()&os.ModeSymlink == os.ModeSymlink {
			realpath, err := common.Realpath(p)
			if err != nil {
				if os.IsNotExist(err) {
					return fmt.Errorf("failed to get realpath of dangling symlink %s: %w", p, err)
				}
				return fmt.Errorf("failed to get realpath of %s: %w", p, err)
			}
			if srcPaths[realpath] {
				// recursive symlink; silently ignore
				return nil
			}
			stat, err := os.Stat(realpath)
			if err != nil {
				return fmt.Errorf("failed to stat file %s pointed to by symlink %s: %w", realpath, p, err)
			}
			f.Path = realpath
			f.FileInfo = stat

			if stat.IsDir() {
				// symlink points to a directory
				return w.copyDir(cfg, srcPaths, f)
			}
		}

		return w.copyPath(cfg, f, outputPath)
	})
}

func (w *walker) calculateOutputPath(cfg *config, file fileInfo) (string, error) {
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
			return "", err
		}
		if !match {
			return "", nil // external workspace is not included
		}
	}

	// apply include_srcs_packages
	match, err := anyGlobsMatch(cfg.IncludeSrcsPackages, file.Package)
	if err != nil {
		return "", err
	}
	if !match {
		return "", nil // package is not included
	}

	// apply exclude_srcs_packages
	match, err = anyGlobsMatch(cfg.ExcludeSrcsPackages, file.Package)
	if err != nil {
		return "", err
	}
	if match {
		return "", nil // package is excluded
	}

	// apply root_paths
	rootPathMatch, _, err := longestGlobsMatch(cfg.RootPaths, outputRoot)
	if err != nil {
		return "", err
	}
	if rootPathMatch != "" {
		outputPath = strings.TrimPrefix(outputPath[len(rootPathMatch):], "/")
	}

	// apply include_srcs_patterns
	match, err = anyGlobsMatch(cfg.IncludeSrcsPatterns, outputPath)
	if err != nil {
		return "", err
	}
	if !match {
		return "", nil // outputPath is not included
	}

	// apply exclude_srcs_patterns
	match, err = anyGlobsMatch(cfg.ExcludeSrcsPatterns, outputPath)
	if err != nil {
		return "", err
	}
	if match {
		return "", nil // outputPath is excluded
	}

	// apply replace_prefixes
	replacePrefixMatch, replacePrefixIndex, err := longestGlobsMatch(cfg.ReplacePrefixesKeys, outputPath)
	if err != nil {
		return "", err
	}
	if replacePrefixMatch != "" {
		replaceWith := cfg.ReplacePrefixes[cfg.ReplacePrefixesKeys[replacePrefixIndex]]
		outputPath = replaceWith + outputPath[len(replacePrefixMatch):]
	}

	return path.Join(cfg.Dst, outputPath), nil
}

func (w *walker) copyPath(cfg *config, file fileInfo, outputPath string) error {
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
		if err := os.MkdirAll(outputDir, os.ModePerm); err != nil {
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
		w.queue <- common.NewCopyOpts(file.Path, outputPath, file.FileInfo, file.Hardlink, cfg.Verbose, cfg.PreserveMTime)
	}

	return nil
}

func (w *walker) copyPaths(cfg *config) error {
	for _, file := range cfg.Files {
		info, err := os.Lstat(file.Path)
		if err != nil {
			return fmt.Errorf("failed to lstat file %s: %w", file.Path, err)
		}
		file.FileInfo = info

		// if file is a directory, then short-circuit without calculating the output path
		if file.FileInfo.IsDir() {
			if err := w.copyDir(cfg, nil, file); err != nil {
				return err
			}
			continue
		}

		outputPath, err := w.calculateOutputPath(cfg, file)
		if err != nil {
			return fmt.Errorf("failed to calculate output path for %s: %w", file.WorkspacePath, err)
		}
		if outputPath == "" {
			// Apply descendant filters to directory links just as to real
			// directories. Keep excluded dangling/file links ignored.
			if info.Mode()&os.ModeSymlink == 0 {
				continue
			}
			stat, err := os.Stat(file.Path)
			if err != nil || !stat.IsDir() {
				continue
			}
		}

		// if file is a symlink, resolve its realpath
		if info.Mode()&os.ModeSymlink == os.ModeSymlink {
			realpath, err := common.Realpath(file.Path)
			if err != nil {
				if os.IsNotExist(err) {
					return fmt.Errorf("failed to get realpath of dangling symlink %s: %w", file.Path, err)
				}
				return fmt.Errorf("failed to get realpath of %s: %w", file.Path, err)
			}
			stat, err := os.Stat(realpath)
			if err != nil {
				return fmt.Errorf("failed to stat file %s pointed to by symlink %s: %w", realpath, file.Path, err)
			}
			file.Path = realpath
			file.FileInfo = stat

			if file.FileInfo.IsDir() {
				// symlink points to a directory
				if err := w.copyDir(cfg, nil, file); err != nil {
					return err
				}
				continue
			}
		}

		if err := w.copyPath(cfg, file, outputPath); err != nil {
			return err
		}
	}
	return nil
}

func main() {
	args := os.Args[1:]

	if len(args) != 1 || !strings.HasPrefix(args[0], "@") {
		fmt.Println("Usage: copy_to_directory @params_file")
		os.Exit(1)
	}

	cfg, err := parseParams(args[0][1:])
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
			queue <- common.NewCopyOpts(file.Path, outputPath, file.FileInfo, file.Hardlink, cfg.Verbose, cfg.PreserveMTime)
		}
	}

	close(queue)
	wg.Wait()
}
