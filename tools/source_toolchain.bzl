"""macros for defining source toolchains for tools"""

def source_toolchain(name, toolchain_rule, toolchain_type, binary):
    toolchain_rule(
        name = "{}_source".format(name),
        bin = binary,
        visibility = ["//visibility:public"],
    )

    native.toolchain(
        name = name,
        toolchain = ":{}_source".format(name),
        toolchain_type = toolchain_type,
        target_settings = [
            "@aspect_bazel_lib//tools:prefer_source_toolchains",
        ],
    )
