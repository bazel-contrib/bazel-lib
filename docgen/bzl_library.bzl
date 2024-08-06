"""Workaround for ModuleInfoExtractor not having a java_binary.

See https://github.com/bazelbuild/bazel/blob/dbbdf2bbaed216e1fbdc07ce03dce2bf5fd90749/src/main/java/com/google/devtools/build/lib/rules/starlarkdocextract/StarlarkDocExtract.java#L306
Ideally we would just run an aspect over the bzl_library targets in the repo, but that aspect needs a binary to run.
The native starlark_doc_extract rule abuses the fact that it's written in the Bazel codebase and so it has special access to that program logic.
"""

load("@bazel_skylib//:bzl_library.bzl", _bzl_library_rule = "bzl_library")

def bzl_library(name, srcs, deps = [], extract_docs = True, **kwargs):
    if len(srcs) == 1 and extract_docs:
        native.starlark_doc_extract(
            name = name + ".doc_extract",
            src = srcs[0],
            deps = deps,
        )

    _bzl_library_rule(name = name, srcs = srcs, deps = deps, **kwargs)
