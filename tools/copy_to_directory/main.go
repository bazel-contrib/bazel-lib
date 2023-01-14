package main

import (
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"io/ioutil"
	"log"
	"os"
	"path"
	"path/filepath"
	"strings"

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
}

type copyMap map[string]fileInfo
type pathSet map[string]bool

func parseConfig(configPath string) (*config, error) {
	f, err := os.Open(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open config file: %w", err)
	}
	defer f.Close()

	byteValue, err := ioutil.ReadAll(f)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var cfg config
	if err := json.Unmarshal([]byte(byteValue), &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	cfg.ReplacePrefixesKeys = maps.Keys(cfg.ReplacePrefixes)

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

func calcCopyDir(cfg *config, copyPaths copyMap, srcPaths pathSet, file fileInfo) error {
	if srcPaths == nil {
		srcPaths = pathSet{}
	}
	srcPaths[file.Path] = true
	// filepath.WalkDir walks the file tree rooted at root, calling fn for each file or directory in
	// the tree, including root. See https://pkg.go.dev/path/filepath#WalkDir for more info.
	// TODO: switch to the more efficient https://pkg.go.dev/io/fs#WalkDirFunc variant?
	return filepath.Walk(file.Path, func(p string, info os.FileInfo, err error) error {
		if info.IsDir() {
			// remember that this directory was visited to prevent infinite recursive symlink loops and
			// then short-circuit by returning nil since filepath.Walk will visit files contained within
			// this directory automatically
			srcPaths[p] = true
			return nil
		}

		if info.Mode()&os.ModeSymlink == os.ModeSymlink {
			// symlink to directories are intentionally never followed by filepath.Walk to avoid infinite recursion
			linkPath, err := os.Readlink(p)
			if err != nil {
				return err
			}
			if !path.IsAbs(linkPath) {
				linkPath = path.Join(path.Dir(p), linkPath)
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
				return calcCopyDir(cfg, copyPaths, srcPaths, f)
			} else {
				// symlink points to a regular file
				r, err := filepath.Rel(file.Path, p)
				if err != nil {
					return fmt.Errorf("failed to walk directory %s: %w", file.Path, err)
				}
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
				return calcCopyPath(cfg, copyPaths, f)
			}
		}

		// a regular file
		r, err := filepath.Rel(file.Path, p)
		if err != nil {
			return fmt.Errorf("failed to walk directory %s: %w", file.Path, err)
		}
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
		return calcCopyPath(cfg, copyPaths, f)
	})
}

func calcCopyPath(cfg *config, copyPaths copyMap, file fileInfo) error {
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
	if file.Workspace != "" {
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
		outputPath = outputPath[len(rootPathMatch):]
		if strings.HasPrefix(outputPath, "/") {
			outputPath = outputPath[1:]
		}
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
	dup, exists := copyPaths[outputPath]
	if exists {
		if dup.ShortPath == file.ShortPath {
			if file.FileInfo.Size() == dup.FileInfo.Size() && file.RootPath == "" {
				// this is likely the same file listed twice: the original in the source tree and the copy
				// in the output tree; when this happens prefer the output tree copy.
				return nil
			}
		} else if !cfg.AllowOverwrites {
			return fmt.Errorf("duplicate output file '%s' configured from source files '%s' and '%s'; set 'allow_overwrites' to True to allow this overwrites but keep in mind that order matters when this is set", outputPath, dup.Path, file.Path)
		}
	}
	copyPaths[outputPath] = file

	return nil
}

func calcCopyPaths(cfg *config) (copyMap, error) {
	copyPaths := copyMap{}
	for _, file := range cfg.Files {
		stat, err := os.Stat(file.Path)
		if err != nil {
			return nil, fmt.Errorf("failed to stat file %s: %w", file.Path, err)
		}
		file.FileInfo = stat
		if file.FileInfo.IsDir() {
			if err := calcCopyDir(cfg, copyPaths, nil, file); err != nil {
				return nil, err
			}
		} else {
			if err := calcCopyPath(cfg, copyPaths, file); err != nil {
				return nil, err
			}
		}
	}
	return copyPaths, nil
}

// From https://opensource.com/article/18/6/copying-files-go
func copy(src fileInfo, dst string) error {
	source, err := os.Open(src.Path)
	if err != nil {
		return err
	}
	defer source.Close()

	destination, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destination.Close()
	_, err = io.Copy(destination, source)
	return err
}

// https://play.golang.org/p/Qg_uv_inCek
// contains checks if a string is present in a slice
func contains(s []string, str string) bool {
	for _, v := range s {
		if v == str {
			return true
		}
	}

	return false
}

func version() string {
	var versionBuilder strings.Builder
	if Release != "" && Release != PreStampRelease {
		versionBuilder.WriteString(Release)
		if GitStatus != CleanGitStatus {
			versionBuilder.WriteString(NotCleanVersionSuffix)
		}
	} else {
		versionBuilder.WriteString(NoReleaseVersion)
	}
	return versionBuilder.String()
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: copy_to_directory [config_file]")
		os.Exit(1)
	}

	if contains(os.Args[1:], "--version") || contains(os.Args[1:], "-v") {
		fmt.Printf("copy_to_directory %s\n", version())
		return
	}

	cfg, err := parseConfig(os.Args[1])
	if err != nil {
		log.Fatal(err)
	}

	// Calculate copy paths
	copyPaths, err := calcCopyPaths(cfg)
	if err != nil {
		log.Fatal(err)
	}

	// Perform copies
	// TODO: split out into parallel go routines?
	for to, from := range copyPaths {
		err := os.MkdirAll(path.Dir(to), os.ModePerm)
		if err != nil {
			log.Fatal(err)
		}
		if !from.FileInfo.Mode().IsRegular() {
			log.Fatalf("%s is not a regular file", from.Path)
		}
		if from.Hardlink {
			// hardlink this file
			if cfg.Verbose {
				fmt.Printf("hardlink %v => %v\n", from.Path, to)
			}
			err = os.Link(from.Path, to)
			if err != nil {
				// fallback to copy
				if cfg.Verbose {
					fmt.Printf("hardlink failed: %v\n", err)
					fmt.Printf("copy (fallback) %v => %v\n", from.Path, to)
				}
				err = copy(from, to)
				if err != nil {
					log.Fatal(err)
				}
			}
		} else {
			// copy this file
			if cfg.Verbose {
				fmt.Printf("copy %v => %v\n", from.Path, to)
			}
			err = copy(from, to)
			if err != nil {
				log.Fatal(err)
			}
		}
	}
}
