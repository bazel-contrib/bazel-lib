"""General utility functions"""

def _propagate_well_known_tags(tags = []):
    """Returns a list of tags filtered from the input set that only contains the ones that are considered "well known"

    Args:
        tags: List of tags to filter

    Returns:
        List of tags that only contains the well known set
    """

    WELL_KNOWN_TAGS = [
        "no-sandbox",
        "no-cache",
        "no-remote-cache",
        "no-remote-exec",
        "no-remote",
        "local",
        "requires-network",
        "block-network",
        "requires-fakeroot",
        "exclusive",
        "manual",
        "external",
    ]

    return [tag for tag in tags if tag in WELL_KNOWN_TAGS]

def _is_darwin(rctx):
    """Return true if host is Darwin.

    Args:
        rctx: repository_ctx

    Returns:
        True if host is Darwin, false otherwise
    """
    return rctx.os.name.lower().startswith("mac os")

def _to_label(param):
    """Converts a string to a Label. If Label is supplied, the same label is returned.

    Args:
        param: a string representing a label or a Label

    Returns:
        a Label
    """
    param_type = type(param)
    if param_type == "string":
        if not param.startswith("@") and not param.startswith("//"):
            # resolve the relative label from the current package
            # if 'param' is in another workspace, then this would return the label relative to that workspace, eg:
            # Label("@my//foo:bar").relative("@other//baz:bill") == Label("@other//baz:bill")
            if param.startswith(":"):
                param = param[1:]
            if native.package_name():
                return Label("//" + native.package_name()).relative(param)
            else:
                return Label("//:" + param)
        return Label(param)
    elif param_type == "Label":
        return param
    else:
        fail("Expected 'string' or 'Label' but got '%s'" % param_type)

def _is_external_label(param):
    """Returns True if the given Label (or stringy version of a label) represents a target outside of the workspace

    Args:
        param: a string or label

    Returns:
        a bool
    """
    return len(_to_label(param).workspace_root) > 0

# Path to the root of the monorepo
def _path_to_root():
    """ Retuns the path to the monorepo root under bazel

    Returns:
        Path to the monorepo root
    """
    return "/".join([".."] * len(native.package_name().split("/")))

# Like glob() but returns directories only
def _glob_directories(include, **kwargs):
    all = native.glob(include, exclude_directories = 0, **kwargs)
    files = native.glob(include, **kwargs)
    directories = [p for p in all if p not in files]
    return directories

utils = struct(
    is_external_label = _is_external_label,
    glob_directories = _glob_directories,
    path_to_root = _path_to_root,
    propagate_well_known_tags = _propagate_well_known_tags,
    is_darwin = _is_darwin,
    to_label = _to_label,
)
