"""default_info_files implementation
"""

load("//lib:utils.bzl", _to_label = "to_label")

def _default_info_files(ctx):
    files = []
    for path in ctx.attr.paths:
        file = find_short_path_in_default_info(
            ctx.attr.target,
            path,
        )
        if not file:
            fail("%s file not found within the DefaultInfo of %s" % (ctx.attr.path, ctx.attr.target))
        files.append(file)
    return [DefaultInfo(
        files = depset(direct = files),
        runfiles = ctx.runfiles(files = files),
    )]

default_info_files = rule(
    doc = "A rule that provides file(s) from a given target's DefaultInfo",
    implementation = _default_info_files,
    attrs = {
        "target": attr.label(
            doc = "the target to look in for requested paths in its' DefaultInfo",
            mandatory = True,
        ),
        "paths": attr.string_list(
            doc = "the paths of the files to provide in the DefaultInfo of the target relative to its root",
            mandatory = True,
            allow_empty = False,
        ),
    },
    provides = [DefaultInfo],
)

def make_default_info_files(name, target, paths):
    """Helper function to generate a default_info_files target and return its label.

    Args:
        name: unique name for the generated `default_info_files` target.
        target: the target to look in for requested paths in its' DefaultInfo
        paths: the paths of the files to provide in the DefaultInfo of the target relative to its root

    Returns:
        The label `name`
    """
    default_info_files(
        name = name,
        target = target,
        paths = paths,
    )
    return _to_label(name)

def find_short_path_in_default_info(default_info, short_path):
    """Helper function find a file in a DefaultInfo by short path

    Args:
        default_info: a DefaultInfo
        short_path: the short path (path relative to root) to search for

    Returns:
        The File if found else None
    """
    if default_info.files:
        for file in default_info.files.to_list():
            if file.short_path == short_path:
                return file
    return None
