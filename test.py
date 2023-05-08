def hex(d):
    r = d
    hex_string = ""
    for _ in range(1000000):
        if r > 0:
            rem = r % 16
            hex_string = _to_char(rem) + hex_string
            r //= 16
        else:
            break
    return hex_string if hex_string else "0"

def _to_char(n):
    alpha = "0123456789abcdef"
    return alpha[n]

print(hex(11111), "0x" + to_hex(11111))