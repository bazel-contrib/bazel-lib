load("@bazel_lib//lib:run_binary.bzl", "run_binary")
load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

sh_binary(
    name = "tool",
    srcs = ["tool.sh"],
    visibility = ["//visibility:public"],
)

go_binary(
    name = "wasm_tool",
    srcs = ["tool.go"],
    goarch = "wasm",
    goos = "wasip1",
    # build as a reactor
    linkmode = "c-shared",
    visibility = ["//visibility:public"],
)

run_binary(
    name = "package",
    outs = ["output.txt"],
    args = ["$(location output.txt)"],
    tool = ":fake_tool",
)

go_library(
    name = "package_lib",
    srcs = ["tool.go"],
    importpath = "github.com/bazel-contrib/bazel-lib/path/to/package",
    visibility = ["//visibility:private"],
)
