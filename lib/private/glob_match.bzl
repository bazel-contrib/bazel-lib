"""
Basic glob match implementation for starlark.

This was originally developed by @jbedard for use in rules_js
(https://github.com/aspect-build/rules_js/blob/6ca32d5199ddc0bf19bd704f591030dc1468ca5f/npm/private/pkg_glob.bzl)
to support the pnpm public-hoist-expr option (https://pnpm.io/npmrc#public-hoist-expr). The pnpm
implementation and tests were used as a reference implementation:
    https://github.com/pnpm/pnpm/blob/v7.4.0-2/packages/matcher/src/index.ts
    https://github.com/pnpm/pnpm/blob/v7.4.0-2/packages/matcher/test/index.ts
"""

GLOB_SYMBOLS = ["**", "*", "?"]

# "forever" (2^30) for ~ while(true) loops
_FOREVER = range(1073741824)

def _split_expr(expr):
    result = []

    # Splits an expression on the tokens in GLOB_SYMBOLS but keeps the tokens symb in the result.
    # Tokens are matched in order so a token such as `**` should come before `*`.
    expr_len = len(expr)
    accumulator = 0
    i = 0
    for _ in _FOREVER:
        if i >= expr_len:
            break

        found_symb = None
        for symb in GLOB_SYMBOLS:
            if expr.startswith(symb, i):
                found_symb = symb
                break

        if found_symb:
            if accumulator != i:
                result.append(expr[accumulator:i])

            result.append(found_symb)
            i = i + len(found_symb)
            accumulator = i
        else:
            i = i + 1

    if accumulator != i:
        result.append(expr[accumulator:])

    return result

def _validate_glob(expr):
    expr_len = len(expr)
    for i in range(expr_len):
        if expr[i] == "*" and i < expr_len - 1 and expr[i + 1] == "*":
            if i > 0 and expr[i - 1] != "/":
                msg = "glob_match: `**` globstar in expression `{}` must be at the start of the expression or preceeded by `/`".format(expr)
                fail(msg)
            if i < expr_len - 2 and expr[i + 2] != "/":
                msg = "glob_match: `**` globstar in expression `{}` must be at the end of the expression or followed by `/`".format(expr)
                fail(msg)

def is_glob(expr):
    """Determine if the passed string is a globa expression

    Args:
        expr: the potential glob expression

    Returns:
        True if the passed string is a globa expression
    """

    return expr.find("*") != -1 or expr.find("?") != -1

def glob_match(expr, path, match_path_separator = False):
    """Test if the passed path matches the glob expression.

    `*` A single asterisk stands for zero or more arbitrary characters except for the the path separator `/` if `match_path_separator` is False

    `?` The question mark stands for exactly one character except for the the path separator `/` if `match_path_separator` is False

    `**` A double asterisk stands for an arbitrary sequence of 0 or more characters. It is only allowed when preceded by either the beginning of the string or a slash. Likewise it must be followed by a slash or the end of the pattern.

    Args:
        expr: the glob expression
        path: the path against which to match the glob expression
        match_path_separator: whether or not to match the path separator '/' when matching `*` and `?` expressions

    Returns:
        True if the path matches the glob expression
    """

    if expr == "":
        fail("glob_match: invalid empty glob expression")

    if expr == "**":
        # matches everything
        return True

    if not is_glob(expr):
        # the expression is not a glob (does bot have any glob symbols) so the only match is an exact match
        return expr == path

    _validate_glob(expr)

    expr_parts = _split_expr(expr)

    for i, expr_part in enumerate(expr_parts):
        if expr_part == "**":
            if i > 0 and not expr_parts[i - 1].endswith("/"):
                msg = "glob_match: `**` globstar in expression `{}` must be at the start of the expression or preceeded by `/`".format(expr)
                fail(msg)
            if i != len(expr_parts) - 1 and not expr_parts[i + 1].startswith("/"):
                msg = "glob_match: `**` globstar in expression `{}` must be at the end of the expression or followed by `/`".format(expr)
                fail(msg)

    # Locations a * was terminated that can be rolled back to.
    branches = []
    expr_i = 0
    path_i = 0

    for _ in _FOREVER:
        subpath = path[path_i:] if path_i < len(path) else None
        subexpr = expr_parts[expr_i] if expr_i < len(expr_parts) else None

        # The next part of the expression.
        next_subexpr = expr_parts[expr_i + 1] if expr_i + 1 < len(expr_parts) else None

        at_slash = subpath != None and subpath.startswith("/")

        # Reached the end of the expression and path.
        if path_i >= len(path) and expr_i >= len(expr_parts):
            return True

        # Reached the end of the path on a final empty "*" or "**" expression
        if path_i >= len(path) and expr_i == len(expr_parts) - 1 and (subexpr == "*" or subexpr == "**"):
            return True

        if (subexpr == "*" and subpath != None and (match_path_separator or not at_slash)) or (subexpr == "**" and subpath != None):
            # A wildcard or globstar in the expression and something to consume.
            if next_subexpr == None and (match_path_separator or subpath.find("/") == -1):
                # This wildcard is the last and matches everything beyond here.
                return True

            # If the next part of the expression matches the current subpath
            # then advance past the wildcard and consume that next expression.
            if next_subexpr != None and subpath.startswith(next_subexpr):
                # Persist the alternative of using the wildcard instead of advancing.
                branches.append([expr_i, path_i + 1])
                expr_i = expr_i + 1
            else:
                # Otherwise consume the next character.
                path_i = path_i + 1

        elif subexpr == "*" and subpath != None and next_subexpr != None and subpath.startswith(next_subexpr):
            # A wildcard that has hit a path separator but we can branch
            # Persist the alternative of using the wildcard instead of advancing.
            branches.append([expr_i, path_i + 1])
            expr_i = expr_i + 1

        elif subexpr == "?" and subpath != None and (match_path_separator or not at_slash):
            # The string matches a ? wildcard at the current location in the path.
            expr_i = expr_i + 1
            path_i = path_i + 1

        elif subexpr and subpath != None and subpath.startswith(subexpr):
            # The string matches the current location in the path.
            expr_i = expr_i + 1
            path_i = path_i + len(subexpr)

        elif len(branches) > 0:
            # The string does not match, backup to the previous branch.
            [restored_pattern_i, restored_path_i] = branches.pop()

            path_i = restored_path_i
            expr_i = restored_pattern_i

        else:
            # The string does not match, with no branches to rollback to, there is no match.
            return False

    fail("glob_match: reached the end of the (in)finite loop")
