package common

import "strings"

func Version() string {
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
