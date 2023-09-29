"copy_to_directory implementation"

load("@bazel_skylib//lib:paths.bzl", skylib_paths = "paths")
load(":copy_common.bzl", _COPY_EXECUTION_REQUIREMENTS = "COPY_EXECUTION_REQUIREMENTS", _progress_path = "progress_path")
load(":directory_path.bzl", "DirectoryPathInfo")
load(":glob_match.bzl", "glob_match", "is_glob")
load(":paths.bzl", "paths")
load(":platform_utils.bzl", _platform_utils = "platform_utils")

_filter_transforms_order_docstring = """Filters and transformations are applied in the following order:

1. `include_external_repositories`

2. `include_srcs_packages`

3. `exclude_srcs_packages`

4. `root_paths`

5. `include_srcs_patterns`

6. `exclude_srcs_patterns`

7. `replace_prefixes`

For more information each filters / transformations applied, see
the documentation for the specific filter / transformation attribute.
"""

_glob_support_docstring = """Glob patterns are supported. Standard wildcards (globbing patterns) plus the `**` doublestar (aka. super-asterisk)
are supported with the underlying globbing library, https://github.com/bmatcuk/doublestar. This is the same
globbing library used by [gazelle](https://github.com/bazelbuild/bazel-gazelle). See https://github.com/bmatcuk/doublestar#patterns
for more information on supported globbing patterns.
"""

_copy_to_directory_doc = """Copies files and directories to an output directory.

Files and directories can be arranged as needed in the output directory using
the `root_paths`, `include_srcs_patterns`, `exclude_srcs_patterns` and `replace_prefixes` attributes.

{filters_transform_order_docstring}

{glob_support_docstring}
""".format(
    filters_transform_order_docstring = _filter_transforms_order_docstring,
    glob_support_docstring = _glob_support_docstring,
)

_copy_to_directory_attr_doc = {
    # srcs
    "srcs": """Files and/or directories or targets that provide `DirectoryPathInfo` to copy into the output directory.""",
    # out
    "out": """Path of the output directory, relative to this package.

If not set, the name of the target is used.
""",
    # root_paths
    "root_paths": """List of paths (with glob support) that are roots in the output directory.

If any parent directory of a file being copied matches one of the root paths
patterns specified, the output directory path will be the path relative to the root path
instead of the path relative to the file's workspace. If there are multiple
root paths that match, the longest match wins.

Matching is done on the parent directory of the output file path so a trailing '**' glob patterm
will match only up to the last path segment of the dirname and will not include the basename.
Only complete path segments are matched. Partial matches on the last segment of the root path
are ignored.

Forward slashes (`/`) should be used as path separators.

A `"."` value expands to the target's package path (`ctx.label.package`).

Defaults to `["."]` which results in the output directory path of files in the
target's package and and sub-packages are relative to the target's package and
files outside of that retain their full workspace relative paths.

Globs are supported (see rule docstring above).
""",
    # include_external_repositories
    "include_external_repositories": """List of external repository names (with glob support) to include in the output directory.

Files from external repositories are only copied into the output directory if
the external repository they come from matches one of the external repository patterns
specified.

When copied from an external repository, the file path in the output directory
defaults to the file's path within the external repository. The external repository
name is _not_ included in that path.

For example, the following copies `@external_repo//path/to:file` to
`path/to/file` within the output directory.

```
copy_to_directory(
    name = "dir",
    include_external_repositories = ["external_*"],
    srcs = ["@external_repo//path/to:file"],
)
```

Files that come from matching external are subject to subsequent filters and
transformations to determine if they are copied and what their path in the output
directory will be. The external repository name of the file from an external
repository is not included in the output directory path and is considered in subsequent
filters and transformations.

Globs are supported (see rule docstring above).
""",
    # include_srcs_packages
    "include_srcs_packages": """List of Bazel packages (with glob support) to include in output directory.

Files in srcs are only copied to the output directory if
the Bazel package of the file matches one of the patterns specified.

Forward slashes (`/`) should be used as path separators. A first character of `"."`
will be replaced by the target's package path.

Defaults to `["**"]` which includes sources from all packages.

Files that have matching Bazel packages are subject to subsequent filters and
transformations to determine if they are copied and what their path in the output
directory will be.

Globs are supported (see rule docstring above).
""",
    # exclude_srcs_packages
    "exclude_srcs_packages": """List of Bazel packages (with glob support) to exclude from output directory.

Files in srcs are not copied to the output directory if
the Bazel package of the file matches one of the patterns specified.

Forward slashes (`/`) should be used as path separators. A first character of `"."`
will be replaced by the target's package path.

Files that have do not have matching Bazel packages are subject to subsequent
filters and transformations to determine if they are copied and what their path in the output
directory will be.

Globs are supported (see rule docstring above).
""",
    # include_srcs_patterns
    "include_srcs_patterns": """List of paths (with glob support) to include in output directory.

Files in srcs are only copied to the output directory if their output
directory path, after applying `root_paths`, matches one of the patterns specified.

Forward slashes (`/`) should be used as path separators.

Defaults to `["**"]` which includes all sources.

Files that have matching output directory paths are subject to subsequent
filters and transformations to determine if they are copied and what their path in the output
directory will be.

Globs are supported (see rule docstring above).
""",
    # exclude_srcs_patterns
    "exclude_srcs_patterns": """List of paths (with glob support) to exclude from output directory.

Files in srcs are not copied to the output directory if their output
directory path, after applying `root_paths`, matches one of the patterns specified.

Forward slashes (`/`) should be used as path separators.

Files that do not have matching output directory paths are subject to subsequent
filters and transformations to determine if they are copied and what their path in the output
directory will be.

Globs are supported (see rule docstring above).
""",
    # exclude_prefixes
    "exclude_prefixes": """List of path prefixes (with glob support) to exclude from output directory.

DEPRECATED: use `exclude_srcs_patterns` instead

Files in srcs are not copied to the output directory if their output
directory path, after applying `root_paths`, starts with or fully matches one of the
patterns specified.

Forward slashes (`/`) should be used as path separators.

Files that do not have matching output directory paths are subject to subsequent
filters and transformations to determine if they are copied and what their path in the output
directory will be.

Globs are supported (see rule docstring above).
""",
    # replace_prefixes
    "replace_prefixes": """Map of paths prefixes (with glob support) to replace in the output directory path when copying files.

If the output directory path for a file starts with or fully matches a
a key in the dict then the matching portion of the output directory path is
replaced with the dict value for that key. The final path segment
matched can be a partial match of that segment and only the matching portion will
be replaced. If there are multiple keys that match, the longest match wins.

Forward slashes (`/`) should be used as path separators.

Replace prefix transformation are the final step in the list of filters and transformations.
The final output path of a file being copied into the output directory
is determined at this step.

Globs are supported (see rule docstring above).
""",
    # allow_overwrites
    "allow_overwrites": """If True, allow files to be overwritten if the same output file is copied to twice.

The order of srcs matters as the last copy of a particular file will win when overwriting.
Performance of copy_to_directory will be slightly degraded when allow_overwrites is True
since copies cannot be parallelized out as they are calculated. Instead all copy paths
must be calculated before any copies can be started.
""",
    # hardlink
    "hardlink": """Controls when to use hardlinks to files instead of making copies.

Creating hardlinks is much faster than making copies of files with the caveat that
hardlinks share file permissions with their source.

Since Bazel removes write permissions on files in the output tree after an action completes,
hardlinks to source files are not recommended since write permissions will be inadvertently
removed from sources files.

- `auto`: hardlinks are used for generated files already in the output tree
- `off`: all files are copied
- `on`: hardlinks are used for all files (not recommended)
    """,
    # verbose
    "verbose": """If true, prints out verbose logs to stdout""",
}

_copy_to_directory_attr = {
    "srcs": attr.label_list(
        allow_files = True,
        doc = _copy_to_directory_attr_doc["srcs"],
    ),
    # Cannot declare out as an output here, because there's no API for declaring
    # TreeArtifact outputs.
    "out": attr.string(
        doc = _copy_to_directory_attr_doc["out"],
    ),
    "root_paths": attr.string_list(
        default = ["."],
        doc = _copy_to_directory_attr_doc["root_paths"],
    ),
    "include_external_repositories": attr.string_list(
        doc = _copy_to_directory_attr_doc["include_external_repositories"],
    ),
    "include_srcs_packages": attr.string_list(
        default = ["**"],
        doc = _copy_to_directory_attr_doc["include_srcs_packages"],
    ),
    "exclude_srcs_packages": attr.string_list(
        doc = _copy_to_directory_attr_doc["exclude_srcs_packages"],
    ),
    "include_srcs_patterns": attr.string_list(
        default = ["**"],
        doc = _copy_to_directory_attr_doc["include_srcs_patterns"],
    ),
    "exclude_srcs_patterns": attr.string_list(
        doc = _copy_to_directory_attr_doc["exclude_srcs_patterns"],
    ),
    "exclude_prefixes": attr.string_list(
        doc = _copy_to_directory_attr_doc["exclude_prefixes"],
    ),
    "replace_prefixes": attr.string_dict(
        doc = _copy_to_directory_attr_doc["replace_prefixes"],
    ),
    "allow_overwrites": attr.bool(
        doc = _copy_to_directory_attr_doc["allow_overwrites"],
    ),
    "hardlink": attr.string(
        values = ["auto", "off", "on"],
        default = "auto",
        doc = _copy_to_directory_attr_doc["hardlink"],
    ),
    "verbose": attr.bool(
        doc = _copy_to_directory_attr_doc["verbose"],
    ),
    # use '_tool' attribute for development only; do not commit with this attribute active since it
    # propagates a dependency on rules_go which would be breaking for users
    # "_tool": attr.label(
    #     executable = True,
    #     cfg = "exec",
    #     default = "//tools/copy_to_directory",
    # ),
}

def _any_globs_match(exprs, path):
    # Exit quick in the common case of having a "**".
    if "**" in exprs:
        return True

    # Special case: support non-standard empty glob expr.
    # Only an empty expression matches an empty path.
    if path == "":
        return "" in exprs

    for expr in exprs:
        if expr != "" and glob_match(expr, path):
            return True
    return None

def _longest_glob_match(expr, path):
    if not is_glob(expr):
        return expr if path.startswith(expr) else None

    for i in range(len(path)):
        maybe_match = path[:-i] if i > 0 else path
        if glob_match(expr, maybe_match):
            # Some subpath matches
            return maybe_match
    return None

def _longest_globs_match(exprs, path):
    matching_expr = None
    longest_match = None
    longest_match_len = 0
    for expr in exprs:
        match = _longest_glob_match(expr, path)
        if match:
            match_len = len(match)
            if match_len > longest_match_len:
                matching_expr = expr
                longest_match = match
                longest_match_len = match_len
    return matching_expr, longest_match

# src can either be a File or a target with a DirectoryPathInfo
def _copy_paths(
        src,
        root_paths,
        include_external_repositories,
        include_srcs_packages,
        exclude_srcs_packages,
        include_srcs_patterns,
        exclude_srcs_patterns,
        replace_prefixes):
    output_path_is_directory = False
    if type(src) == "File":
        src_file = src
        src_path = src_file.path
        output_path = paths.to_workspace_path(src_file)
        output_path_is_directory = src_file.is_directory
    elif DirectoryPathInfo in src:
        src_file = src[DirectoryPathInfo].directory
        src_path = "/".join([src_file.path, src[DirectoryPathInfo].path])
        output_path = "/".join([paths.to_workspace_path(src_file), src[DirectoryPathInfo].path])
    else:
        fail("Unsupported type")

    if not src_file.owner:
        msg = "Expected an owner target label for file {} but found none".format(src_file)
        fail(msg)

    if src_file.owner.package == None:
        msg = "Expected owner target label for file {} to have a package name but found None".format(src_file)
        fail(msg)

    if not include_srcs_packages:
        fail("An empty 'include_srcs_packages' list will exclude all srcs and result in an empty directory")

    if "**" in exclude_srcs_packages:
        fail("A '**' glob pattern in 'exclude_srcs_packages' will exclude all srcs and result in an empty directory")

    if not include_srcs_patterns:
        fail("An empty 'include_srcs_patterns' list will exclude all srcs and result in an empty directory")

    if "**" in exclude_srcs_patterns:
        fail("A '**' glob pattern in 'exclude_srcs_patterns' will exclude all srcs and result in an empty directory")

    # Apply filters and transformations in the following order:
    #
    # - `include_external_repositories`
    # - `include_srcs_packages`
    # - `exclude_srcs_packages`
    # - `root_paths`
    # - `include_srcs_patterns`
    # - `exclude_srcs_patterns`
    # - `replace_prefixes`
    #
    # If you change this order please update the docstrings to reflect the changes.

    # apply include_external_repositories if the file is from an external repository
    if src_file.owner.workspace_name:
        if not _any_globs_match(include_external_repositories, src_file.owner.workspace_name):
            # file is excluded as its external repository does not match any patterns in include_external_repositories
            return None, None, None

    # apply include_srcs_packages
    if not _any_globs_match(include_srcs_packages, src_file.owner.package):
        # file is excluded as it does not match any specified include_srcs_packages
        return None, None, None

    # apply exclude_srcs_packages
    if _any_globs_match(exclude_srcs_packages, src_file.owner.package):
        # file is excluded due to a matching exclude_srcs_packages
        return None, None, None

    # apply root_paths
    if root_paths:
        globstar_suffix = False
        for root_path in root_paths:
            if root_path.endswith("**"):
                globstar_suffix = True
                break
        if not output_path_is_directory and globstar_suffix:
            # match against the output_path dirname and not the full output path
            # so we don't match against the filename on an ending '**' glob pattern
            output_root = skylib_paths.dirname(output_path)
        else:
            output_root = output_path
        _, longest_match = _longest_globs_match(root_paths, output_root)
        if longest_match:
            if longest_match.endswith("/"):
                longest_match = longest_match[:-1]
            if len(longest_match) == len(output_root) or output_root[len(longest_match)] == "/":
                output_path = output_path[len(longest_match) + 1:]

    # apply include_srcs_patterns if "**" is not included in the list
    if not _any_globs_match(include_srcs_patterns, output_path):
        # file is excluded as it does not match any specified include_srcs_patterns
        return None, None, None

    # apply exclude_srcs_patterns
    if _any_globs_match(exclude_srcs_patterns, output_path):
        # file is excluded due to a matching exclude_srcs_patterns
        return None, None, None

    # apply replace_prefixes
    if replace_prefixes:
        for replace_prefix in replace_prefixes.keys():
            if replace_prefix.endswith("**"):
                msg = "replace_prefix '{}' must not end with '**' glob expression".format(replace_prefix)
                fail(msg)
        matching_expr, longest_match = _longest_globs_match(replace_prefixes.keys(), output_path)
        if longest_match:
            # replace the longest matching prefix in the output path
            output_path = replace_prefixes[matching_expr] + output_path[len(longest_match):]

    return skylib_paths.normalize(src_path), skylib_paths.normalize(output_path), src_file

def _merge_into_copy_path(copy_paths, src_path, dst_path, src_file):
    for i, s in enumerate(copy_paths):
        _, maybe_dst_path, maybe_src_file = s
        if dst_path == maybe_dst_path:
            if src_file == maybe_src_file:
                return True
            if src_file.short_path == maybe_src_file.short_path:
                if maybe_src_file.is_source and not src_file.is_source:
                    # If the files are the at the same path but one in the source tree and one in
                    # the output tree, always copy the output tree file. This is also the default
                    # Bazel behavior for layout out runfiles if there are files that have the same
                    # path in the source tree and the output tree. This can happen, for example, if
                    # the source file and a generated file that is a copy to the source file are
                    # both added to the package which can happen, for example, through 'additional_files'
                    # in 'copy_to_directory_action'.
                    copy_paths[i] = (src_path, dst_path, src_file)
                return True
    return False

def _copy_to_dir_bash(ctx, copy_paths, dst_dir, allow_overwrites):
    cmds = [
        "set -o errexit -o nounset -o pipefail",
        "OUT_CAPTURE=$(mktemp)",
        """_exit() {
    EXIT_CODE=$?;
    if [ "$EXIT_CODE" != 0 ]; then
        cat "$OUT_CAPTURE"
    fi
    exit $EXIT_CODE
}""",
        "trap _exit EXIT",
        "mkdir -p \"%s\"" % dst_dir.path,
    ]

    inputs = []

    for src_path, dst_path, src_file in copy_paths:
        inputs.append(src_file)

        maybe_force = "-f " if allow_overwrites else "-n "
        maybe_chmod_file = """if [ -e "{dst}" ]; then
    chmod a+w "{dst}"
fi
""" if allow_overwrites else ""
        maybe_chmod_dir = """if [ -e "{dst}" ]; then
    chmod -R a+w "{dst}"
fi
""" if allow_overwrites else ""

        cmds.append("""
if [[ ! -e "{src}" ]]; then echo "file '{src}' does not exist"; exit 1; fi
if [[ -f "{src}" ]]; then
    mkdir -p "{dst_dir}"
    {maybe_chmod_file}cp -v {maybe_force}"{src}" "{dst}" >> "$OUT_CAPTURE" 2>>"$OUT_CAPTURE"
else
    if [[ -d "{dst}" ]]; then
        # When running outside the sandbox, then an earlier copy will create the dst folder
        # with nested read-only folders, so our copy operation will fail to write there.
        # Make sure the output folders are writeable.
        find "{dst}" -type d -print0 | xargs -0 chmod a+w
    fi
    mkdir -p "{dst}"
    {maybe_chmod_dir}cp -v -R {maybe_force}"{src}/." "{dst}" >> "$OUT_CAPTURE" 2>>"$OUT_CAPTURE"
fi
""".format(
            src = src_path,
            dst_dir = skylib_paths.dirname(dst_path),
            dst = dst_path,
            maybe_force = maybe_force,
            maybe_chmod_file = maybe_chmod_file,
            maybe_chmod_dir = maybe_chmod_dir,
        ))

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [dst_dir],
        command = "\n".join(cmds),
        mnemonic = "CopyToDirectory",
        progress_message = "Copying files to directory %s" % _progress_path(dst_dir),
        use_default_shell_env = True,
        execution_requirements = _COPY_EXECUTION_REQUIREMENTS,
    )

def _copy_to_dir_cmd(ctx, copy_paths, dst_dir):
    # Most Windows binaries built with MSVC use a certain argument quoting
    # scheme. Bazel uses that scheme too to quote arguments. However,
    # cmd.exe uses different semantics, so Bazel's quoting is wrong here.
    # To fix that we write the command to a .bat file so no command line
    # quoting or escaping is required.
    # Based on skylib copy_file:
    # https://github.com/bazelbuild/bazel-skylib/blob/main/rules/private/copy_file_private.bzl#L28.
    bat = ctx.actions.declare_file(ctx.label.name + "-cmd.bat")

    # NB: mkdir will create all subdirectories; it will exit 1
    # print an error to stderr if the directory already exists so
    # we supress both its stdout & stderr output
    cmds = ["""
@rem @generated by @aspect_bazel_lib//lib/private:copy_to_directory.bzl
@echo off
mkdir "%s" >NUL 2>NUL
""" % dst_dir.path.replace("/", "\\")]

    inputs = []

    for src_path, dst_path, src_file in copy_paths:
        inputs.append(src_file)

        # copy & xcopy flags are documented at
        # https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/copy
        # https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy
        cmds.append("""
if not exist "{src}" (
    echo file "{src}" does not exist
    exit /b 1
)
if exist "{src}\\*" (
    mkdir "{dst}" >NUL 2>NUL
    robocopy "{src}" "{dst}" /E >NUL
) else (
    mkdir "{dst_dir}" >NUL 2>NUL
    copy /Y "{src}" "{dst}" >NUL
)
""".format(
            src = src_path.replace("/", "\\"),
            dst_dir = skylib_paths.dirname(dst_path).replace("/", "\\"),
            dst = dst_path.replace("/", "\\"),
        ))

    # robocopy return non-zero exit codes on success so we must exit 0 when we are done
    cmds.append("exit 0")

    ctx.actions.write(
        output = bat,
        # Do not use lib/shell.bzl's shell.quote() method, because that uses
        # Bash quoting syntax, which is different from cmd.exe's syntax.
        content = "\n".join(cmds),
        is_executable = True,
    )

    ctx.actions.run(
        inputs = inputs,
        tools = [bat],
        outputs = [dst_dir],
        executable = "cmd.exe",
        arguments = ["/C", bat.path.replace("/", "\\")],
        mnemonic = "CopyToDirectory",
        progress_message = "Copying files to directory %s" % _progress_path(dst_dir),
        use_default_shell_env = True,
        execution_requirements = _COPY_EXECUTION_REQUIREMENTS,
    )

def _copy_to_directory_impl(ctx):
    copy_to_directory_bin = ctx.toolchains["@aspect_bazel_lib//lib:copy_to_directory_toolchain_type"].copy_to_directory_info.bin

    dst = ctx.actions.declare_directory(ctx.attr.out if ctx.attr.out else ctx.attr.name)

    copy_to_directory_bin_action(
        ctx,
        name = ctx.attr.name,
        dst = dst,
        # copy_to_directory_bin = ctx.executable._tool,  # use for development
        copy_to_directory_bin = copy_to_directory_bin,
        files = ctx.files.srcs,
        targets = [t for t in ctx.attr.srcs if DirectoryPathInfo in t],
        root_paths = ctx.attr.root_paths,
        include_external_repositories = ctx.attr.include_external_repositories,
        include_srcs_packages = ctx.attr.include_srcs_packages,
        exclude_srcs_packages = ctx.attr.exclude_srcs_packages,
        include_srcs_patterns = ctx.attr.include_srcs_patterns,
        exclude_srcs_patterns = ctx.attr.exclude_srcs_patterns,
        exclude_prefixes = ctx.attr.exclude_prefixes,
        replace_prefixes = ctx.attr.replace_prefixes,
        allow_overwrites = ctx.attr.allow_overwrites,
        hardlink = ctx.attr.hardlink,
        verbose = ctx.attr.verbose,
    )

    return [
        DefaultInfo(
            files = depset([dst]),
            runfiles = ctx.runfiles([dst]),
        ),
    ]

def _expand_src_packages_patterns(patterns, package):
    result = []
    for pattern in patterns:
        if pattern.startswith("."):
            if not package and pattern.startswith("./"):
                # special case in the root package
                result.append(pattern[2:])
            else:
                result.append(package + pattern[1:])
        else:
            result.append(pattern)
    return result

def copy_to_directory_bin_action(
        ctx,
        name,
        dst,
        copy_to_directory_bin,
        files = [],
        targets = [],
        root_paths = ["."],
        include_external_repositories = [],
        include_srcs_packages = ["**"],
        exclude_srcs_packages = [],
        include_srcs_patterns = ["**"],
        exclude_srcs_patterns = [],
        exclude_prefixes = [],
        replace_prefixes = {},
        allow_overwrites = False,
        hardlink = "auto",
        verbose = False):
    """Factory function to copy files to a directory using a tool binary.

    The tool binary will typically be the `@aspect_bazel_lib//tools/copy_to_directory` `go_binary`
    either built from source or provided by a toolchain.

    This helper is used by copy_to_directory. It is exposed as a public API so it can be used within
    other rule implementations where additional_files can also be passed in.

    Args:
        ctx: The rule context.

        name: Name of target creating this action used for config file generation.

        dst: The directory to copy to. Must be a TreeArtifact.

        copy_to_directory_bin: Copy to directory tool binary.

        files: List of files to copy into the output directory.

        targets: List of targets that provide `DirectoryPathInfo` to copy into the output directory.

        root_paths: List of paths that are roots in the output directory.

            See copy_to_directory rule documentation for more details.

        include_external_repositories: List of external repository names to include in the output directory.

            See copy_to_directory rule documentation for more details.

        include_srcs_packages: List of Bazel packages to include in output directory.

            See copy_to_directory rule documentation for more details.

        exclude_srcs_packages: List of Bazel packages (with glob support) to exclude from output directory.

            See copy_to_directory rule documentation for more details.

        include_srcs_patterns: List of paths (with glob support) to include in output directory.

            See copy_to_directory rule documentation for more details.

        exclude_srcs_patterns: List of paths (with glob support) to exclude from output directory.

            See copy_to_directory rule documentation for more details.

        exclude_prefixes: List of path prefixes to exclude from output directory.

            See copy_to_directory rule documentation for more details.

        replace_prefixes: Map of paths prefixes to replace in the output directory path when copying files.

            See copy_to_directory rule documentation for more details.

        allow_overwrites: If True, allow files to be overwritten if the same output file is copied to twice.

            See copy_to_directory rule documentation for more details.

        hardlink: Controls when to use hardlinks to files instead of making copies.

            See copy_to_directory rule documentation for more details.

        verbose: If true, prints out verbose logs to stdout
    """

    # Replace "." in root_paths with the package name of the target
    root_paths = [p if p != "." else ctx.label.package for p in root_paths]

    # Replace a leading "." with the package name of the target in include_srcs_packages & exclude_srcs_packages
    include_srcs_packages = _expand_src_packages_patterns(include_srcs_packages, ctx.label.package)
    exclude_srcs_packages = _expand_src_packages_patterns(exclude_srcs_packages, ctx.label.package)

    # Convert and append exclude_prefixes to exclude_srcs_patterns
    # TODO(2.0): remove exclude_prefixes this block and in a future breaking release
    for exclude_prefix in exclude_prefixes:
        if exclude_prefix.endswith("**"):
            exclude_srcs_patterns.append(exclude_prefix)
        elif exclude_prefix.endswith("*"):
            exclude_srcs_patterns.append(exclude_prefix + "/**")
            exclude_srcs_patterns.append(exclude_prefix)
        elif exclude_prefix.endswith("/"):
            exclude_srcs_patterns.append(exclude_prefix + "**")
        else:
            exclude_srcs_patterns.append(exclude_prefix + "*/**")
            exclude_srcs_patterns.append(exclude_prefix + "*")

    if not include_srcs_packages:
        fail("An empty 'include_srcs_packages' list will exclude all srcs and result in an empty directory")

    if "**" in exclude_srcs_packages:
        fail("A '**' glob pattern in 'exclude_srcs_packages' will exclude all srcs and result in an empty directory")

    if not include_srcs_patterns:
        fail("An empty 'include_srcs_patterns' list will exclude all srcs and result in an empty directory")

    if "**" in exclude_srcs_patterns:
        fail("A '**' glob pattern in 'exclude_srcs_patterns' will exclude all srcs and result in an empty directory")

    for replace_prefix in replace_prefixes.keys():
        if replace_prefix.endswith("**"):
            msg = "replace_prefix '{}' must not end with '**' glob expression".format(replace_prefix)
            fail(msg)

    files_and_targets = []
    for f in files:
        files_and_targets.append(struct(
            file = f,
            path = f.path,
            root_path = f.root.path,
            short_path = f.short_path,
            workspace_path = paths.to_workspace_path(f),
        ))
    for t in targets:
        if not DirectoryPathInfo in t:
            continue
        files_and_targets.append(struct(
            file = t[DirectoryPathInfo].directory,
            path = "/".join([t[DirectoryPathInfo].directory.path, t[DirectoryPathInfo].path]),
            root_path = t[DirectoryPathInfo].directory.root.path,
            short_path = "/".join([t[DirectoryPathInfo].directory.short_path, t[DirectoryPathInfo].path]),
            workspace_path = "/".join([paths.to_workspace_path(t[DirectoryPathInfo].directory), t[DirectoryPathInfo].path]),
        ))

    file_infos = []
    file_inputs = []
    for f in files_and_targets:
        if not f.file.owner:
            msg = "Expected an owner target label for file {} but found none".format(f)
            fail(msg)

        if f.file.owner.package == None:
            msg = "Expected owner target label for file {} to have a package name but found None".format(f)
            fail(msg)

        if f.file.owner.workspace_name == None:
            msg = "Expected owner target label for file {} to have a workspace name but found None".format(f)
            fail(msg)

        hardlink_file = False
        if hardlink == "on":
            hardlink_file = True
        elif hardlink == "auto":
            hardlink_file = not f.file.is_source

        file_infos.append({
            "package": f.file.owner.package,
            "path": f.path,
            "root_path": f.root_path,
            "short_path": f.short_path,
            "workspace": f.file.owner.workspace_name,
            "workspace_path": f.workspace_path,
            "hardlink": hardlink_file,
        })
        file_inputs.append(f.file)

    if not file_inputs:
        fail("No files to copy")

    config = {
        "allow_overwrites": allow_overwrites,
        "dst": dst.path,
        "exclude_srcs_packages": exclude_srcs_packages,
        "exclude_srcs_patterns": exclude_srcs_patterns,
        "files": file_infos,
        "include_external_repositories": include_external_repositories,
        "include_srcs_packages": include_srcs_packages,
        "include_srcs_patterns": include_srcs_patterns,
        "replace_prefixes": replace_prefixes,
        "root_paths": root_paths,
        "verbose": verbose,
    }

    config_file = ctx.actions.declare_file("{}_config.json".format(name))
    ctx.actions.write(
        output = config_file,
        content = json.encode_indent(config),
    )

    ctx.actions.run(
        inputs = file_inputs + [config_file],
        outputs = [dst],
        executable = copy_to_directory_bin,
        arguments = [config_file.path],
        mnemonic = "CopyToDirectory",
        progress_message = "Copying files to directory %s" % _progress_path(dst),
        execution_requirements = _COPY_EXECUTION_REQUIREMENTS,
    )

# TODO(2.0): remove the legacy copy_to_directory_action helper
def copy_to_directory_action(
        ctx,
        srcs,
        dst,
        additional_files = [],
        root_paths = ["."],
        include_external_repositories = [],
        include_srcs_packages = ["**"],
        exclude_srcs_packages = [],
        include_srcs_patterns = ["**"],
        exclude_srcs_patterns = [],
        exclude_prefixes = [],
        replace_prefixes = {},
        allow_overwrites = False,
        is_windows = None):
    """Legacy factory function to copy files to a directory.

    This helper calculates copy paths in Starlark during analysis and performs the copies in a
    bash/bat script. For improved analysis and runtime performance, it is recommended the switch
    to `copy_to_directory_bin_action` which calculates copy paths and performs copies with a tool
    binary, typically the `@aspect_bazel_lib//tools/copy_to_directory` `go_binary` either built
    from source or provided by a toolchain.

    This helper is used by copy_to_directory. It is exposed as a public API so it can be used within
    other rule implementations where additional_files can also be passed in.

    Args:
        ctx: The rule context.

        srcs: Files and/or directories or targets that provide `DirectoryPathInfo` to copy into the output directory.

        dst: The directory to copy to. Must be a TreeArtifact.

        additional_files: List or depset of additional files to copy that are not in the `DefaultInfo` or `DirectoryPathInfo` of srcs

        root_paths: List of paths that are roots in the output directory.

            See copy_to_directory rule documentation for more details.

        include_external_repositories: List of external repository names to include in the output directory.

            See copy_to_directory rule documentation for more details.

        include_srcs_packages: List of Bazel packages to include in output directory.

            See copy_to_directory rule documentation for more details.

        exclude_srcs_packages: List of Bazel packages (with glob support) to exclude from output directory.

            See copy_to_directory rule documentation for more details.

        include_srcs_patterns: List of paths (with glob support) to include in output directory.

            See copy_to_directory rule documentation for more details.

        exclude_srcs_patterns: List of paths (with glob support) to exclude from output directory.

            See copy_to_directory rule documentation for more details.

        exclude_prefixes: List of path prefixes to exclude from output directory.

            See copy_to_directory rule documentation for more details.

        replace_prefixes: Map of paths prefixes to replace in the output directory path when copying files.

            See copy_to_directory rule documentation for more details.

        allow_overwrites: If True, allow files to be overwritten if the same output file is copied to twice.

            See copy_to_directory rule documentation for more details.

        is_windows: Deprecated and unused
    """

    # TODO(2.0): remove deprecated & unused is_windows parameter
    if not srcs:
        fail("srcs must not be empty")

    # Replace "." in root_paths with the package name of the target
    root_paths = [p if p != "." else ctx.label.package for p in root_paths]

    # Replace a leading "." with the package name of the target in include_srcs_packages & exclude_srcs_packages
    include_srcs_packages = _expand_src_packages_patterns(include_srcs_packages, ctx.label.package)
    exclude_srcs_packages = _expand_src_packages_patterns(exclude_srcs_packages, ctx.label.package)

    # Convert and append exclude_prefixes to exclude_srcs_patterns
    # TODO(2.0): remove exclude_prefixes this block and in a future breaking release
    for exclude_prefix in exclude_prefixes:
        if exclude_prefix.endswith("**"):
            exclude_srcs_patterns.append(exclude_prefix)
        elif exclude_prefix.endswith("*"):
            exclude_srcs_patterns.append(exclude_prefix + "/**")
            exclude_srcs_patterns.append(exclude_prefix)
        elif exclude_prefix.endswith("/"):
            exclude_srcs_patterns.append(exclude_prefix + "**")
        else:
            exclude_srcs_patterns.append(exclude_prefix + "*/**")
            exclude_srcs_patterns.append(exclude_prefix + "*")

    # Gather a list of src_path, dst_path pairs
    found_input_paths = False

    src_dirs = []
    src_depsets = []
    copy_paths = []
    for src in srcs:
        if DirectoryPathInfo in src:
            src_dirs.append(src)
        if DefaultInfo in src:
            src_depsets.append(src[DefaultInfo].files)

    # Convert potentially-large arrays into slices to pass by reference
    # instead of copying when invoking _copy_paths()
    root_paths = root_paths[:]
    include_external_repositories = include_external_repositories[:]
    include_srcs_packages = include_srcs_packages[:]
    exclude_srcs_packages = exclude_srcs_packages[:]
    include_srcs_patterns = include_srcs_patterns[:]
    exclude_srcs_patterns = exclude_srcs_patterns[:]

    if type(additional_files) == "list":
        additional_files = depset(additional_files)

    all_srcs = src_dirs + depset(transitive = [additional_files] + src_depsets).to_list()
    for src in all_srcs:
        found_input_paths = True
        src_path, output_path, src_file = _copy_paths(
            src = src,
            root_paths = root_paths,
            include_external_repositories = include_external_repositories,
            include_srcs_packages = include_srcs_packages,
            exclude_srcs_packages = exclude_srcs_packages,
            include_srcs_patterns = include_srcs_patterns,
            exclude_srcs_patterns = exclude_srcs_patterns,
            replace_prefixes = replace_prefixes,
        )
        if src_path != None:
            dst_path = skylib_paths.normalize("/".join([dst.path, output_path]))
            if not _merge_into_copy_path(copy_paths, src_path, dst_path, src_file):
                copy_paths.append((src_path, dst_path, src_file))

    if not found_input_paths:
        fail("No files or directories found in srcs.")
    if not copy_paths:
        fail("There are no files or directories to copy after applying filters. Are your 'include_srcs_patterns' and 'exclude_srcs_patterns' attributes correct?")

    # Because copy actions have "local" execution requirements, we can safely assume
    # the execution is the same as the host platform and generate different actions for Windows
    # and non-Windows host platforms
    is_windows = _platform_utils.host_platform_is_windows()
    if is_windows:
        _copy_to_dir_cmd(ctx, copy_paths, dst)
    else:
        _copy_to_dir_bash(ctx, copy_paths, dst, allow_overwrites)

copy_to_directory_lib = struct(
    doc = _copy_to_directory_doc,
    attr_doc = _copy_to_directory_attr_doc,
    attrs = _copy_to_directory_attr,
    impl = _copy_to_directory_impl,
    provides = [DefaultInfo],
)
