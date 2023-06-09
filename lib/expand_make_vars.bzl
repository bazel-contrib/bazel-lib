"Public API for expanding variables"

load("//lib/private:expand_locations.bzl", _expand_locations = "expand_locations")
load("//lib/private:expand_variables.bzl", _expand_variables = "expand_variables")
load(":expand_template.bzl", _expand_template = "expand_template")

expand_locations = _expand_locations
expand_variables = _expand_variables

# TODO: 2.0 remove re-export from this file.
expand_template = _expand_template
