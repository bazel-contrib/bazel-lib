package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

func main() {
	// Define command-line flags
	inputFile := flag.String("input", "", "Path to the input file (required)")
	outputFile := flag.String("output", "", "Path to the output file (required)")
	strip_prefix := flag.String("strip_prefix", "", "Prefix to strip from paths")
	package_dir := flag.String("package_dir", "", "Directory to prepend to paths")
	mtime := flag.String("mtime", "", "Modify time for mtree entries")
	owner := flag.String("owner", "", "Owner ID for mtree entries")
	ownername := flag.String("ownername", "", "Owner name for mtree entries")
	bin_dir := flag.String("bin_dir", "", "Directory to check for symlink resolution")
	flag.Parse()

	// Check if required flags are provided
	if *inputFile == "" || *outputFile == "" {
		flag.Usage()
		fmt.Println("Error: Both -input and -output flags are required.")
		os.Exit(1)
	}

	// Open input file
	file, err := os.Open(*inputFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error opening input file: %v\n", err)
		return
	}
	defer file.Close()

	// Create output file
	outFile, err := os.Create(*outputFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating output file: %v\n", err)
		return
	}
	defer outFile.Close()

	scanner := bufio.NewScanner(file)

	// Create map to hold paths
	paths := make(map[string]string)

	// First pass to gather paths
	for scanner.Scan() {
		line := scanner.Text()
		fields := strings.Fields(line)
		if len(fields) > 0 && strings.Contains(line, "content=") {
			contentIndex := strings.Index(line, "content=")
			if contentIndex != -1 {
				contentValue := line[contentIndex+len("content="):]
				endIndex := strings.Index(contentValue, " ")
				if endIndex == -1 {
					endIndex = len(contentValue)
				}
				paths[contentValue[:endIndex]] = fields[0]
			}
		}
	}

	// Resolve symlinks
	resolvedPaths, originalPaths := resolveAllSymlinks(paths, *bin_dir)

	// Reset scanner for second pass
	file.Seek(0, 0) // Reset file pointer to the start
	scanner = bufio.NewScanner(file)

	for scanner.Scan() {
		line := scanner.Text()
		fields := strings.Fields(line)
		if len(fields) == 0 {
			continue // Skip empty lines
		}

		// Handle strip_prefix
		if *strip_prefix != "" {
			if fields[0] == *strip_prefix {
				continue // Skip if this line declares the directory which is now the root
			} else if strings.HasPrefix(fields[0], *strip_prefix+"/") {
				fields[0] = strings.TrimPrefix(fields[0], *strip_prefix+"/")

				// Check if this is a directory at the root level
				components := strings.Split(fields[0], "/")
				if strings.Contains(line, "type=dir") && len(components) == 1 {
					if !strings.HasPrefix(line, " ") {
						fields[0] += "/" // If the line doesn't start with a space, append a slash
					} else {
						continue // Skip root directory entries with only orphaned keywords
					}
				}
			} else {
				continue // Skip lines that declare paths under a parent directory
			}
			line = strings.Join(fields, " ")
		}

		// Handle mtime
		if *mtime != "" {
			line = regexp.MustCompile(`time=[0-9\.]+`).ReplaceAllString(line, "time="+*mtime)
		}

		// Handle owner
		if *owner != "" {
			line = regexp.MustCompile(`uid=[0-9]+`).ReplaceAllString(line, "uid="+*owner)
		}

		// Handle ownername
		if *ownername != "" {
			line = regexp.MustCompile(`uname=[^ ]+`).ReplaceAllString(line, "uname="+*ownername)

		}

		// Handle package_dir
		if *package_dir != "" {
			fields[0] = filepath.Join(*package_dir, fields[0])
			line = strings.Join(fields, " ")
		}

		// Handle symlinks
		if strings.Contains(line, "type=file") && strings.Contains(line, "content=") {
			if resolvedPath, exists := resolvedPaths[fields[0]]; exists {
				newLine := fields[0] + " type=link link=" + resolvedPath
				fmt.Fprintln(outFile, newLine)
				continue
			} else if _, exists := originalPaths[fields[0]]; exists {
				// If it's an original path, keep the line as is but update content
				line = strings.Replace(line, "content=", "content="+originalPaths[fields[0]], 1)
			}
		}

		fmt.Fprintln(outFile, line)
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "Error reading input: %v\n", err)
	}
}

func resolveAllSymlinks(paths map[string]string, allowedPrefix string) (map[string]string, map[string]string) {
	resolvedPaths := make(map[string]string)
	originalPaths := make(map[string]string)
	for key, value := range paths {
		resolved, err := resolveSymlink(key, allowedPrefix)
		if err != nil {
			fmt.Printf("Error resolving symlink for %s: %v\n", key, err)
			continue
		}
		if resolved == "" {
			originalPaths[key] = value // Keep the original if not a symlink or outside prefix
		} else {
			resolvedPaths[value] = paths[resolved]
		}
	}
	return resolvedPaths, originalPaths
}

// resolveSymlink resolves a symlink and verifies its relationship to the allowed prefix.
func resolveSymlink(path string, allowedPrefix string) (string, error) {
	info, err := os.Lstat(path)
	if err != nil {
		return "", err
	}

	if info.Mode()&os.ModeSymlink == 0 {
		return "", nil
	}

	resolved, err := filepath.EvalSymlinks(path)
	if err != nil {
		return "", err
	}

	index := strings.LastIndex(resolved, allowedPrefix)
	if index == -1 {
		return "", nil
	}

	resolvedSuffix := resolved[index+len(allowedPrefix):]
	if resolvedSuffix == "" {
		return "", nil
	}
	resolvedPath := filepath.Join(allowedPrefix, resolvedSuffix)
	if resolvedPath == path {
		return "", nil
	}

	return resolvedPath, nil
}
