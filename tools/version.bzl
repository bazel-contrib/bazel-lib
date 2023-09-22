"version information. replaced with stamped info with each release"

_VERSION_PRIVATE = "$Format:%(describe:tags=true)$"

VERSION = "0.0.0" if _VERSION_PRIVATE.startswith("$Format") else _VERSION_PRIVATE.replace("v", "", 1)
