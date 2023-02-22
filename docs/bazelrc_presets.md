<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Aspect bazelrc presets; see https://docs.aspect.build/guides/bazelrc

<a id="write_aspect_bazelrc_presets"></a>

## write_aspect_bazelrc_presets

<pre>
write_aspect_bazelrc_presets(<a href="#write_aspect_bazelrc_presets-name">name</a>, <a href="#write_aspect_bazelrc_presets-presets">presets</a>, <a href="#write_aspect_bazelrc_presets-kwargs">kwargs</a>)
</pre>

Keeps your vendored copy of Aspect recommended `.bazelrc` presets up-to-date.

This macro uses a [write_source_files](https://docs.aspect.build/rules/aspect_bazel_lib/docs/write_source_files)
rule under the hood to keep your presets up-to-date.

By default all presets are vendored but this list can be customized using
the 'presets' attribute.

See https://docs.aspect.build/guides/bazelrc for more info.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="write_aspect_bazelrc_presets-name"></a>name |  a unique name for this target   |  none |
| <a id="write_aspect_bazelrc_presets-presets"></a>presets |  a list of preset names to keep up-to-date<br><br>For example,<br><br><pre><code> write_aspect_bazelrc_presets(   name = "update_aspect_bazelrc_presets",   presets = [     "bazel6",     "ci",     "convenience",     "correctness",     "debug",     "javascript",     "performance",   ], ) </code></pre>   |  <code>["bazel5", "bazel6", "ci", "convenience", "correctness", "debug", "javascript", "performance"]</code> |
| <a id="write_aspect_bazelrc_presets-kwargs"></a>kwargs |  Additional arguments to pass to <code>write_source_files</code>   |  none |


