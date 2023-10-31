"Helpers for copy rules"

# Hints for Bazel spawn strategy
COPY_EXECUTION_REQUIREMENTS = {
    # ----------------+-----------------------------------------------------------------------------
    # no-sandbox      | Results in the action or test never being sandboxed; it can still be cached
    #                 | or run remotely.
    # ----------------+-----------------------------------------------------------------------------
    # See https://bazel.google.cn/reference/be/common-definitions?hl=en&authuser=0#common-attributes
    #
    # Sandboxing for this action is wasteful since there is a 1:1 mapping of input file/directory to
    # output file/directory so little room for non-hermetic inputs to sneak in to the execution.
    "no-sandbox": "1",
}

def progress_path(f):
    """
    Convert a file to an appropriate string to display in an action progress message.

    Args:
        f: a file to show as a path in a progress message

    Returns:
        The path formatted for use in a progress message
    """
    return f.short_path.removeprefix("../")
