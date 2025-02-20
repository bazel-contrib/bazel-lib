# Tests of the vis encoding support scripts.
#
# Most test cases make use of the fact that newline characters are passed through verbatim by all of these scripts.
# For this reason, paragraph-delimited records of newline-delimited fields is a natural framing structure that will
# be preserved through the encoding/decoding/canonicalizing transformation.

gawk() {
  # TODO: from toolchain
  /opt/homebrew/bin/gawk "$@"
}
cat() {
  "$COREUTILS" cat "$@"
}
cp() {
  "$COREUTILS" cp "$@"
}
cut() {
  "$COREUTILS" cut "$@"
}
diff() {
  # No toolchain diff tool available; rely on system version. `diff` is part of POSIX; it should be available.
  diff "$@"
}
tr() {
  "$COREUTILS" tr "$@"
}
basenc() {
  "$COREUTILS" basenc "$@"
}
od() {
  "$COREUTILS" od "$@"
}
paste() {
  "$COREUTILS" paste "$@"
}

@test "vis encode passthrough text" {
  cat <<'EOF' >"$BATS_TEST_TMPDIR/input"
Newlines (\n), backslahes (\\), spaces (\s), and graphical ASCII ([[:graph:]]) characters are passed through unencoded.
Upstream encoders should escape the first three in content they feed to the general encoder.

    Newline   => \012
    Backslash => \134
    Space     => \040

These gaps enable our encoder to operate on newline-delimited records of space-delimited fields of vis-encoded content.
EOF

  gawk -bf "$VIS_ESCAPE" <"$BATS_TEST_TMPDIR/input" >"$BATS_TEST_TMPDIR/output"

  # Content chosen to pass through encoder unmodified.
  cp "$BATS_TEST_TMPDIR/input" "$BATS_TEST_TMPDIR/want"

  cd "$BATS_TEST_TMPDIR"
  diff -u want output
}

@test "vis encode each byte" {
  gawk -v OFS="0A" -v ORS="0A0A" '{ $1 = $1; print }' <<'EOF' | basenc --decode --base16 >"$BATS_TEST_TMPDIR/input"
00 01 02 03 04 05 06 07 08 09    0B 0C 0D 0E 0F
10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F
20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F
30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F
40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F
50 51 52 53 54 55 56 57 58 59 5A 5B    5D 5E 5F
60 61 62 63 64 65 66 67 68 69 6A 6B 6C 6D 6E 6F
70 71 72 73 74 75 76 77 78 79 7A 7B 7C 7D 7E 7F
80 81 82 83 84 85 86 87 88 89 8A 8B 8C 8D 8E 8F
90 91 92 93 94 95 96 97 98 99 9A 9B 9C 9D 9E 9F
A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 AA AB AC AD AE AF
B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 BA BB BC BD BE BF
C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 CA CB CC CD CE CF
D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 DA DB DC DD DE DF
E0 E1 E2 E3 E4 E5 E6 E7 E8 E9 EA EB EC ED EE EF
F0 F1 F2 F3 F4 F5 F6 F7 F8 F9 FA FB FC FD FE FF
EOF

  gawk -bf "$VIS_ESCAPE" <"$BATS_TEST_TMPDIR/input" >"$BATS_TEST_TMPDIR/output.raw"

  gawk -v FS='\n' -v RS='\n\n' '
    NR == rshift(0x00, 4) + 1  { for (i = NF; i > 0x0A; i--) $(i+1) = $(i); $(0x0A+1) = "" }            # Newline gap
    NR == rshift(0x50, 4) + 1  { for (i = NF; i > 0x0C; i--) $(i+1) = $(i); $(0x0C+1) = "" }            # Backslash gap
                               { for (i = 1; i <= NF; i++) printf "%4s%s", $(i), i == NF ? ORS : OFS }  # Emit table with fixed-width columns.
  ' <"$BATS_TEST_TMPDIR/output.raw" >"$BATS_TEST_TMPDIR/output"

  cat <<'EOF' >"$BATS_TEST_TMPDIR/want"
\000 \001 \002 \003 \004 \005 \006 \007 \010 \011      \013 \014 \015 \016 \017
\020 \021 \022 \023 \024 \025 \026 \027 \030 \031 \032 \033 \034 \035 \036 \037
        !    "    #    $    %    &    '    (    )    *    +    ,    -    .    /
   0    1    2    3    4    5    6    7    8    9    :    ;    <    =    >    ?
   @    A    B    C    D    E    F    G    H    I    J    K    L    M    N    O
   P    Q    R    S    T    U    V    W    X    Y    Z    [         ]    ^    _
   `    a    b    c    d    e    f    g    h    i    j    k    l    m    n    o
   p    q    r    s    t    u    v    w    x    y    z    {    |    }    ~ \177
\200 \201 \202 \203 \204 \205 \206 \207 \210 \211 \212 \213 \214 \215 \216 \217
\220 \221 \222 \223 \224 \225 \226 \227 \230 \231 \232 \233 \234 \235 \236 \237
\240 \241 \242 \243 \244 \245 \246 \247 \250 \251 \252 \253 \254 \255 \256 \257
\260 \261 \262 \263 \264 \265 \266 \267 \270 \271 \272 \273 \274 \275 \276 \277
\300 \301 \302 \303 \304 \305 \306 \307 \310 \311 \312 \313 \314 \315 \316 \317
\320 \321 \322 \323 \324 \325 \326 \327 \330 \331 \332 \333 \334 \335 \336 \337
\340 \341 \342 \343 \344 \345 \346 \347 \350 \351 \352 \353 \354 \355 \356 \357
\360 \361 \362 \363 \364 \365 \366 \367 \370 \371 \372 \373 \374 \375 \376 \377
EOF

  cd "$BATS_TEST_TMPDIR"
  diff -u want output
}

@test "vis decode passthrough text" {
  cat <<'EOF' >"$BATS_TEST_TMPDIR/input"
All text that is not an 3-digit octal escape sequence is passed through the decoder.
This includes backslashes (\), even those part of special forms sometimes recognized elsewhere (e.g. \n, \r, \v, \0, etc.).
EOF

  gawk -bf "$UNVIS" <"$BATS_TEST_TMPDIR/input" >"$BATS_TEST_TMPDIR/output"

  # Content chosen to pass through encoder unmodified.
  cp "$BATS_TEST_TMPDIR/input" "$BATS_TEST_TMPDIR/want"

  cd "$BATS_TEST_TMPDIR"
  diff -u want output
}

@test "vis decode passthrough all non-escape-sequence bytes" {
  tr -d ' \n' <<'EOF' | basenc --decode --base16 >"$BATS_TEST_TMPDIR/input"
00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F
20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F
30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F
40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F
50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F
60 61 62 63 64 65 66 67 68 69 6A 6B 6C 6D 6E 6F
70 71 72 73 74 75 76 77 78 79 7A 7B 7C 7D 7E 7F
80 81 82 83 84 85 86 87 88 89 8A 8B 8C 8D 8E 8F
90 91 92 93 94 95 96 97 98 99 9A 9B 9C 9D 9E 9F
A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 AA AB AC AD AE AF
B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 BA BB BC BD BE BF
C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 CA CB CC CD CE CF
D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 DA DB DC DD DE DF
E0 E1 E2 E3 E4 E5 E6 E7 E8 E9 EA EB EC ED EE EF
F0 F1 F2 F3 F4 F5 F6 F7 F8 F9 FA FB FC FD FE FF
EOF

  gawk -bf "$UNVIS" <"$BATS_TEST_TMPDIR/input" >"$BATS_TEST_TMPDIR/output.raw"

  # Decoded content contains unprintable control characters. Diff the hexdump instead.
  od -Ax -tx1 <"$BATS_TEST_TMPDIR/output.raw" >"$BATS_TEST_TMPDIR/output"

  cat <<'EOF' >"$BATS_TEST_TMPDIR/want"
000000 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f
000010 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f
000020 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f
000030 30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f
000040 40 41 42 43 44 45 46 47 48 49 4a 4b 4c 4d 4e 4f
000050 50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f
000060 60 61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f
000070 70 71 72 73 74 75 76 77 78 79 7a 7b 7c 7d 7e 7f
000080 80 81 82 83 84 85 86 87 88 89 8a 8b 8c 8d 8e 8f
000090 90 91 92 93 94 95 96 97 98 99 9a 9b 9c 9d 9e 9f
0000A0 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 aa ab ac ad ae af
0000B0 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 ba bb bc bd be bf
0000C0 c0 c1 c2 c3 c4 c5 c6 c7 c8 c9 ca cb cc cd ce cf
0000D0 d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 da db dc dd de df
0000E0 e0 e1 e2 e3 e4 e5 e6 e7 e8 e9 ea eb ec ed ee ef
0000F0 f0 f1 f2 f3 f4 f5 f6 f7 f8 f9 fa fb fc fd fe ff
000100
EOF

  cd "$BATS_TEST_TMPDIR"
  diff -u want output
}

@test "vis decode all octal escape-sequences" {
  tr -d ' \n' <<'EOF' >"$BATS_TEST_TMPDIR/input"
\000 \001 \002 \003 \004 \005 \006 \007 \010 \011 \012 \013 \014 \015 \016 \017
\020 \021 \022 \023 \024 \025 \026 \027 \030 \031 \032 \033 \034 \035 \036 \037
\040 \041 \042 \043 \044 \045 \046 \047 \050 \051 \052 \053 \054 \055 \056 \057
\060 \061 \062 \063 \064 \065 \066 \067 \070 \071 \072 \073 \074 \075 \076 \077
\100 \101 \102 \103 \104 \105 \106 \107 \110 \111 \112 \113 \114 \115 \116 \117
\120 \121 \122 \123 \124 \125 \126 \127 \130 \131 \132 \133 \134 \135 \136 \137
\140 \141 \142 \143 \144 \145 \146 \147 \150 \151 \152 \153 \154 \155 \156 \157
\160 \161 \162 \163 \164 \165 \166 \167 \170 \171 \172 \173 \174 \175 \176 \177
\200 \201 \202 \203 \204 \205 \206 \207 \210 \211 \212 \213 \214 \215 \216 \217
\220 \221 \222 \223 \224 \225 \226 \227 \230 \231 \232 \233 \234 \235 \236 \237
\240 \241 \242 \243 \244 \245 \246 \247 \250 \251 \252 \253 \254 \255 \256 \257
\260 \261 \262 \263 \264 \265 \266 \267 \270 \271 \272 \273 \274 \275 \276 \277
\300 \301 \302 \303 \304 \305 \306 \307 \310 \311 \312 \313 \314 \315 \316 \317
\320 \321 \322 \323 \324 \325 \326 \327 \330 \331 \332 \333 \334 \335 \336 \337
\340 \341 \342 \343 \344 \345 \346 \347 \350 \351 \352 \353 \354 \355 \356 \357
\360 \361 \362 \363 \364 \365 \366 \367 \370 \371 \372 \373 \374 \375 \376 \377
EOF

  gawk -bf "$UNVIS" <"$BATS_TEST_TMPDIR/input" >"$BATS_TEST_TMPDIR/output.raw"

  # Decoded content contains unprintable control characters. Diff the hexdump instead.
  od -Ax -tx1 <"$BATS_TEST_TMPDIR/output.raw" >"$BATS_TEST_TMPDIR/output"

  cat <<'EOF' >"$BATS_TEST_TMPDIR/want"
000000 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f
000010 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f
000020 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f
000030 30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f
000040 40 41 42 43 44 45 46 47 48 49 4a 4b 4c 4d 4e 4f
000050 50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f
000060 60 61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f
000070 70 71 72 73 74 75 76 77 78 79 7a 7b 7c 7d 7e 7f
000080 80 81 82 83 84 85 86 87 88 89 8a 8b 8c 8d 8e 8f
000090 90 91 92 93 94 95 96 97 98 99 9a 9b 9c 9d 9e 9f
0000A0 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 aa ab ac ad ae af
0000B0 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 ba bb bc bd be bf
0000C0 c0 c1 c2 c3 c4 c5 c6 c7 c8 c9 ca cb cc cd ce cf
0000D0 d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 da db dc dd de df
0000E0 e0 e1 e2 e3 e4 e5 e6 e7 e8 e9 ea eb ec ed ee ef
0000F0 f0 f1 f2 f3 f4 f5 f6 f7 f8 f9 fa fb fc fd fe ff
000100
EOF

  cd "$BATS_TEST_TMPDIR"
  diff -u want output
}

@test "vis canonicalize passthrough already-canonical" {
  cat <<'EOF' >"$BATS_TEST_TMPDIR/input.table"
\000 \001 \002 \003 \004 \005 \006 \007 \010 \011 \012 \013 \014 \015 \016 \017
\020 \021 \022 \023 \024 \025 \026 \027 \030 \031 \032 \033 \034 \035 \036 \037
\040    !    "    #    $    %    &    '    (    )    *    +    ,    -    .    /
   0    1    2    3    4    5    6    7    8    9    :    ;    <    =    >    ?
   @    A    B    C    D    E    F    G    H    I    J    K    L    M    N    O
   P    Q    R    S    T    U    V    W    X    Y    Z    [ \134    ]    ^    _
   `    a    b    c    d    e    f    g    h    i    j    k    l    m    n    o
   p    q    r    s    t    u    v    w    x    y    z    {    |    }    ~ \177
\200 \201 \202 \203 \204 \205 \206 \207 \210 \211 \212 \213 \214 \215 \216 \217
\220 \221 \222 \223 \224 \225 \226 \227 \230 \231 \232 \233 \234 \235 \236 \237
\240 \241 \242 \243 \244 \245 \246 \247 \250 \251 \252 \253 \254 \255 \256 \257
\260 \261 \262 \263 \264 \265 \266 \267 \270 \271 \272 \273 \274 \275 \276 \277
\300 \301 \302 \303 \304 \305 \306 \307 \310 \311 \312 \313 \314 \315 \316 \317
\320 \321 \322 \323 \324 \325 \326 \327 \330 \331 \332 \333 \334 \335 \336 \337
\340 \341 \342 \343 \344 \345 \346 \347 \350 \351 \352 \353 \354 \355 \356 \357
\360 \361 \362 \363 \364 \365 \366 \367 \370 \371 \372 \373 \374 \375 \376 \377
EOF
  gawk -v OFS='\n' -v ORS='\n\n' '{ $1 = $1; print }' <"$BATS_TEST_TMPDIR/input.table" >"$BATS_TEST_TMPDIR/input"

  gawk -bf "$VIS_CANONICALIZE" <"$BATS_TEST_TMPDIR/input" >"$BATS_TEST_TMPDIR/output.raw"

  gawk -v FS='\n' -v RS='\n\n' '
    { for (i = 1; i <= NF; i++) printf "%4s%s", $(i), i == NF ? ORS : OFS }  # Emit table with fixed-width columns.
  ' <"$BATS_TEST_TMPDIR/output.raw" >"$BATS_TEST_TMPDIR/output"

  # Content chosen to pass through encoder unmodified.
  cp "$BATS_TEST_TMPDIR/input.table" "$BATS_TEST_TMPDIR/want"

  cd "$BATS_TEST_TMPDIR"
  diff -u want output
}

@test "vis canonicalize unnecessarily escaped" {
  gawk -v OFS='\n' -v ORS='\n\n' '{ $1 = $1; print }' <<'EOF' >"$BATS_TEST_TMPDIR/input"
     \041 \042 \043 \044 \045 \046 \047 \050 \051 \052 \053 \054 \055 \056 \057
\060 \061 \062 \063 \064 \065 \066 \067 \070 \071 \072 \073 \074 \075 \076 \077
\100 \101 \102 \103 \104 \105 \106 \107 \110 \111 \112 \113 \114 \115 \116 \117
\120 \121 \122 \123 \124 \125 \126 \127 \130 \131 \132 \133      \135 \136 \137
\140 \141 \142 \143 \144 \145 \146 \147 \150 \151 \152 \153 \154 \155 \156 \157
\160 \161 \162 \163 \164 \165 \166 \167 \170 \171 \172 \173 \174 \175 \176 
EOF

  gawk -bf "$VIS_CANONICALIZE" <"$BATS_TEST_TMPDIR/input" >"$BATS_TEST_TMPDIR/output.raw"

  gawk -v FS='\n' -v RS='\n\n' '
    NR == rshift(0x20 - 0x20, 4) + 1  { for (i = NF; i > 0x00; i--) $(i+1) = $(i); $(0x00+1) = "" }            # Space gap
    NR == rshift(0x50 - 0x20, 4) + 1  { for (i = NF; i > 0x0C; i--) $(i+1) = $(i); $(0x0C+1) = "" }            # Backslash gap
    NR == rshift(0x70 - 0x20, 4) + 1  { for (i = NF; i > 0x0F; i--) $(i+1) = $(i); $(0x0F+1) = "" }            # Delete gap
                                      { for (i = 1; i <= NF; i++) printf "%1s%s", $(i), i == NF ? ORS : OFS }  # Emit table with fixed-width columns.
  ' <"$BATS_TEST_TMPDIR/output.raw" >"$BATS_TEST_TMPDIR/output"

  cat <<'EOF' >"$BATS_TEST_TMPDIR/want"
  ! " # $ % & ' ( ) * + , - . /
0 1 2 3 4 5 6 7 8 9 : ; < = > ?
@ A B C D E F G H I J K L M N O
P Q R S T U V W X Y Z [   ] ^ _
` a b c d e f g h i j k l m n o
p q r s t u v w x y z { | } ~  
EOF

  cd "$BATS_TEST_TMPDIR"
  diff -u want output
}

@test "vis canonicalize unescaped" {
  gawk -v OFS='0A' -v ORS='0A0A' '{ $1 = $1; print }' <<'EOF' | basenc --decode --base16 >"$BATS_TEST_TMPDIR/input"
00 01 02 03 04 05 06 07 08 09    0B 0C 0D 0E 0F
10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F
20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F
30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F
40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F
50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F
60 61 62 63 64 65 66 67 68 69 6A 6B 6C 6D 6E 6F
70 71 72 73 74 75 76 77 78 79 7A 7B 7C 7D 7E 7F
80 81 82 83 84 85 86 87 88 89 8A 8B 8C 8D 8E 8F
90 91 92 93 94 95 96 97 98 99 9A 9B 9C 9D 9E 9F
A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 AA AB AC AD AE AF
B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 BA BB BC BD BE BF
C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 CA CB CC CD CE CF
D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 DA DB DC DD DE DF
E0 E1 E2 E3 E4 E5 E6 E7 E8 E9 EA EB EC ED EE EF
F0 F1 F2 F3 F4 F5 F6 F7 F8 F9 FA FB FC FD FE FF
EOF

  gawk -bf "$VIS_CANONICALIZE" <"$BATS_TEST_TMPDIR/input" >"$BATS_TEST_TMPDIR/output.raw"

  gawk -v FS='\n' -v RS='\n\n' '
    NR == rshift(0x00, 4) + 1  { for (i = NF; i > 0x0A; i--) $(i+1) = $(i); $(0x0A+1) = "" }            # Newline gap
                               { for (i = 1; i <= NF; i++) printf "%4s%s", $(i), i == NF ? ORS : OFS }  # Emit table with fixed-width columns.
  ' <"$BATS_TEST_TMPDIR/output.raw" >"$BATS_TEST_TMPDIR/output"

  cat <<'EOF' >"$BATS_TEST_TMPDIR/want"
\000 \001 \002 \003 \004 \005 \006 \007 \010 \011      \013 \014 \015 \016 \017
\020 \021 \022 \023 \024 \025 \026 \027 \030 \031 \032 \033 \034 \035 \036 \037
\040    !    "    #    $    %    &    '    (    )    *    +    ,    -    .    /
   0    1    2    3    4    5    6    7    8    9    :    ;    <    =    >    ?
   @    A    B    C    D    E    F    G    H    I    J    K    L    M    N    O
   P    Q    R    S    T    U    V    W    X    Y    Z    [ \134    ]    ^    _
   `    a    b    c    d    e    f    g    h    i    j    k    l    m    n    o
   p    q    r    s    t    u    v    w    x    y    z    {    |    }    ~ \177
\200 \201 \202 \203 \204 \205 \206 \207 \210 \211 \212 \213 \214 \215 \216 \217
\220 \221 \222 \223 \224 \225 \226 \227 \230 \231 \232 \233 \234 \235 \236 \237
\240 \241 \242 \243 \244 \245 \246 \247 \250 \251 \252 \253 \254 \255 \256 \257
\260 \261 \262 \263 \264 \265 \266 \267 \270 \271 \272 \273 \274 \275 \276 \277
\300 \301 \302 \303 \304 \305 \306 \307 \310 \311 \312 \313 \314 \315 \316 \317
\320 \321 \322 \323 \324 \325 \326 \327 \330 \331 \332 \333 \334 \335 \336 \337
\340 \341 \342 \343 \344 \345 \346 \347 \350 \351 \352 \353 \354 \355 \356 \357
\360 \361 \362 \363 \364 \365 \366 \367 \370 \371 \372 \373 \374 \375 \376 \377
EOF

  cd "$BATS_TEST_TMPDIR"
  diff -u want output
}

@test "vis canonicalize special forms" {
  cat <<'EOF' >"$BATS_TEST_TMPDIR/input_want"
\0	\000
\	\134
\\	\134
\a	\007
\b	\010
\f	\014
\n	\012
\r	\015
\s	\040
\t	\011
\v	\013
EOF
  cut -f1 <"$BATS_TEST_TMPDIR/input_want" >"$BATS_TEST_TMPDIR/input"

  gawk -bf "$VIS_CANONICALIZE" <"$BATS_TEST_TMPDIR/input" >"$BATS_TEST_TMPDIR/output"

  paste "$BATS_TEST_TMPDIR/input" "$BATS_TEST_TMPDIR/output" >"$BATS_TEST_TMPDIR/input_output"

  cd "$BATS_TEST_TMPDIR"
  diff -u input_want input_output
}
