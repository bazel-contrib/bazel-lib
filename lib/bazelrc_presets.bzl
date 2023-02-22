"Aspect bazelrc presets; see https://docs.aspect.build/guides/bazelrc"

load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")

ALL_PRESETS = [
    "bazel5",
    "bazel6",
    "ci",
    "convenience",
    "correctness",
    "debug",
    "javascript",
    "performance",
]

def write_aspect_bazelrc_presets(
        name,
        presets = ALL_PRESETS,
        **kwargs):
    """Keeps your vendored copy of Aspect recommended `.bazelrc` presets up-to-date.

    This macro uses a [write_source_files](https://docs.aspect.build/rules/aspect_bazel_lib/docs/write_source_files)
    rule under the hood to keep your presets up-to-date.

    By default all presets are vendored but this list can be customized using
    the 'presets' attribute.

    See https://docs.aspect.build/guides/bazelrc for more info.

    Args:
        name: a unique name for this target

        presets: a list of preset names to keep up-to-date

          For example,

          ```
          write_aspect_bazelrc_presets(
            name = "update_aspect_bazelrc_presets",
            presets = [
              "bazel6",
              "ci",
              "convenience",
              "correctness",
              "debug",
              "javascript",
              "performance",
            ],
          )
          ```

        **kwargs: Additional arguments to pass to `write_source_files`
    """

    files = {}
    for p in presets:
        files["{}.bazelrc".format(p)] = "@aspect_bazel_lib//.aspect/bazelrc:{}.bazelrc".format(p)

    write_source_files(
        name = name,
        files = files,
        **kwargs
    )
