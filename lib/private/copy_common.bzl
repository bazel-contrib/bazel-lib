"Helpers for copy rules"

load(
    "@bazel_lib//lib/private:copy_common.bzl",
    _COPY_EXECUTION_REQUIREMENTS = "COPY_EXECUTION_REQUIREMENTS",
)

# Hints for Bazel spawn strategy
COPY_EXECUTION_REQUIREMENTS = _COPY_EXECUTION_REQUIREMENTS
