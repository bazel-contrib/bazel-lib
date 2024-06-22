## Running bazel-lib tests

These four commands should be used to validate aspect-lib code

```
cd <workspace_dir>
1. bazel test //lib/tests/... --enable_runfiles
2. bazel test //lib/tests/... --noenable_runfiles
3. lib/tests/test_with_run.sh //lib/tests/... --enable_runfiles
4. lib/tests/test_with_run.sh //lib/tests/... --noenable_runfiles
```

These four commands each give a different set of results. `bazel run` behaves differently 
to `bazel test` in how it sets up the environment, so commands 3 and 4 give a more accurate 
validation of tools used in this way.

Note: On linux, commands 1 and 2 currently have the same behaviour (the --noenable_runfiles 
flag appears to be ignored with bazel test), I have an issue requesting clarification.

### test_with_run.sh

#### !This script makes changes to the source tree!
WARNING: This script will cause data to be written to the source tree. Some outputs may interfere between test cases. I have not found a way to avoid that. This is discussed here: https://github.com/bazelbuild/bazel/issues/3325. I've tried --run_under and can't get it to work on windows. 

We may be able to use git to automate deletion of test temporary data

#### Exit code
test_with_run.sh returns 1 if there are any failures and 0 if all tests pass

### test_with_run.bat
On windows, there is a bat wrapper. %BAZEL_SH% must be set to bash
```
lib\tests\test_with_run.bat //lib/tests/... --enable_runfiles
```