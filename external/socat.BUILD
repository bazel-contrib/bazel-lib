load("@rules_foreign_cc//foreign_cc:defs.bzl", "configure_make")

filegroup(
    name = "all_srcs",
    srcs = glob(
        include = ["**"],
        exclude = ["*.bazel"],
    ),
)

configure_make(
    name = "socat",
    env = select({
        "@platforms//os:macos": {"AR": ""},
        "//conditions:default": {},
    }),
    lib_source = ":all_srcs",
    out_binaries = ["socat"],
    visibility = ["//visibility:public"],
)

# load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
# load("@aspect_bazel_lib//lib:expand_make_vars.bzl", "expand_template")

# expand_template(
#     name = "fix_socat",
#     out = "main.c",
#     substitutions = {
#         "#include \"./VERSION\"": "\"1.7.4.3\"",
#     },
#     template = "socat.c",
# )

# copy_file(
#     name = "config",
#     src = "config.h.in",
#     out = "config.h",
# )

# cc_binary(
#     name = "socat",
#     srcs = glob(["*.h"]) + [
#         "config.h",
#         "main.c",
#         "xioopts.c",
#     ],
# )
