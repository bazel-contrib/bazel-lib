"""Utility functions for repository rules"""

def _is_windows_os(rctx):
    """Returns true if the host operating system is Windows"""
    return rctx.os.name.lower().find("windows") != -1

def _is_darwin_os(rctx):
    """Returns true if the host operating system is Darwin"""
    return rctx.os.name.lower().os_name.startswith("mac os")

def _is_linux_os(rctx):
    """Returns true if the host operating system is Linux"""
    return rctx.os.name.lower().startswith("linux")

repo_utils = struct(
    is_windows_os = _is_windows_os,
    is_darwin_os = _is_darwin_os,
    is_linux_os = _is_linux_os,
)
