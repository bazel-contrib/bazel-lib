# Declare the local Bazel workspace.
# This is *not* included in the published distribution.
workspace(
    # see https://docs.bazel.build/versions/main/skylark/deploying.html#workspace
    name = "aspect_bazel_lib",
)

load(":internal_deps.bzl", "bazel_lib_internal_deps")

# Fetch deps needed only locally for development
bazel_lib_internal_deps()

load("//lib:repositories.bzl", "aspect_bazel_lib_dependencies")

aspect_bazel_lib_dependencies(override_local_config_platform = True)

# For running our own unit tests
load("@bazel_skylib//lib:unittest.bzl", "register_unittest_toolchains")

register_unittest_toolchains()

# An external repository for test to use
local_repository(
    name = "external_test_repo",
    path = "./lib/tests/external_test_repo",
)

load("//lib:host_repo.bzl", "host_repo")

host_repo(name = "aspect_bazel_lib_host")

############################################
# rules_go

load("//:deps.bzl", "go_dependencies")

# gazelle:repository_macro deps.bzl%go_dependencies
# gazelle:repository go_repository name=org_golang_x_tools importpath=golang.org/x/tools
# https://github.com/bazelbuild/bazel-gazelle/issues/1217#issuecomment-1152236735
go_dependencies()

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.18.3")

############################################
# Gazelle, for generating bzl_library targets

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

gazelle_dependencies()

# Buildifier
load("@buildifier_prebuilt//:deps.bzl", "buildifier_prebuilt_deps")

buildifier_prebuilt_deps()

load("@buildifier_prebuilt//:defs.bzl", "buildifier_prebuilt_register_toolchains")

buildifier_prebuilt_register_toolchains()
