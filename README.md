# Aspect's Bazel helpers library

This is code we would contribute to bazel-skylib,
but the declared scope of that project is narrow
and it's very difficult to get anyone's attention
to review PRs there.

## Installation

From the release you wish to use:
<https://github.com/aspect-build/bazel-lib/releases>
copy the WORKSPACE snippet into your `WORKSPACE` file.

## Directory

| Project                | Description                                            | Docs                              |
| ---------------------- | ------------------------------------------------------ | --------------------------------- |
| copy_to_directory      | Copy files and directories to an output directory      | [docs](docs/copy_to_directory.md) |
| stardoc_with_diff_test | Keep stardocs up to date in your docs folder           | [docs](docs/docs.md)              |
| expand                 | Expand location and make vars in templates and strings | [docs](docs/expand_make_vars.md)  |
| jq                     | Run jq filters to manipulate json files                | [docs](docs/jq.md)                |
| params_file            | Generate params file from a list of arguments          | [docs](docs/params_file.md)       |
| paths                  | Various path methods                                   | [docs](docs/paths.md)             |
| utils                  | Useful starlark methods                                | [docs](docs/utils.md)             |
