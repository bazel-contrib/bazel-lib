"""Re-export of https://registry.bazel.build/modules/tar.bzl to avoid breaking change.
https://github.com/bazel-contrib/bazel-lib/pull/1083 moved these symbols to tar.bzl
TODO(3.0): delete
"""

load("@tar.bzl//tar:mtree.bzl", _mtree_mutate = "mtree_mutate", _mtree_spec = "mtree_spec")
load("@tar.bzl//tar:tar.bzl", _tar = "tar", _tar_lib = "tar_lib", _tar_rule = "tar_rule")

mtree_mutate = _mtree_mutate
mtree_spec = _mtree_spec
tar = _tar
tar_lib = _tar_lib
tar_rule = _tar_rule
