"""Public API for jq"""

load("//lib/private:jq.bzl", _jq_lib = "jq_lib")

_jq_rule = rule(
    attrs = _jq_lib.attrs,
    implementation = _jq_lib.implementation,
    toolchains = ["@aspect_bazel_lib//lib:jq_toolchain_type"],
)

def jq(name, srcs, filter, args = [], out = None):
    """Invoke jq with a filter on a set of json input files.

    For jq documentation, see https://stedolan.github.io/jq/.

    Args:
        name: Name of the rule
        srcs: List of input json files
        filter: mandatory jq filter specification (https://stedolan.github.io/jq/manual/#Basicfilters)
        args: additional args to pass to jq
        out: Name of the output json file; defaults to the rule name plus ".json"
    """
    if not out:
        out = name + ".json"

    _jq_rule(
        name = name,
        srcs = srcs,
        filter = filter,
        args = args,
        out = out,
    )
