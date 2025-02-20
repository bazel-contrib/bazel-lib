#!/usr/bin/env gawk --characters-as-bytes --file
#
# Replace octal escape sequences with the bytes they represent.
# NOTE: not a fully general unvis program.

BEGIN {
    for (i = 0x00; i <= 0xFF; i++) {
        b = sprintf("%c", i)
        esc = sprintf("\\%03o", i)
        REPLACE[esc] = b
    }
}

{
    n = split($0, verbatim_parts, /[\\][0-3][0-7][0-7]/, replace_parts)
    for (i = 1; i < n; i++)
        printf "%s%s", verbatim_parts[i], REPLACE[replace_parts[i]]
    printf "%s%s", verbatim_parts[n], RT
}
