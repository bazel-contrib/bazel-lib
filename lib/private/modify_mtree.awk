# Edits mtree files. See the modify_mtree macro in /lib/tar.bzl.
function make_relative_link(symlink, target) {
    command = "realpath -s --relative-to=\"" symlink "\" \"" target "\""
    command | getline relative
    return relative
}
{
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
                if ($0 !~ /^ /) {
                    $1 = $1 "/";
                }
                else {
                    # this line is the root directory and only contains orphaned keywords, which will be discarded
                    next;
                }
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
    if (preserve_symlinks != "") {
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

        symlink = ""
        if ($0 ~ /type=file/ && $0 ~ /content=/) {
            match($0, /content=[^ ]+/)
            content_field = substr($0, RSTART, RLENGTH)
            split(content_field, parts, "=")
            path = parts[2]
	    # Store paths for look up
	    symlink_map[path] = $1
	    # Resolve the symlink if it exists
	    resolved_path = ""
	    cmd = "readlink -f \"" path "\""
	    cmd | getline resolved_path
	    close(cmd)
	    # If readlink -f fails use readlink for relative links
	    if (resolved_path == "") {
		cmd = "readlink \"" path "\""
		cmd | getline resolved_path
		close(cmd)
	    }


	    if (resolved_path) {
		if (resolved_path ~ bin_dir || resolved_path ~ /\.\.\//) {
		    # Strip down the resolved path to start from bin_dir
		    sub("^.*" bin_dir, bin_dir, resolved_path)
		    # If the resolved path is different from the original path,
		    # or if it's a relative path
		    if (path != resolved_path || resolved_path ~ /\.\.\//) {
		        symlink = resolved_path
		    }
		}
	    }
        }
	if (symlink != "") {
	  line_array[NR] = $1 SUBSEP resolved_path
	  }
	else {
	    line_array[NR] = $0  # Store other lines too, with an empty path
	}
    }

    else {

      print;  # Print immediately if symlinks are not preserved

    }
}
END {
    if (preserve_symlinks != "") {
        # Process symlinks if needed
        for (i = 1; i <= NR; i++) {
            line = line_array[i]
            if (index(line, SUBSEP) > 0) {  # Check if this path was a symlink
	        split(line, fields, SUBSEP)
		field0 = fields[1]
		resolved_path = fields[2]
		if (resolved_path in symlink_map) {
                   mapped_link = symlink_map[resolved_path]
		   linked_to = make_relative_link(field0, mapped_link)
	        }
		else {
                  # Already a relative path
		   linked_to = resolved_path
	        }
                # Adjust the line for symlink using the map we created
                new_line = field0 " type=link link=" linked_to
                print new_line
            } else {
                # Print the original line if no symlink adjustment was needed
                print line
            }
        }
    }
}
