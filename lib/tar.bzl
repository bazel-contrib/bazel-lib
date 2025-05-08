"""Re-export of https://registry.bazel.build/modules/tar.bzl to avoid breaking change.
TODO(3.0): delete
"""

load("@tar.bzl//tar:mtree.bzl", _mtree_mutate = "mtree_mutate", _mtree_spec = "mtree_spec")
load("@tar.bzl//tar:tar.bzl", _tar = "tar")

mtree_mutate = _mtree_mutate
mtree_spec = _mtree_spec
tar = _tar
