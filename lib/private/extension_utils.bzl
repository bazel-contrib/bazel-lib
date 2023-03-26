"Starlark utilities for module extensions"

load("//lib:semver.bzl", "semver")

def highest_compatible_toolchain_version(selected_version, all_versions):
    """Select the highest compatible version for a toolchain.

    This is useful in a module extension that registers a single toolchain
    for a module dependency graph.

    Al versions must follow semantic versioning. Preceeding 'v's are supported.

    Args:
        selected_version: Toolchain version used in the root module
        all_versions: List of requested toolchain versions in the module dependency graph

    Returns:
        Most recent version compatible with the selected version.
    """
    selected_version = semver.parse(selected_version)
    all_versions = sorted(
        [semver.parse(v) for v in all_versions],
        key = semver.key,
    )

    if selected_version.major < all_versions[-1].major:
        fail("Incompatible version")

    same_major_versions = [v for v in all_versions if v.major == selected_version.major]
    highest_compatible = same_major_versions[-1]

    return semver.to_str(highest_compatible)
