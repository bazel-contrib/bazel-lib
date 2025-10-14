# Bazel helpers library

Base Starlark libraries and basic Bazel rules which are useful for constructing rulesets and BUILD files.

📚 **API documentation**: https://registry.bazel.build/docs/bazel_lib

## 3.0 release

This branch has code for the 3.0 release of `bazel_lib`, to https://registry.bazel.build/modules/bazel_lib

The module has been renamed from the 2.x releases which used the name "aspect_bazel_lib".
Following Aspect's donation to the Linux Foundation, the new name allows more of the community to participate without supporting one vendor.
This code is still in the `2.x` branch.

These two modules can be used in parallel during a transition. Note that `tar`, `jq` and `yq` have moved to their own modules as part of the 3.0 release.

## Relationship to bazel-skylib

This module depends on [bazel-skylib](https://github.com/bazelbuild/bazel-skylib).
In theory all these utilities could be upstreamed to bazel-skylib, but the declared scope of that project
is narrow and it no longer accepts feature requests, see https://github.com/orgs/bazelbuild/discussions/3.
It's possible that we may instead remove the dependency on bazel-skylib and entirely replace it, in an ABI-compatible sense. See https://github.com/bazel-contrib/bazel-lib/issues/927.

## Installation

Installation instructions are included on each release:
<https://github.com/bazel-contrib/bazel-lib/releases>

To use a commit rather than a release, you can point at any SHA of the repo.
However, this adds more "dev dependencies", as you'll have to build our helper programs
(such as `copy_to_directory`, `expand_template`) from their Go sources rather than
download pre-built binaries.

For example to use commit `abc123` in `MODULE.bazel`:

```
# Automatically picks up new Go dev dependencies
git_override(
    module_name = "bazel_lib",
    commit = "abc123",
    remote = "git@github.com:bazel-contrib/bazel-lib.git",
)
```

Or in `WORKSPACE`:

1. Replace `url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v0.1.0/bazel-lib-v0.1.0.tar.gz"`
   with a GitHub-provided source archive like
   `url = "https://github.com/bazel-contrib/bazel-lib/archive/abc123.tar.gz"`
1. Replace `strip_prefix = "bazel-lib-0.1.0"` with `strip_prefix = "bazel-lib-abc123"`
1. Update the `sha256`. The easiest way to do this is to comment out the line, then Bazel will
   print a message with the correct value.
1. `load("@bazel_lib//:deps.bzl", "go_dependencies")` and then call `go_dependencies()`

> Note that GitHub source archives don't have a strong guarantee on the sha256 stability, see
> <https://github.blog/2023-02-21-update-on-the-future-stability-of-source-code-archives-and-hashes>
