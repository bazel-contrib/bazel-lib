package main

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"path"
	"path/filepath"
	"strings"

	"github.com/gobwas/glob"
	"golang.org/x/exp/maps"
)

type fileInfo struct {
	MaybeDirectory bool   `json:"maybe_directory"`
	Package        string `json:"package"`
	Path           string `json:"path"`
	RootPath       string `json:"root_path"`
	ShortPath      string `json:"short_path"`
	Workspace      string `json:"workspace"`
	WorkspacePath  string `json:"workspace_path"`
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

	ExcludeSrcsPackagesGlobs         []glob.Glob
	ExcludeSrcsPatternsGlobs         []glob.Glob
	IncludeExternalRepositoriesGlobs []glob.Glob
	IncludeSrcsPackagesGlobs         []glob.Glob
	IncludeSrcsPatternsGlobs         []glob.Glob
	ReplacePrefixesGlobs             []glob.Glob
	ReplacePrefixesKeys              []string
	RootPathsGlobs                   []glob.Glob
}

type copyPaths map[string]fileInfo

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

	// compile all globs
	cfg.ExcludeSrcsPackagesGlobs, err = compileGlobs(cfg.ExcludeSrcsPackages)
	if err != nil {
		return nil, err
	}

	cfg.ExcludeSrcsPatternsGlobs, err = compileGlobs(cfg.ExcludeSrcsPatterns)
	if err != nil {
		return nil, err
	}

	cfg.IncludeExternalRepositoriesGlobs, err = compileGlobs(cfg.IncludeExternalRepositories)
	if err != nil {
		return nil, err
	}

	cfg.IncludeSrcsPackagesGlobs, err = compileGlobs(cfg.IncludeSrcsPackages)
	if err != nil {
		return nil, err
	}

	cfg.IncludeSrcsPatternsGlobs, err = compileGlobs(cfg.IncludeSrcsPatterns)
	if err != nil {
		return nil, err
	}

	cfg.RootPathsGlobs, err = compileGlobs(cfg.RootPaths)
	if err != nil {
		return nil, err
	}

	cfg.ReplacePrefixesKeys = maps.Keys(cfg.ReplacePrefixes)
	cfg.ReplacePrefixesGlobs, err = compileGlobs(cfg.ReplacePrefixesKeys)
	if err != nil {
		return nil, err
	}

	return &cfg, nil
}

func compileGlobs(patterns []string) ([]glob.Glob, error) {
	result := make([]glob.Glob, len(patterns))
	for i, pattern := range patterns {
		g, err := glob.Compile(pattern)
		if err != nil {
			return nil, fmt.Errorf("failed to compile glob pattern '%s': %w", pattern, err)
		}
		result[i] = g
	}
	return result, nil
}

func anyGlobsMatch(globs []glob.Glob, test string) bool {
	for _, g := range globs {
		if g.Match(test) {
			return true
		}
	}
	return false
}

func longestGlobsMatch(globs []glob.Glob, test string) (string, int) {
	result := ""
	index := 0
	for i, g := range globs {
		match := longestGlobMatch(g, test)
		if len(match) > len(result) {
			result = match
			index = i
		}
	}
	return result, index
}

func longestGlobMatch(g glob.Glob, test string) string {
	for i := 0; i < len(test); i++ {
		t := test[:len(test)-i]
		if g.Match(t) {
			return t
		}
	}
	return ""
}

// From https://stackoverflow.com/a/49196644
func filePathWalkDir(root string) ([]string, error) {
	var files []string
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if !info.IsDir() {
			files = append(files, path)
		}
		return nil
	})
	return files, err
}

func calcCopyPath(cfg *config, copyPaths copyPaths, file fileInfo) error {
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
		if !anyGlobsMatch(cfg.IncludeExternalRepositoriesGlobs, file.Workspace) {
			return nil // external workspace is not included
		}
	}

	// apply include_srcs_packages
	if !anyGlobsMatch(cfg.IncludeSrcsPackagesGlobs, file.Package) {
		return nil // package is not included
	}

	// apply exclude_srcs_packages
	if anyGlobsMatch(cfg.ExcludeSrcsPackagesGlobs, file.Package) {
		return nil // package is excluded
	}

	// apply root_paths
	rootPathMatch, _ := longestGlobsMatch(cfg.RootPathsGlobs, outputRoot)
	if rootPathMatch != "" {
		outputPath = outputPath[len(rootPathMatch):]
		if strings.HasPrefix(outputPath, "/") {
			outputPath = outputPath[1:]
		}
	}

	// apply include_srcs_patterns
	if !anyGlobsMatch(cfg.IncludeSrcsPatternsGlobs, outputPath) {
		return nil // outputPath is not included
	}

	// apply include_srcs_patterns
	if anyGlobsMatch(cfg.ExcludeSrcsPatternsGlobs, outputPath) {
		return nil // outputPath is excluded
	}

	// apply replace_prefixes
	replacePrefixMatch, replacePrefixIndex := longestGlobsMatch(cfg.ReplacePrefixesGlobs, outputPath)
	if replacePrefixMatch != "" {
		replaceWith := cfg.ReplacePrefixes[cfg.ReplacePrefixesKeys[replacePrefixIndex]]
		outputPath = replaceWith + outputPath[len(replacePrefixMatch):]
	}

	outputPath = path.Join(cfg.Dst, outputPath)

	// add this file to the copy Paths
	dup, exists := copyPaths[outputPath]
	if exists {
		if dup.ShortPath == file.ShortPath {
			// this is likely the same file listed twice: the original in the source
			// tree and the copy in the output tree
			// TODO: stat the two files to double check that they are the same
			if file.RootPath == "" {
				// when this happens prefer the output tree copy.
				return nil
			}
		} else if !cfg.AllowOverwrites {
			return fmt.Errorf("duplicate output file '%s' configured from source files '%s' and '%s'; set 'allow_overwrites' to True to allow this overwrites but keep in mind that order matters when this is set", outputPath, dup.Path, file.Path)
		}
	}
	copyPaths[outputPath] = file

	return nil
}

func calcCopyPaths(cfg *config) (copyPaths, error) {
	result := copyPaths{}

	for _, file := range cfg.Files {
		if file.MaybeDirectory {
			// This entry may be a directory
			s, err := os.Stat(file.Path)
			if err != nil {
				return nil, fmt.Errorf("failed to stats file %s: %w", file.Path, err)
			}
			if s.IsDir() {
				// List files in the directory recursively and copy each file individually
				files, err := filePathWalkDir(file.Path)
				if err != nil {
					return nil, fmt.Errorf("failed to walk directory %s: %w", file.Path, err)
				}
				for _, f := range files {
					r, err := filepath.Rel(file.Path, f)
					if err != nil {
						return nil, fmt.Errorf("failed to walk directory %s: %w", file.Path, err)
					}
					dirFile := fileInfo{
						MaybeDirectory: false,
						Package:        file.Package,
						Path:           f,
						RootPath:       file.RootPath,
						ShortPath:      path.Join(file.ShortPath, r),
						Workspace:      file.Workspace,
						WorkspacePath:  path.Join(file.WorkspacePath, r),
					}
					if err := calcCopyPath(cfg, result, dirFile); err != nil {
						return nil, err
					}
				}
				continue
			}
			// The entry is not a directory
			file.MaybeDirectory = false
		}
		if err := calcCopyPath(cfg, result, file); err != nil {
			return nil, err
		}
	}

	return result, nil
}

// From https://opensource.com/article/18/6/copying-files-go
func copy(src, dst string) (int64, error) {
	sourceFileStat, err := os.Stat(src)
	if err != nil {
		return 0, err
	}

	if !sourceFileStat.Mode().IsRegular() {
		return 0, fmt.Errorf("%s is not a regular file", src)
	}

	source, err := os.Open(src)
	if err != nil {
		return 0, err
	}
	defer source.Close()

	destination, err := os.Create(dst)
	if err != nil {
		return 0, err
	}
	defer destination.Close()
	nBytes, err := io.Copy(destination, source)
	return nBytes, err
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
		if cfg.Verbose {
			fmt.Printf("%v => %v\n", from.Path, to)
		}
		err := os.MkdirAll(path.Dir(to), os.ModePerm)
		if err != nil {
			log.Fatal(err)
		}
		_, err = copy(from.Path, to)
		if err != nil {
			log.Fatal(err)
		}
	}
}
