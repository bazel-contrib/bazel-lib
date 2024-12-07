# Edits mtree files. See the modify_mtree macro in /lib/tar.bzl.
{
    if (preserve_symlink != "") {
        # By default Bazel reports symlinks as regular file/dir therefore mtree_spec has no way of knowing that a file
        # is a symlink. This is a problem when we want to preserve symlinks especially for symlink sensitive applications
        # such as nodejs with pnpm. To work around this we need to determine if a file a symlink and if so, we need to
        # determine where the symlink points to by calling readlink repeatedly until we get the final destination.
        #
        # We then need to decide if it's a symlink based on how many times we had to call readlink and where we ended up.
        #
        # Unlike Bazels own symlinks, which points out of the sandbox symlinks, symlinks created by ctx.actions.symlink
        # stays within the bazel sandbox so it's possible to detect those.
        #
        # See https://github.com/bazelbuild/rules_pkg/pull/609
        if ($0 ~ /type=file/) {

        }
    }
    if (strip_prefix != "") {
        if ($1 == strip_prefix) {
            # this line declares the directory which is now the root. It may be discarded.
            next;
        } else if (index($1, strip_prefix) == 1) {
            # this line starts with the strip_prefix
            sub("^" strip_prefix "/", "");

            # NOTE: The mtree format treats file paths without slashes as "relative" entries.
            #       If a relative entry is a directory, then it will "change directory" to that
            #       directory, and any subsequent "relative" entries will be created inside that
            #       directory. This causes issues when there is a top-level directory that is
            #       followed by a top-level file, as the file will be created inside the directory.
            #       To avoid this, we append a slash to the directory path to make it a "full" entry.
            components = split($1, _, "/");
            if ($0 ~ /type=dir/ && components == 1) {
                $1 = $1 "/";
            }
        } else {
            # this line declares some path under a parent directory, which will be discarded
            next;
        }
    }

    if (mtime != "") {
        sub(/time=[0-9\.]+/, "time=" mtime);
    }

    if (owner != "") {
        sub(/uid=[0-9\.]+/, "uid=" owner)
    }

    if (ownername != "") {
        sub(/uname=[^ ]+/, "uname=" ownername)
    }

    if (package_dir != "") {
        sub(/^/, package_dir "/")
    }
    print;
}
