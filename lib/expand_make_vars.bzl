"Public API for expanding variables"

load(
    "//lib/private:expand_make_vars.bzl",
    _expand_locations = "expand_locations",
    _expand_template = "expand_template",
    _expand_variables = "expand_variables",
)

expand_locations = _expand_locations
expand_variables = _expand_variables

expand_template = rule(
    doc = _expand_template.doc,
    implementation = _expand_template.implementation,
    attrs = _expand_template.attrs,
)
