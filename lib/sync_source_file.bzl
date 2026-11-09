"""Synchronize a source file or directory using a build validation action.

This is an alternative to `write_source_files` for callers who want stale source
files to fail `bazel build`. It re-exports `diff.bzl`'s `sync_source_file` macro,
which compares the source with its origin using hermetic GNU diff. Existing
`diff_test` and `write_source_files` targets keep their test-based behavior.

For example, in `pkg/BUILD.bazel`:

```starlark
load("@bazel_lib//lib:sync_source_file.bzl", "sync_source_file")

sync_source_file(
    name = "sync_generated",
    origin = ":generated_file",
    out = "checked_in_file.txt",
)
```

`out` must be in the same package as the target. Build `//pkg/...` to check
its sync targets. In the default patch mode, building `//pkg:sync_generated`
also validates an existing source file. To accept the generated content, run
`bazel run //pkg:sync_generated --norun_validations`.

The default `mode = "patch"` applies the diff using the system `patch` command;
`mode = "copy"` copies the origin instead. The updater scripts require Bash.
See [diff.bzl](https://github.com/kormide/diff.bzl) for the full API.
"""

load("@diff.bzl//diff:sync_source_file.bzl", _sync_source_file = "sync_source_file")

sync_source_file = _sync_source_file
