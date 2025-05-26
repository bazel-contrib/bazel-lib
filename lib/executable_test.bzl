"""A test rule that checks the executable permission on a file or directory."""

load(
    "//lib/private:executable_test.bzl",
    _executable_test = "executable_test",
)

executable_test = _executable_test
