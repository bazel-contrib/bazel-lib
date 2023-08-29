"Helpers for copy rules"

# Hints for Bazel spawn strategy, copied from
# https://github.com/bazelbuild/bazel-skylib/blob/0171c69e5cc691e2d0cd9f3f3e4c3bf112370ca2/rules/private/copy_common.bzl
# See extensive comments there for reasoning on this execution-requirements selection.
COPY_EXECUTION_REQUIREMENTS = {
    "no-remote": "1",
    "no-cache": "1",
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
