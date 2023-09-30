<!-- Generated with Stardoc: http://skydoc.bazel.build -->

General-purpose rule to create tar archives.

Unlike [pkg_tar from rules_pkg](https://github.com/bazelbuild/rules_pkg/blob/main/docs/latest.md#pkg_tar)
this:

- Does not depend on any Python interpreter setup
- Does not have any custom program to produce the output, instead
  we rely on a well-known C++ program called "tar".
  Specifically, we use the BSD variant of tar since it provides a means
  of controlling mtimes, uid, symlinks, etc.

We also provide full control for tar'ring binaries including their runfiles.


<a id="tar_rule"></a>

## tar_rule

<pre>
tar_rule(<a href="#tar_rule-name">name</a>, <a href="#tar_rule-compress">compress</a>, <a href="#tar_rule-mtree">mtree</a>, <a href="#tar_rule-out">out</a>, <a href="#tar_rule-srcs">srcs</a>)
</pre>

Rule that executes BSD `tar`. Most users should use the [`tar`](#tar) macro, rather than load this directly.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="tar_rule-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="tar_rule-compress"></a>compress |  Compress the archive file with a supported algorithm.   | String | optional | "" |
| <a id="tar_rule-mtree"></a>mtree |  An mtree specification file   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="tar_rule-out"></a>out |  Resulting tar file to write   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional |  |
| <a id="tar_rule-srcs"></a>srcs |  Files that are placed into the tar   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | required |  |


<a id="tar"></a>

## tar

<pre>
tar(<a href="#tar-name">name</a>, <a href="#tar-mtree">mtree</a>, <a href="#tar-kwargs">kwargs</a>)
</pre>

Wrapper macro around [`tar_rule`](#tar_rule).

Allows the mtree to be supplied as an array literal of lines, in addition to a separate file, e.g.

```
mtree =[
    "usr/bin uid=0 gid=0 mode=0755 type=dir",
    "usr/bin/ls uid=0 gid=0 mode=0755 time=0 type=file content={}/a".format(package_name()),
],
```

For the format of a line, see "There are four types of lines in a specification" on the man page for BSD mtree,
https://man.freebsd.org/cgi/man.cgi?mtree(8)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="tar-name"></a>name |  name of resulting <code>tar_rule</code>   |  none |
| <a id="tar-mtree"></a>mtree |  either an array of specification lines, or a label of a file that contains the lines.   |  <code>None</code> |
| <a id="tar-kwargs"></a>kwargs |  additional named parameters to pass to <code>tar_rule</code>   |  none |


