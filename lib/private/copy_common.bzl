"Helpers for copy rules"

CopyOptionsInfo = provider("Options for running copy actions", fields = ["execution_requirements"])

def _copy_options_impl(ctx):
    return CopyOptionsInfo(
        execution_requirements = COPY_EXECUTION_REQUIREMENTS_LOCAL if ctx.attr.copy_use_local_execution else {},
    )

copy_options = rule(implementation = _copy_options_impl, attrs = {"copy_use_local_execution": attr.bool()})

# Helper function to be used when creating an action
def execution_requirements_for_copy(ctx):
    if hasattr(ctx.attr, "_options") and CopyOptionsInfo in ctx.attr._options:
        return ctx.attr._options[CopyOptionsInfo].execution_requirements

    # If the rule ctx doesn't expose the CopyOptions, the default is to run locally
    return COPY_EXECUTION_REQUIREMENTS_LOCAL

# When applied to execution_requirements of an action, these prevent the action from being sandboxed
# for improved performance.
COPY_EXECUTION_REQUIREMENTS_LOCAL = {
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
