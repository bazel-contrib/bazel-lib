"Public API"

load("//lib/private:repo_utils.bzl", "repo_utils")
load("//lib/private:patch.bzl", _patch = "patch")

is_windows_os = repo_utils.is_windows_os
is_darwin_os = repo_utils.is_darwin_os
is_linux_os = repo_utils.is_linux_os
patch = _patch
