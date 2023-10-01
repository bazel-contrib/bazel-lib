<!-- Generated with Stardoc: http://skydoc.bazel.build -->

General-purpose rule to create tar archives.

Unlike [pkg_tar from rules_pkg](https://github.com/bazelbuild/rules_pkg/blob/main/docs/latest.md#pkg_tar)
this:

- Does not depend on any Python interpreter setup
- The "manifest" specification is a mature public API and uses a compact tabular format, fixing
  https://github.com/bazelbuild/rules_pkg/pull/238
- Does not have any custom program to produce the output, instead
  we rely on a well-known C++ program called "tar".
  Specifically, we use the BSD variant of tar since it provides a means
  of controlling mtimes, uid, symlinks, etc.

We also provide full control for tar'ring binaries including their runfiles.

TODO:
- Ensure we are reproducible, see https://reproducible-builds.org/docs/archives/
- Provide convenience for rules_pkg users to re-use or replace pkg_files trees


<a id="mtree"></a>

## mtree

<pre>
mtree(<a href="#mtree-name">name</a>, <a href="#mtree-out">out</a>)
</pre>

Create an mtree specification to map a directory hierarchy. See https://man.freebsd.org/cgi/man.cgi?mtree(8)

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="mtree-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="mtree-out"></a>out |  Resulting specification file to write   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional |  |


<a id="tar_rule"></a>

## tar_rule

<pre>
tar_rule(<a href="#tar_rule-name">name</a>, <a href="#tar_rule-args">args</a>, <a href="#tar_rule-compress">compress</a>, <a href="#tar_rule-gid">gid</a>, <a href="#tar_rule-gname">gname</a>, <a href="#tar_rule-mtree">mtree</a>, <a href="#tar_rule-out">out</a>, <a href="#tar_rule-srcs">srcs</a>, <a href="#tar_rule-uid">uid</a>, <a href="#tar_rule-uname">uname</a>)
</pre>

Rule that executes BSD `tar`. Most users should use the [`tar`](#tar) macro, rather than load this directly.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="tar_rule-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="tar_rule-args"></a>args |  Additional flags permitted by BSD tar --create   | List of strings | optional | [] |
| <a id="tar_rule-compress"></a>compress |  Compress the archive file with a supported algorithm.   | String | optional | "" |
| <a id="tar_rule-gid"></a>gid |  Use the provided group id number.  On extract, this overrides 	    the group id in the archive; the group name in the archive will 	    be  ignored. On create, this overrides the group id read from 	    disk; if --gname is not also specified, the group name will be 	    set to match the group id.   | String | optional | "0" |
| <a id="tar_rule-gname"></a>gname |  Use the provided  group name. On extract, this overrides the 	    group name in the archive; if the provided group name does not 	    exist on the system, the group id (from the archive or from the 	    --gid option) will be used instead. On create, this sets the 	    group name that will be stored in the archive; the name will 	    not be verified against the system group database.   | String | optional | "" |
| <a id="tar_rule-mtree"></a>mtree |  An mtree specification file   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="tar_rule-out"></a>out |  Resulting tar file to write   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional |  |
| <a id="tar_rule-srcs"></a>srcs |  Files that are placed into the tar   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | required |  |
| <a id="tar_rule-uid"></a>uid |  Use the provided user id number and ignore the user name from 	    the archive.  On create, if --uname is not also specified,  the 	    user name will be set to match the user id.   | String | optional | "0" |
| <a id="tar_rule-uname"></a>uname |  Use the provided user name.	On extract, this overrides the 	    user name in the archive; if the provided user name  does  not 	    exist  on  the system, it will be ignored and the user id (from 	    the archive or from the --uid option) will be used instead.  On 	    create, this sets the user name that  will  be  stored  in  the 	    archive; the name is not verified against the system user data- 	    base.   | String | optional | "" |


<a id="tar"></a>

## tar

<pre>
tar(<a href="#tar-name">name</a>, <a href="#tar-mtree">mtree</a>, <a href="#tar-kwargs">kwargs</a>)
</pre>

Wrapper macro around [`tar_rule`](#tar_rule).

Options for mtree
-----------------

mtree provides the "specification" or manifest of a tar file.
See https://man.freebsd.org/cgi/man.cgi?mtree(8)

1. By default, mtree is "auto" which causes the macro to create an `mtree` rule.
Because BSD tar doesn't have a flag to set modification times to a constant,
we must always supply an mtree input to get reproducible builds.
(See https://reproducible-builds.org/docs/archives/)

2. `mtree` may also be supplied as an array literal of lines, e.g.

```
mtree =[
    "usr/bin uid=0 gid=0 mode=0755 type=dir",
    "usr/bin/ls uid=0 gid=0 mode=0755 time=0 type=file content={}/a".format(package_name()),
],
```

For the format of a line, see "There are four types of lines in a specification" on the man page for BSD mtree,
https://man.freebsd.org/cgi/man.cgi?mtree(8)

3. `mtree` may be a label of a file containing the specification lines.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="tar-name"></a>name |  name of resulting <code>tar_rule</code>   |  none |
| <a id="tar-mtree"></a>mtree |  "auto", or an array of specification lines, or a label of a file that contains the lines.   |  <code>"auto"</code> |
| <a id="tar-kwargs"></a>kwargs |  additional named parameters to pass to <code>tar_rule</code>   |  none |


