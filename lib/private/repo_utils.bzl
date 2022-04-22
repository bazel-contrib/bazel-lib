"""Utility functions for repository rules"""

def _is_darwin_os(rctx):
    """Returns true if the host operating system is Darwin"""
    return rctx.os.name.lower().os_name.startswith("mac os")

def _is_linux_os(rctx):
    """Returns true if the host operating system is Linux"""
    return rctx.os.name.lower().startswith("linux")

def _is_windows_os(rctx):
    """Returns true if the host operating system is Windows"""
    return rctx.os.name.lower().find("windows") != -1

def _os_name(rctx):
    """Returns the name of the host operating system

    Args:
        rctx: repository_ctx

    Returns:
        The string "windows", "linux" or "darwin" that describes the host os
    """
    if _is_darwin_os(rctx):
        return "darwin"
    if _is_linux_os(rctx):
        return "linux"
    if _is_windows_os(rctx):
        return "windows"
    fail("unrecognized os")

def _get_env_var(rctx, name, default):
    """Find an environment variable in system. Doesn't %-escape the value!

    Args:
        rctx: repository_ctx
        name: environment variable name
        default: default value to return if env var is not set in system

    Returns:
        The environment variable value or the default if it is not set
    """
    if name in rctx.os.environ:
        return rctx.os.environ[name]
    return default

def _os_arch_name(rctx):
    """Returns a normalized name of the host os and CPU architecture.

    Alias archictures names are normalized:

    x86_64 => amd64
    aarch64 => arm64

    The result can be used to generate repository names for host toolchain
    repositories for toolchains that use these normalized names.

    Common os & architecture pairs that are returned are,

    - darwin_amd64
    - darwin_arm64
    - linux_amd64
    - linux_arm64
    - linux_s390x
    - linux_ppc64le
    - windows_amd64

    Args:
        rctx: repository_ctx

    Returns:
        The normalized "<os_name>_<arch>" string of the host os and CPU architecture.
    """
    os_name = _os_name(rctx)

    # NB: in bazel 5.1.1 rctx.os.arch was added which https://github.com/bazelbuild/bazel/commit/32d1606dac2fea730abe174c41870b7ee70ae041.
    # Once we drop support for anything older than Bazel 5.1.1 than we can simplify
    # this function.
    if os_name == "windows":
        proc_arch = (_get_env_var(rctx, "PROCESSOR_ARCHITECTURE", "", False) or
                     _get_env_var(rctx, "PROCESSOR_ARCHITEW6432", "", False))
        if proc_arch == "ARM64":
            arch = "arm64"
        else:
            arch = "amd64"
    else:
        arch = rctx.execute(["uname", "-m"]).stdout.strip()
    arch_map = {
        "x86_64": "amd64",
        "aarch64": "arm64",
    }
    if arch in arch_map.keys():
        arch = arch_map[arch]
    return "%s_%s" % arch

repo_utils = struct(
    is_darwin_os = _is_darwin_os,
    is_linux_os = _is_linux_os,
    is_windows_os = _is_windows_os,
    get_env_var = _get_env_var,
    os_name = _os_name,
    os_arch_name = _os_arch_name,
)
