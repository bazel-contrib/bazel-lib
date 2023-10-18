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


<a id="mtree_spec"></a>

## mtree_spec

<pre>
mtree_spec(<a href="#mtree_spec-name">name</a>, <a href="#mtree_spec-out">out</a>, <a href="#mtree_spec-srcs">srcs</a>, <a href="#mtree_spec-transform">transform</a>)
</pre>

Create an mtree specification to map a directory hierarchy. See https://man.freebsd.org/cgi/man.cgi?mtree(8)

Supports `$` and `^` RegExp tokens, which may be used together.

* for stripping prefix, use `^path/to/strip`
* for stripping suffix, use `path/to/strip$`
* for exact match and replace, use `^path/to/strip$`
* for partial match and replace, use `replace_anywhere`


An example of stripping package path relative to the workspace

```starlark
tar(
    srcs = ["PKGINFO"],
    transform = {
        "^{}".format(package_name()): ""
    }
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="mtree_spec-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="mtree_spec-out"></a>out |  Resulting specification file to write   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional |  |
| <a id="mtree_spec-srcs"></a>srcs |  Files that are placed into the tar   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | required |  |
| <a id="mtree_spec-transform"></a>transform |  A dict for path transforming. These are applied serially in respect to their orders.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |


<a id="tar_rule"></a>

## tar_rule

<pre>
tar_rule(<a href="#tar_rule-name">name</a>, <a href="#tar_rule-args">args</a>, <a href="#tar_rule-compress">compress</a>, <a href="#tar_rule-mode">mode</a>, <a href="#tar_rule-mtree">mtree</a>, <a href="#tar_rule-out">out</a>, <a href="#tar_rule-srcs">srcs</a>)
</pre>

Rule that executes BSD `tar`. Most users should use the [`tar`](#tar) macro, rather than load this directly.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="tar_rule-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="tar_rule-args"></a>args |  Additional flags permitted by BSD tar; see the man page.   | List of strings | optional | [] |
| <a id="tar_rule-compress"></a>compress |  Compress the archive file with a supported algorithm.   | String | optional | "" |
| <a id="tar_rule-mode"></a>mode |  A mode indicator from the following list, copied from the tar manpage:<br><br>       - create: Create a new archive containing the specified items.        - append: Like <code>create</code>, but new entries are appended to the archive.             Note that this only works on uncompressed archives stored in regular files.             The -f option is required.        - list: List  archive contents to stdout.        - update: Like <code>append</code>, but new entries are added only if they have a             modification date newer than the corresponding entry in the archive. 	       Note that this only works on uncompressed archives stored in 	       regular files. The -f option	is required.        - extract: Extract to disk from the archive. If a file with the same name 	       appears more than once in the archive, each copy	 will  be  extracted,            with  later  copies  overwriting  (replacing) earlier copies.   | String | optional | "create" |
| <a id="tar_rule-mtree"></a>mtree |  An mtree specification file   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="tar_rule-out"></a>out |  Resulting tar file to write. If absent, <code>[name].tar</code> is written.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional |  |
| <a id="tar_rule-srcs"></a>srcs |  Files, directories, or other targets whose default outputs are placed into the tar.<br><br>        If any of the srcs are binaries with runfiles, those are copied into the resulting tar as well.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | required |  |


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
Because BSD tar doesn't have a flag to set modification times to a constant,
we must always supply an mtree input to get reproducible builds.
See https://reproducible-builds.org/docs/archives/ for more explanation.

1. By default, mtree is "auto" which causes the macro to create an `mtree` rule.

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


