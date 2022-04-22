"Public API"

load("//lib/private:repo_utils.bzl", "repo_utils")
load("//lib/private:patch.bzl", _patch = "patch")

is_darwin_os = repo_utils.is_darwin_os
is_linux_os = repo_utils.is_linux_os
is_windows_os = repo_utils.is_windows_os
get_env_var = repo_utils.get_env_var
os_name = repo_utils.os_name
os_arch_name = repo_utils.os_arch_name
patch = _patch
