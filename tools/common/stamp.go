// Variables in this file will be replaced by the linker when Bazel is run with --stamp
// The time should be in format '2018-12-12 12:30:00 UTC'
// The GitStatus should be either "clean" or "dirty"
// Release will be a comma-separated string representation of any tags.

package common

// BuildTime is a string representation of when this binary was built.
var BuildTime = "an unknown time"

// GitCommit is the revision this binary was built from.
var GitCommit = "an unknown revision"

// GitStatus is whether the git workspace was clean.
var GitStatus = "unknown"

// HostName is the machine where this binary was built.
var HostName = "an unknown machine"

// Release is the revision number, if any.
var Release = "no release"

func IsStamped() bool {
	return BuildTime != "{BUILD_TIMESTAMP}"
}

const (
	// Git status
	CleanGitStatus = "clean"

	// Release values
	PreStampRelease = "no release"

	// Version constants
	NotCleanVersionSuffix = " (with local changes)"
	NoReleaseVersion      = "unknown [not built with --stamp]"
)
