#!/usr/bin/env gawk --characters-as-bytes --file
#
# Replace most bytes with their octal escape sequences.
# Backslashes, newlines, and spaces remain in place to preserve newline-delimited records of space-delimited fields
# while allowing upstream producers to include these delimiters in vis-encoded content.

BEGIN {
    # Not all entries in REPLACE will be used but over-inclusion is simpler.
    for (i = 0x00; i <= 0xFF; i++) {
        b = sprintf("%c", i)
	esc = sprintf("\\%03o", i)
        REPLACE[b] = esc
    }
}

{
    n = split($0, verbatim_parts, /[^[:graph:] \\]/, replace_parts)
    for (i = 1; i < n; i++)
        printf "%s%s", verbatim_parts[i], REPLACE[replace_parts[i]]
    printf "%s%s", verbatim_parts[n], RT
}
