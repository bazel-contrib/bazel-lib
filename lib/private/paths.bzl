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
        fail("paths must share a common root, got '%s' and '%s'" % (to_file, frm_file))

    longest_common = []
    for to_seg, frm_seg in zip(to_segments, frm_segments):
        if to_seg == frm_seg:
            longest_common.append(to_seg)
        else:
            break

    split_point = len(longest_common)

    if split_point == 0:
        fail("paths share no common ancestor, '%s' -> '%s'" % (frm_file, to_file))

    return _spaths.join(
        *(
            [".."] * (len(frm_segments) - split_point) +
            to_segments[split_point:] +
            [_spaths.basename(to_file)]
        )
    )

paths = struct(
    relative_file = _relative_file,
)
