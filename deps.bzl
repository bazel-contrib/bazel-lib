"""This module contains the project repository dependencies.
"""

load("@gazelle//:deps.bzl", "go_repository")

def go_dependencies():
    """The Go dependencies.
    """
    go_repository(
        name = "com_github_bmatcuk_doublestar_v4",
        build_file_proto_mode = "disable_global",
        importpath = "github.com/bmatcuk/doublestar/v4",
        sum = "h1:FH9SifrbvJhnlQpztAx++wlkk70QBf0iBWDwNy7PA4I=",
        version = "v4.6.1",
    )
    go_repository(
        name = "com_github_google_go_cmp",
        build_file_proto_mode = "disable_global",
        importpath = "github.com/google/go-cmp",
        sum = "h1:e6P7q2lk1O+qJJb4BtCQXlK8vWEO8V1ZeuEdJNOqZyg=",
        version = "v0.5.8",
    )
    go_repository(
        name = "org_golang_x_exp",
        build_file_proto_mode = "disable_global",
        importpath = "golang.org/x/exp",
        sum = "h1:Q8/wZp0KX97QFTc2ywcOE0YRjZPVIx+MXInMzdvQqcA=",
        version = "v0.0.0-20240119083558-1b970713d09a",
    )
    go_repository(
        name = "org_golang_x_mod",
        build_file_proto_mode = "disable_global",
        importpath = "golang.org/x/mod",
        sum = "h1:dGoOF9QVLYng8IHTm7BAyWqCqSheQ5pYWGhzW00YJr0=",
        version = "v0.14.0",
    )
    go_repository(
        name = "org_golang_x_sys",
        build_file_proto_mode = "disable_global",
        importpath = "golang.org/x/sys",
        sum = "h1:Twjiwq9dn6R1fQcyiK+wQyHWfaz/BJB+YIpzU/Cv3Xg=",
        version = "v0.24.0",
    )
