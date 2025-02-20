#!/usr/bin/env gawk --characters-as-bytes --file
#
# Convert lines of vis-encoded content to a bespoke canonical form. After canonicalization, equality checks are trivial.
# Backslash, space characters, and all characters outside the 95 printable ASCII set are represented using escaped three-digit octal.
# The remaining characters are not escaped; they represent themselves.
# Newlines are the record separator and are exempt from replacement, although the escaped special form \n does canonicalized to octal.
#
# Input is interpreted as libarchive would, with a wider set of escape sequences:
#   * \\, \a, \b, \f, \n, \r, \t, \v have their conventional C-based meanings
#   * \0 means NUL when not the start of an three-digit octal escape sequence
#   * \s means SPACE
#   * \ is valid as an ordinary backslash when not the start of a valid escape sequence
#
# See: https://github.com/libarchive/libarchive/blob/a90e9d84ec147be2ef6a720955f3b315cb54bca3/libarchive/archive_read_support_format_mtree.c#L1942

BEGIN {
    REPLACE["\\\\"] = "\\134"
    REPLACE["\\0"] = "\\000"
    REPLACE["\\a"] = "\\007"
    REPLACE["\\b"] = "\\010"
    REPLACE["\\f"] = "\\014"
    REPLACE["\\n"] = "\\012"
    REPLACE["\\r"] = "\\015"
    REPLACE["\\s"] = "\\040"
    REPLACE["\\t"] = "\\011"
    REPLACE["\\v"] = "\\013"

    for (i = 0x00; i <= 0xFF; i++) {
        b = sprintf("%c", i)
        esc = sprintf("\\%03o", i)
        if (match(b, /[^[:graph:]]|[\\]/)) {
            REPLACE[b] = esc
            REPLACE[esc] = esc
        } else {
            REPLACE[esc] = b
        }
    }
}

{
    n = split($0, verbatim_parts, /[\\][\\0abfnrstv]|[\\][0-3][0-7][0-7]|[^[:graph:]]|[\\]/, replace_parts)
    for (i = 1; i < n; i++)
        printf "%s%s", verbatim_parts[i], REPLACE[replace_parts[i]]
    printf "%s%s", verbatim_parts[n], RT
}
