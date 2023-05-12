"""Path utils built on top of Skylib's path utils"""

load("@bazel_skylib//lib:paths.bzl", _spaths = "paths")

def _relative_file(to_file, frm_file):
    """Resolves a relative path between two files, "to_file" and "frm_file".

    If neither of the paths begin with ../ it is assumed that they share the same root. When finding the relative path,
    the incoming files are treated as actual files (not folders) so the resulting relative path may differ when compared
    to passing the same arguments to python's "os.path.relpath()" or NodeJs's "path.relative()".

    For example, 'relative_file("../foo/foo.txt", "bar/bar.txt")' will return '../../foo/foo.txt'

    Args:
        to_file: the path with file name to resolve to, from frm
        frm_file: the path with file name to resolve from

    Returns:
        The relative path from frm_file to to_file, including the file name
    """
    to_parent_count = to_file.count("../")
    frm_parent_count = frm_file.count("../")

    parent_count = to_parent_count

    if to_parent_count > 0 and frm_parent_count > 0:
        if frm_parent_count > to_parent_count:
            fail("traversing more parent directories (with '../') for 'frm_file' than 'to_file' requires file layout knowledge")

        parent_count = to_parent_count - frm_parent_count

    to_segments = _spaths.normalize(_spaths.join("/", to_file)).split("/")[:-1]
    frm_segments = _spaths.normalize(_spaths.join("/", frm_file)).split("/")[:-1]

    if len(to_segments) == 0 and len(frm_segments) == 0:
        return to_file

    # since we prefix a "/" and normalize, the first segment is always "". So split point will be at least 1
    split_point = 1

    # if either of the paths starts with ../ then assume that any shared paths are a coincidence
    if to_segments[0] != ".." and frm_segments != "..":
        longest_common = []
        for to_seg, frm_seg in zip(to_segments, frm_segments):
            if to_seg == frm_seg:
                longest_common.append(to_seg)
            else:
                break

        split_point = len(longest_common)

    return _spaths.join(
        *(
            [".."] * (len(frm_segments) - split_point + parent_count) +
            to_segments[split_point:] +
            [_spaths.basename(to_file)]
        )
    )

def _to_output_relative_path(file):
    """
    The relative path from bazel-out/[arch]/bin to the given File object

    Args:
        file: a `File` object

    Returns:
        The output relative path for the `File`
    """
    if file.is_source:
        execroot = "../../../"
    else:
        execroot = ""
    if file.short_path.startswith("../"):
        path = "external/" + file.short_path[3:]
    else:
        path = file.short_path
    return execroot + path

def _to_rlocation_path(ctx, file):
    """The rlocation path for a `File`

    This produces the same value as the `rlocationpath` predefined source/output path variable.

    From https://bazel.build/reference/be/make-variables#predefined_genrule_variables:

    > `rlocationpath`: The path a built binary can pass to the `Rlocation` function of a runfiles
    > library to find a dependency at runtime, either in the runfiles directory (if available)
    > or using the runfiles manifest.

    > This is similar to root path (a.k.a. [short_path](https://bazel.build/rules/lib/File#short_path))
    > in that it does not contain configuration prefixes, but differs in that it always starts with the
    > name of the repository.

    > The rlocation path of a `File` in an external repository repo will start with `repo/`, followed by the
    > repository-relative path.

    > Passing this path to a binary and resolving it to a file system path using the runfiles libraries
    > is the preferred approach to find dependencies at runtime. Compared to root path, it has the
    > advantage that it works on all platforms and even if the runfiles directory is not available.

    Args:
        ctx: starlark rule execution context
        file: a `File` object

    Returns:
        The rlocationpath for the `File`
    """
    if file.short_path.startswith("../"):
        return file.short_path[3:]
    else:
        return ctx.workspace_name + "/" + file.short_path

def _to_repository_relative_path(file):
    """The repository relative path for a `File`

    This is the full runfiles path of a `File` excluding its workspace name.

    This differs from  root path (a.k.a. [short_path](https://bazel.build/rules/lib/File#short_path)) and
    rlocation path as it does not include the repository name if the `File` is from an external repository.

    Args:
        file: a `File` object

    Returns:
        The repository relative path for the `File`
    """

    if file.short_path.startswith("../"):
        return "/".join(file.short_path.split("/")[2:])
    else:
        return file.short_path

paths = struct(
    relative_file = _relative_file,
    to_output_relative_path = _to_output_relative_path,
    to_repository_relative_path = _to_repository_relative_path,
    to_rlocation_path = _to_rlocation_path,
    # TODO(2.0): remove to_workspace_path? it is replaced by to_repository_relative_path
    to_workspace_path = _to_repository_relative_path,
    # TODO(2.0): remove to_manifest_path? it is replaced by to_rlocation_path
    to_manifest_path = _to_rlocation_path,
)
