"Provide access to a BSD tar"

load(":repo_utils.bzl", "repo_utils")

BSDTAR_PLATFORMS = {
    "linux_amd64": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
    ),
    "linux_arm64": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
    ),
    # TODO(alexeagle): download from libarchive github releases.
    "windows_amd64": struct(
        release_platform = "win64",
        compatible_with = [
            "@platforms//os:windows",
            "@platforms//cpu:x86_64",
        ],
    ),
    # WARNING: host toolchain should always come last to make it a fallback toolchain.
    "host": struct(
        # loaded by the macro
        compatible_with = "HOST_CONSTRAINTS",
    ),
}

# note, using Ubuntu Focal packages as it works with older glibc versions.
# Ubuntu Jammy will fail on ubuntu 20.02 with
# bsdtar: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.33' not found
# bsdtar: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.34' not found
LIBARCHIVE13_URLS = {
    # https://packages.ubuntu.com/focal/amd64/libarchive13/download
    "linux_amd64": struct(
        urls = [
            "http://security.ubuntu.com/ubuntu/pool/main/liba/libarchive/libarchive13_3.4.0-2ubuntu1.2_amd64.deb",
        ],
        integrity = "8ba7507f61bb3ea8da488702ec0badcbfb726d36ea6886e3421ac59082aaf2d1",
        type = "deb",
        libs = "usr/lib/x86_64-linux-gnu",
    ),
    # http://ports.ubuntu.com/pool/main/liba/libarchive/
    "linux_arm64": struct(
        urls = [
            "http://ports.ubuntu.com/pool/main/liba/libarchive/libarchive13_3.4.0-2ubuntu1_arm64.deb",
        ],
        integrity = "aa5e31d05a9d6bde8093137bd1c82b5a20a5f470bd5109642014f895c20f323a",
        type = "deb",
        libs = "usr/lib/aarch64-linux-gnu",
    ),
}
LIBARCHIVE_TOOLS_URLS = {
    # https://packages.ubuntu.com/focal/amd64/libarchive-tools/download
    "linux_amd64": struct(
        urls = [
            "http://security.ubuntu.com/ubuntu/pool/universe/liba/libarchive/libarchive-tools_3.4.0-2ubuntu1.2_amd64.deb",
        ],
        integrity = "12a19878d34b407e6f4893d3b26b7758a26c5534a066d76184c8b764b2df1652",
        type = "deb",
    ),
    # http://ports.ubuntu.com/pool/main/liba/libarchive/
    "linux_arm64": struct(
        urls = [
            "http://ports.ubuntu.com/pool/main/liba/libarchive/libarchive-tools_3.2.1-2~ubuntu16.04.1_arm64.deb",
        ],
        integrity = "6d089f878507b536d8ca51b1ad80a80706a1dd7dbbcce7600800d3f9f98be2ab",
        type = "deb",
    ),
}

def _find_usable_system_tar(rctx, tar_name):
    tar = rctx.which(tar_name)
    if not tar:
        fail("tar not found on PATH, and we don't handle this case yet")

    # Run tar --version and see if we are satisfied to use it
    tar_version = rctx.execute([tar, "--version"]).stdout.strip()

    # TODO: also check if it's really ancient or compiled without gzip support or something?
    # TODO: document how users could fetch the source and compile it themselves
    if tar_version.find("bsdtar") >= 0:
        return tar

    fail("tar isn't a BSD tar")

def _bsdtar_binary_repo(rctx):
    tar_name = "tar.exe" if repo_utils.is_windows(rctx) else "tar"
    build_header = """\
# @generated by @aspect_bazel_lib//lib/private:tar_toolchain.bzl

load("@aspect_bazel_lib//lib/private:tar_toolchain.bzl", "tar_toolchain")

package(default_visibility = ["//visibility:public"])

"""

    # On MacOS, the system `tar` binary on the PATH should already work
    if rctx.attr.platform == "host":
        tar = _find_usable_system_tar(rctx, tar_name)
        output = rctx.path(tar_name)
        rctx.symlink(tar, output)
        rctx.file("BUILD.bazel", build_header + """tar_toolchain(name = "bsdtar_toolchain", binary = "tar")""")
        return

    # Other platforms, we have more work to do.
    libarchive_tools = LIBARCHIVE_TOOLS_URLS[rctx.attr.platform]
    libarchive13 = LIBARCHIVE13_URLS[rctx.attr.platform]

    # TODO: windows.
    rctx.download_and_extract(
        url = libarchive13.urls,
        output = "libarchive13",
        type = libarchive13.type,
        sha256 = libarchive13.integrity,
    )
    rctx.download_and_extract(
        url = libarchive_tools.urls,
        output = "libarchive-tools",
        type = libarchive_tools.type,
        sha256 = libarchive_tools.integrity,
    )
    rctx.extract(
        "libarchive13/data.tar.xz",
    )
    rctx.extract(
        "libarchive-tools/data.tar.xz",
    )

    rctx.file("BUILD.bazel", build_header + """\
filegroup(
    name = "libs",
    srcs = glob(["{libs}/*.so.*"])
)

tar_toolchain(
    name = "bsdtar_toolchain",
    binary = "usr/bin/bsdtar",
    include_path = "{include_path}",
    data = [":libs"],
    visibility = ["//visibility:public"],
)
""".format(libs = libarchive13.libs, include_path = rctx.path(libarchive13.libs)))

bsdtar_binary_repo = repository_rule(
    implementation = _bsdtar_binary_repo,
    attrs = {
        "platform": attr.string(mandatory = True, values = BSDTAR_PLATFORMS.keys()),
    },
)

TarInfo = provider(
    doc = "Provide info for executing BSD tar",
    fields = {
        "binary": "bsdtar executable",
        "include_path": "directory of dynamic-linked libraries needed on LD_LIBRARY_PATH",
        "files": "files which must be included as inputs to any actions running the binary",
    },
)

def _tar_toolchain_impl(ctx):
    binary = ctx.executable.binary

    # Make the $(BSDTAR_BIN) variable available in places like genrules.
    # See https://docs.bazel.build/versions/main/be/make-variables.html#custom_variables
    template_variables = platform_common.TemplateVariableInfo({
        "BSDTAR_BIN": binary.path,
        "BSDTAR_LIB": ctx.attr.include_path,
    })

    default_info = DefaultInfo(
        files = depset([binary]),
        runfiles = ctx.runfiles(files = [binary]),
    )
    tarinfo = TarInfo(
        binary = binary,
        include_path = ctx.attr.include_path,
        files = ctx.files.data,
    )

    # Export all the providers inside our ToolchainInfo
    # so the resolved_toolchain rule can grab and re-export them.
    toolchain_info = platform_common.ToolchainInfo(
        tarinfo = tarinfo,
        template_variables = template_variables,
        default = default_info,
    )

    return [toolchain_info, template_variables, default_info]

tar_toolchain = rule(
    implementation = _tar_toolchain_impl,
    attrs = {
        "binary": attr.label(
            doc = "a command to find on the system path",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "include_path": attr.string(
            doc = "folder include on LD_LIBRARY_PATH when running tar",
        ),
        "data": attr.label_list(doc = "Files needed in actions that run tar", allow_files = True),
    },
)

def _tar_toolchains_repo_impl(rctx):
    # Expose a concrete toolchain which is the result of Bazel resolving the toolchain
    # for the execution or target platform.
    # Workaround for https://github.com/bazelbuild/bazel/issues/14009
    starlark_content = """\
# @generated by @aspect_bazel_lib//lib/private:tar_toolchain.bzl

# Forward all the providers
def _resolved_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["@aspect_bazel_lib//lib:tar_toolchain_type"]
    return [
        toolchain_info,
        toolchain_info.default,
        toolchain_info.tarinfo,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
resolved_toolchain = rule(
    implementation = _resolved_toolchain_impl,
    toolchains = ["@aspect_bazel_lib//lib:tar_toolchain_type"],
    incompatible_use_toolchain_transition = True,
)
"""
    rctx.file("defs.bzl", starlark_content)

    build_content = """# @generated by @aspect_bazel_lib//lib/private:tar_toolchain.bzl
load(":defs.bzl", "resolved_toolchain")
load("@local_config_platform//:constraints.bzl", "HOST_CONSTRAINTS")

resolved_toolchain(name = "resolved_toolchain", visibility = ["//visibility:public"])"""

    for [platform, meta] in BSDTAR_PLATFORMS.items():
        build_content += """
toolchain(
    name = "{platform}_toolchain",
    exec_compatible_with = {compatible_with},
    toolchain = "@{user_repository_name}_{platform}//:bsdtar_toolchain",
    toolchain_type = "@aspect_bazel_lib//lib:tar_toolchain_type",
)
""".format(
            platform = platform,
            user_repository_name = rctx.attr.user_repository_name,
            compatible_with = meta.compatible_with,
        )

    rctx.file("BUILD.bazel", build_content)

tar_toolchains_repo = repository_rule(
    _tar_toolchains_repo_impl,
    doc = """Creates a repository that exposes a tar_toolchain_type target.""",
    attrs = {
        "user_repository_name": attr.string(doc = "Base name for toolchains repository"),
    },
)
