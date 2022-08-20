"Public API"

load("//lib/private:utils.bzl", "utils")

is_external_label = utils.is_external_label
glob_directories = utils.glob_directories
path_to_workspace_root = utils.path_to_workspace_root
propagate_well_known_tags = utils.propagate_well_known_tags
to_label = utils.to_label
file_exists = utils.file_exists
default_timeout = utils.default_timeout
