"""General utility functions"""

def _propagate_well_known_tags(tags = []):
    """Returns a list of tags filtered from the input set that only contains the ones that are considered "well known"

    These are listed in Bazel's documentation:
    https://docs.bazel.build/versions/main/test-encyclopedia.html#tag-conventions
    https://docs.bazel.build/versions/main/be/common-definitions.html#common-attributes

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

    # cpu:n tags allow setting the requested number of CPUs for a test target.
    # More info at https://docs.bazel.build/versions/main/test-encyclopedia.html#other-resources
    CPU_PREFIX = "cpu:"

    return [
        tag
        for tag in tags
        if tag in WELL_KNOWN_TAGS or tag.startswith(CPU_PREFIX)
    ]

def _to_label(param):
    """Converts a string to a Label. If Label is supplied, the same label is returned.

    Args:
        param: a string representing a label or a Label

    Returns:
        a Label
    """
    param_type = type(param)
    if param_type == "string":
        if param.startswith("@"):
            return Label(param)
        if param.startswith("//"):
            return Label("@" + param)

        # resolve the relative label from the current package
        # if 'param' is in another workspace, then this would return the label relative to that workspace, eg:
        # `Label("@my//foo:bar").relative("@other//baz:bill") == Label("@other//baz:bill")`
        if param.startswith(":"):
            param = param[1:]
        if native.package_name():
            return Label("@//" + native.package_name()).relative(param)
        else:
            return Label("@//:" + param)

    elif param_type == "Label":
        return param
    else:
        msg = "Expected 'string' or 'Label' but got '{}'".format(param_type)
        fail(msg)

def _is_external_label(param):
    """Returns True if the given Label (or stringy version of a label) represents a target outside of the workspace

    Args:
        param: a string or label

    Returns:
        a bool
    """
    return len(_to_label(param).workspace_root) > 0

# Path to the root of the workspace
def _path_to_workspace_root():
    """ Returns the path to the workspace root under bazel

    Returns:
        Path to the workspace root
    """
    return "/".join([".."] * len(native.package_name().split("/")))

# Like glob() but returns directories only
def _glob_directories(include, **kwargs):
    all = native.glob(include, exclude_directories = 0, **kwargs)
    files = native.glob(include, **kwargs)
    directories = [p for p in all if p not in files]
    return directories

def _file_exists(path):
    """Check whether a file exists.

    Useful in macros to set defaults for a configuration file if it is present.
    This can only be called during the loading phase, not from a rule implementation.

    Args:
        path: a label, or a string which is a path relative to this package
    """
    label = _to_label(path)
    file_abs = "%s/%s" % (label.package, label.name)
    file_rel = file_abs[len(native.package_name()) + 1:]
    file_glob = native.glob([file_rel], exclude_directories = 1)
    return len(file_glob) > 0

def _default_timeout(size, timeout):
    """Provide a sane default for *_test timeout attribute.

    The [test-encyclopedia](https://bazel.build/reference/test-encyclopedia) says
    > Tests may return arbitrarily fast regardless of timeout.
    > A test is not penalized for an overgenerous timeout, although a warning may be issued:
    > you should generally set your timeout as tight as you can without incurring any flakiness.

    However Bazel's default for timeout is medium, which is dumb given this guidance.

    It also says:
    > Tests which do not explicitly specify a timeout have one implied based on the test's size as follows
    Therefore if size is specified, we should allow timeout to take its implied default.
    If neither is set, then we can fix Bazel's wrong default here to avoid warnings under
    `--test_verbose_timeout_warnings`.

    This function can be used in a macro which wraps a testing rule.

    Args:
        size: the size attribute of a test target
        timeout: the timeout attribute of a test target

    Returns:
        "short" if neither is set, otherwise timeout
    """

    if size == None and timeout == None:
        return "short"

    return timeout

utils = struct(
    is_external_label = _is_external_label,
    file_exists = _file_exists,
    glob_directories = _glob_directories,
    path_to_workspace_root = _path_to_workspace_root,
    propagate_well_known_tags = _propagate_well_known_tags,
    to_label = _to_label,
    default_timeout = _default_timeout,
)
