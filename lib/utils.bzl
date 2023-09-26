"Public API"

load("//lib/private:utils.bzl", "utils")

default_timeout = utils.default_timeout
file_exists = utils.file_exists
glob_directories = utils.glob_directories
is_bazel_6_or_greater = utils.is_bazel_6_or_greater
is_bzlmod_enabled = utils.is_bzlmod_enabled
is_external_label = utils.is_external_label
maybe_http_archive = utils.maybe_http_archive
path_to_workspace_root = utils.path_to_workspace_root
propagate_well_known_tags = utils.propagate_well_known_tags
propagate_common_rule_attributes = utils.propagate_common_rule_attributes
propagate_common_test_rule_attributes = utils.propagate_common_test_rule_attributes
propagate_common_binary_rule_attributes = utils.propagate_common_binary_rule_attributes
to_label = utils.to_label
consistent_label_str = utils.consistent_label_str
