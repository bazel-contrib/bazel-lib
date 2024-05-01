# Edits mtree files. See the modify_mtree macro in /lib/tar.bzl.
{
    if (strip_prefix != "") {
        if ($1 == strip_prefix) {
            # this line declares the directory which is now the root. It may be discarded.
            next;
        } else if (index($1, strip_prefix) == 1) {
            # this line starts with the strip_prefix
            sub("^" strip_prefix "/", "");
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
