"Copy files and directories to an output directory"

load("@bazel_skylib//lib:paths.bzl", skylib_paths = "paths")
load(":paths.bzl", "paths")

_DOC = """Copies files and directories to an output directory.

Files and directories can be arranged as needed in the output directory using
the `root_paths` and `replace_prefixes` attributes.

NB: This rule is not yet implemented for Windows
"""

_copy_to_directory_attr = {
    "srcs": attr.label_list(
        allow_files = True,
        doc = """Files and/or directories to copy into the output directory""",
    ),
    "root_paths": attr.string_list(
        default = [],
        doc = """
List of paths that are roots in the output directory. If a file or directory
being copied is in one of the listed paths or one of its subpaths, the output
directory path is the path relative to the root path instead of the path
relative to the file's workspace.

Forward slashes (`/`) should be used as path separators. Partial matches
on the final path segment of a root path against the corresponding segment
in the full workspace relative path of a file are not matched.

If there are multiple root paths that match, the longest match wins.

Defaults to [package_name()] so that the output directory path of files in the
target's package and and sub-packages are relative to the target's package and
files outside of that retain their full workspace relative paths.
""",
    ),
    "replace_prefixes": attr.string_dict(
        default = {},
        doc = """
Map of paths prefixes to replace in the output directory path when copying files.

If the output directory path for a file or directory starts with or is equal to
a key in the dict then the matching portion of the output directory path is
replaced with the dict value for that key.

Forward slashes (`/`) should be used as path separators. The final path segment
of the key can be a partial match in the corresponding segment of the output
directory path.

If there are multiple keys that match, the longest match wins.
""",
    ),
    "is_windows": attr.bool(mandatory = True),
}

# Hints for Bazel spawn strategy
_execution_requirements = {
    # Copying files is entirely IO-bound and there is no point doing this work
    # remotely. Also, remote-execution does not allow source directory inputs,
    # see
    # https://github.com/bazelbuild/bazel/commit/c64421bc35214f0414e4f4226cc953e8c55fa0d2
    # So we must not attempt to execute remotely in that case.
    "no-remote-exec": "1",
}

def _longest_match(subject, tests, allow_partial = False):
    match = None
    high_score = 0
    for test in tests:
        starts_with_test = test if allow_partial else test + "/"
        if subject == test or subject.startswith(starts_with_test):
            score = len(test)
            if score > high_score:
                match = test
                high_score = score
    return match

def _output_path(ctx, src):
    result = paths.to_workspace_path(ctx, src)

    # strip root paths
    root_path = _longest_match(result, ctx.attr.root_paths)
    if root_path:
        strip_depth = len(root_path.split("/"))
        result = "/".join(result.split("/")[strip_depth:])

    # apply a replacement if one is found
    match = _longest_match(result, ctx.attr.replace_prefixes.keys(), True)
    if match:
        result = ctx.attr.replace_prefixes[match] + result[len(match):]
    return result

def _copy_to_dir_bash(ctx, srcs, dst_dir):
    cmds = [
        "set -o errexit -o nounset -o pipefail",
        "mkdir -p \"%s\"" % dst_dir.path,
    ]
    for src in srcs:
        output_path = _output_path(ctx, src)
        dst_path = skylib_paths.normalize("/".join([dst_dir.path, output_path]))
        cmds.append("""
if [[ ! -e "{src}" ]]; then echo "file '{src}' does not exist"; exit 1; fi
if [[ -f "{src}" ]]; then
    mkdir -p "{dst_dir}"
    cp -f "{src}" "{dst}"
else
    mkdir -p "{dst}"
    cp -rf "{src}"/* "{dst}"
fi
""".format(src = src.path, dst_dir = skylib_paths.dirname(dst_path), dst = dst_path))

    ctx.actions.run_shell(
        inputs = srcs,
        outputs = [dst_dir],
        command = "\n".join(cmds),
        mnemonic = "CopyToDirectory",
        progress_message = "Copying files to directory",
        use_default_shell_env = True,
        execution_requirements = _execution_requirements,
    )

def _copy_to_directory_impl(ctx):
    if not ctx.files.srcs:
        msg = "srcs must not be empty in copy_to_directory %s" % ctx.label
        fail(msg)
    output = ctx.actions.declare_directory(ctx.attr.name)
    if ctx.attr.is_windows:
        # TODO: Windows implementation
        fail("not yet implemented")
    else:
        _copy_to_dir_bash(ctx, ctx.files.srcs, output)
    return [
        DefaultInfo(files = depset([output])),
    ]

copy_to_directory_lib = struct(
    attrs = _copy_to_directory_attr,
    impl = _copy_to_directory_impl,
    provides = [DefaultInfo],
)

# For stardoc to generate documentation for the rule rather than a wrapper macro
copy_to_directory = rule(
    doc = _DOC,
    implementation = copy_to_directory_lib.impl,
    attrs = copy_to_directory_lib.attrs,
    provides = copy_to_directory_lib.provides,
)
