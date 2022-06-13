"""Path utils built on top of Skylib's path utils"""

load("@bazel_skylib//lib:paths.bzl", _spaths = "paths")

def _relative_file(to_file, frm_file):
    """Resolves a relative path between two files, "to_file" and "frm_file", they must share the same root

    Args:
        to_file: the path with file name to resolve to, from frm
        frm_file: the path with file name to resolve from

    Returns:
        The relative path from frm_file to to_file, including the file name
    """

    to_segments = _spaths.normalize(_spaths.join("/", to_file)).split("/")[:-1]
    frm_segments = _spaths.normalize(_spaths.join("/", frm_file)).split("/")[:-1]

    if len(to_segments) == 0 and len(frm_segments) == 0:
        return to_file

    if to_segments[0] != frm_segments[0]:
        msg = "paths must share a common root, got '{}' and '{}'".format(to_file, frm_file)
        fail(msg)

    longest_common = []
    for to_seg, frm_seg in zip(to_segments, frm_segments):
        if to_seg == frm_seg:
            longest_common.append(to_seg)
        else:
            break

    split_point = len(longest_common)

    if split_point == 0:
        msg = "paths share no common ancestor, '{}' -> '{}'".format(frm_file, to_file)
        fail(msg)

    return _spaths.join(
        *(
            [".."] * (len(frm_segments) - split_point) +
            to_segments[split_point:] +
            [_spaths.basename(to_file)]
        )
    )

def _to_output_relative_path(f):
    "The relative path from bazel-out/[arch]/bin to the given File object"
    if f.is_source:
        execroot = "../../../"
    else:
        execroot = ""
    if f.short_path.startswith("../"):
        path = "external/" + f.short_path[3:]
    else:
        path = f.short_path
    return execroot + path

def _to_manifest_path(ctx, file):
    """The runfiles manifest entry path for a file

    This is the full runfiles path of a file including its workspace name as
    the first segment. We refert to it as the manifest path as it is the path
    flavor that is used for in the runfiles MANIFEST file.

    We must avoid using non-normalized paths (workspace/../other_workspace/path)
    in order to locate entries by their key.

    Args:
        ctx: starlark rule execution context
        file: a File object

    Returns:
        The runfiles manifest entry path for a file
    """

    if file.short_path.startswith("../"):
        return file.short_path[3:]
    else:
        return ctx.workspace_name + "/" + file.short_path

def _to_workspace_path(file):
    """The workspace relative path for a file

    This is the full runfiles path of a file excluding its workspace name.
    This differs from root path and manifest path as it does not include the
    repository name if the file is from an external repository.

    Args:
        file: a File object

    Returns:
        The workspace relative path for a file
    """

    if file.short_path.startswith("../"):
        return "/".join(file.short_path.split("/")[2:])
    else:
        return file.short_path

paths = struct(
    relative_file = _relative_file,
    to_manifest_path = _to_manifest_path,
    to_output_relative_path = _to_output_relative_path,
    to_workspace_path = _to_workspace_path,
)
