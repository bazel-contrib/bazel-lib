"Public API"

load("//lib/private:base64.bzl", _decode = "decode", _encode = "encode")

base64 = struct(
    decode = _decode,
    encode = _encode,
)
