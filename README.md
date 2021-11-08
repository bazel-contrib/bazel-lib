# Aspect's Bazel helpers library

This is code we would contribute to bazel-skylib,
but the declared scope of that project is narrow
and it's very difficult to get anyone's attention
to review PRs there.

## Installation

Include this in your WORKSPACE file:

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "aspect_bazel_lib",
    url = "https://github.com/myorg/bazel_lib/releases/download/0.0.0/bazel_lib-0.0.0.tar.gz",
    sha256 = "",
)
```

> note, in the above, replace the version and sha256 with the one indicated
> in the release notes for bazel_lib
> In the future, our release automation should take care of this.
