"Copy files and directories to an output directory"

load(
    "//lib/private:copy_to_directory.bzl",
    lib = "copy_to_directory_lib",
)

_copy_to_directory = rule(
    implementation = lib.impl,
    provides = lib.provides,
    attrs = lib.attrs,
)

def copy_to_directory(
        name,
        srcs = [],
        root_paths = None,
        include_external_repositories = [],
        exclude_prefixes = [],
        replace_prefixes = {},
        **kwargs):
    """Copies files and directories to an output directory.

    Files and directories can be arranged as needed in the output directory using
    the `root_paths`, `exclude_prefixes` and `replace_prefixes` attributes.

    Args:
        name: A unique name for this target.

        srcs: Files and/or directories or targets that provide DirectoryPathInfo to copy into the output directory.

        root_paths: List of paths that are roots in the output directory.

            If a file or directory being copied is in one of the listed paths or one of its subpaths,
            the output directory path is the path relative to the root path instead of the path
            relative to the file's workspace.

            Forward slashes (`/`) should be used as path separators. Partial matches
            on the final path segment of a root path against the corresponding segment
            in the full workspace relative path of a file are not matched.

            If there are multiple root paths that match, the longest match wins.

            Defaults to [package_name()] so that the output directory path of files in the
            target's package and and sub-packages are relative to the target's package and
            files outside of that retain their full workspace relative paths.

        include_external_repositories: List of external repository names to include in the output directory.

            Files from external repositories are not copied into the output directory unless
            the external repository they come from is listed here.

            When copied from an external repository, the file path in the output directory
            defaults to the file's path within the external repository. The external repository
            name is _not_ included in that path.

            For example, the following copies `@external_repo//path/to:file` to
            `path/to/file` within the output directory.

            ```
            copy_to_directory(
                name = "dir",
                include_external_repositories = ["external_repo"],
                srcs = ["@external_repo//path/to:file"],
            )
            ```

            Files from external repositories are subject to `root_paths`, `exclude_prefixes`
            and `replace_prefixes` in the same way as files form the main repository.

        exclude_prefixes: List of path prefixes to exclude from output directory.

            If the output directory path for a file or directory starts with or is equal to
            a path in the list then that file is not copied to the output directory.

            Exclude prefixes are matched *before* replace_prefixes are applied.

        replace_prefixes: Map of paths prefixes to replace in the output directory path when copying files.

            If the output directory path for a file or directory starts with or is equal to
            a key in the dict then the matching portion of the output directory path is
            replaced with the dict value for that key.

            Forward slashes (`/`) should be used as path separators. The final path segment
            of the key can be a partial match in the corresponding segment of the output
            directory path.

            If there are multiple keys that match, the longest match wins.

        **kwargs: Other common named parameters such as `tags` or `visibility`
    """

    if root_paths == None:
        root_paths = [native.package_name()]

    _copy_to_directory(
        name = name,
        srcs = srcs,
        root_paths = root_paths,
        include_external_repositories = include_external_repositories,
        exclude_prefixes = exclude_prefixes,
        replace_prefixes = replace_prefixes,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
