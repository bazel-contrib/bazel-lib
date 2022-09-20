<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Wraps binary rules to make them more compatible with Bazel.

Currently supports only Bash as the wrapper language, not cmd.exe.

Future additions might include:
- wrap a binary such that it sees a tty on stdin
- manipulate arguments or environment variables
- redirect stdout/stderr, e.g. to silence buildspam on success
- intercept exit code, e.g. to make an "expect_fail"
- change user, e.g. to deal with containerized build running as root, but tool requires non-root
- intercept signals, e.g. to make a tool behave as a Bazel persistent worker


<a id="chdir_binary"></a>

## chdir_binary

<pre>
chdir_binary(<a href="#chdir_binary-name">name</a>, <a href="#chdir_binary-binary">binary</a>, <a href="#chdir_binary-chdir">chdir</a>, <a href="#chdir_binary-kwargs">kwargs</a>)
</pre>

Wrap a *_binary to be executed under a given working directory.

Note: under `bazel run`, this is similar to the `--run_under "cd $PWD &&"` trick, but is hidden
from the user so they don't need to know about that flag.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="chdir_binary-name"></a>name |  Name of the rule.   |  none |
| <a id="chdir_binary-binary"></a>binary |  Label of an executable target to wrap.   |  none |
| <a id="chdir_binary-chdir"></a>chdir |  Argument for the <code>cd</code> command, the default is commonly used with <code>bazel run</code> to run the program in the root of the Bazel workspace, in the source tree.   |  <code>"$BUILD_WORKSPACE_DIRECTORY"</code> |
| <a id="chdir_binary-kwargs"></a>kwargs |  Additional named arguments for the resulting sh_binary rule.   |  none |


