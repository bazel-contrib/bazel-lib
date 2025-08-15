module github.com/bazel-contrib/bazel-lib

<!-- 
upgrade to go 1.23 may require fixing copy.go as there are some 
changes in symlink handling in go/windows.
These are caught by e2e\smoke
https://tip.golang.org/doc/go1.23#ospkgos
-->
go 1.22.7

require (
	github.com/bazelbuild/rules_go v0.55.0
	github.com/bmatcuk/doublestar/v4 v4.7.1
	golang.org/x/exp v0.0.0-20240823005443-9b4947da3948
	golang.org/x/sys v0.30.0
)
