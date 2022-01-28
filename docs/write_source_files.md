<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API for write_source_files

<a id="#write_source_files"></a>

## write_source_files

<pre>
write_source_files(<a href="#write_source_files-name">name</a>, <a href="#write_source_files-files">files</a>, <a href="#write_source_files-kwargs">kwargs</a>)
</pre>

Write to one or more files in the source tree. Stamp out tests that ensure the files exists and are up to date.

Usage:

```starlark
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")

write_source_files(
    name = "write_foobar",
    files = {
        "foobar.json": "//some/generated:file",
    },
)
```

To update the source file, run:
```bash
bazel run //:write_foobar
```

A test will fail if the source file doesn't exist
```bash
bazel test //...

//:foobar.json does not exist. To create & update this file, run:

    bazel run //:write_foobar
```

...or if it's out of date.
```bash
bazel test //...

//:foobar.json is out-of-date. To update this file, run:

    bazel run //:write_foobar
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="write_source_files-name"></a>name |  Name of the executable target that creates or updates the source file   |  none |
| <a id="write_source_files-files"></a>files |  A dict where the keys are source files to write to and the values are labels pointing to the desired content. Source files must be within the same bazel package as the target.   |  none |
| <a id="write_source_files-kwargs"></a>kwargs |  Other common named parameters such as <code>tags</code> or <code>visibility</code>   |  none |


