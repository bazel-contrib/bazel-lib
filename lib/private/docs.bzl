"Helpers for generating stardoc documentation"

load("@io_bazel_stardoc//stardoc:stardoc.bzl", "stardoc")
load("//lib:write_source_files.bzl", "write_source_files")

def stardoc_with_diff_test(
        name,
        bzl_library_target,
        aspect_template = "@io_bazel_stardoc//stardoc:templates/markdown_tables/aspect.vm",
        func_template = "@io_bazel_stardoc//stardoc:templates/markdown_tables/func.vm",
        header_template = "@io_bazel_stardoc//stardoc:templates/markdown_tables/header.vm",
        provider_template = "@io_bazel_stardoc//stardoc:templates/markdown_tables/provider.vm",
        rule_template = "@io_bazel_stardoc//stardoc:templates/markdown_tables/rule.vm",
        suggested_update_target = "//docs:update"):
    """Creates a stardoc target, diff test, and an executable to rule to write the generated doc to the source tree and test that it's up to date.

    This is helpful for minimizing boilerplate in repos wih lots of stardoc targets.

    Args:
        name: the name of the stardoc file to be written to the current source directory (.md will be appended to the name). Call bazel run on this target to update the file.
        bzl_library_target: the label of the `bzl_library` target to generate documentation for
        aspect_template: the label or path to the Velocity aspect template to use with stardoc
        func_template: the label or path to the Velocity function/macro template to use with stardoc
        header_template: the label or path to the Velocity header template to use with stardoc
        provider_template: the label or path to the Velocity provider template to use with stardoc
        rule_template: the label or path to the Velocity rule template to use with stardoc
        suggested_update_target: the target suggested to be run when a doc is out of date (should be the label for [update_docs](#update_docs))
    """

    stardoc_label = name + "-docgen"
    out_file = name + ".md"

    # Generate MD from .bzl
    stardoc(
        name = stardoc_label,
        out = name + "-docgen.md",
        input = bzl_library_target + ".bzl",
        deps = [bzl_library_target],
        aspect_template = aspect_template,
        func_template = func_template,
        header_template = header_template,
        provider_template = provider_template,
        rule_template = rule_template,
        tags = ["package:" + native.package_name()],  # Tag the package name which will help us reconstruct the write_source_files label in update_docs
    )

    write_source_files(
        name = name,
        suggested_update_target = suggested_update_target,
        files = {
            out_file: ":" + stardoc_label,
        },
    )

def update_docs(name = "update"):
    """Stamps an executable run for writing all stardocs declared with stardoc_with_diff_test to the source tree.

    This is to be used in tandem with `stardoc_with_diff_test()` to produce a convenient workflow
    for generating, testing, and updating all doc files as follows:

    ``` bash
    bazel build //{docs_folder}/... && bazel test //{docs_folder}/... && bazel run //{docs_folder}:update
    ```

    eg.

    ``` bash
    bazel build //docs/... && bazel test //docs/... && bazel run //docs:update
    ```

    Args:
        name: the name of executable target
    """

    update_labels = []
    for r in native.existing_rules().values():
        if r["kind"] == "stardoc":
            for tag in r["tags"]:
                if tag.startswith("package:"):
                    stardoc_name = r["name"]
                    write_source_files_name = stardoc_name[:-len("-docgen")]
                    update_labels.append("//%s:%s" % (tag[len("package:"):], write_source_files_name))

    write_source_files(
        name = name,
        additional_update_targets = update_labels,
    )
