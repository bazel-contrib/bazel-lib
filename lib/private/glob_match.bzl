"""
Basic glob match implementation for starlark.

This was originally developed by @jbedard for use in rules_js
(https://github.com/aspect-build/rules_js/blob/6ca32d5199ddc0bf19bd704f591030dc1468ca5f/npm/private/pkg_glob.bzl)
to support the pnpm public-hoist-expr option (https://pnpm.io/npmrc#public-hoist-expr). The pnpm
implementation and tests were used as a reference implementation:
    https://github.com/pnpm/pnpm/blob/v7.4.0-2/packages/matcher/src/index.ts
    https://github.com/pnpm/pnpm/blob/v7.4.0-2/packages/matcher/test/index.ts
"""

def _split_on(expr, splits):
    # Splits an expression on the tokens in splits but keeps the tokens split in the result.
    # Tokens are matched in order so a token such as `**` should come before `*`.
    result = []
    accumulator = ""
    skip = 0
    for i in range(len(expr)):
        j = i + skip
        if j >= len(expr):
            break
        for split in splits:
            if not split:
                fail("empty split token")
            if expr[j:].startswith(split):
                if accumulator:
                    result.append(accumulator)
                    accumulator = ""
                result.append(split)
                skip = skip + len(split)
                j = i + skip
                break
        if j >= len(expr):
            break
        accumulator = accumulator + expr[j]
    if accumulator:
        result.append(accumulator)
    return result

GLOB_SYMBOLS = ["**", "*", "?"]

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

    expr_i = 0
    path_i = 0

    if expr.find("***") != -1:
        fail("glob_match: invalid *** pattern found in glob expression")

    expr_parts = _split_on(expr, GLOB_SYMBOLS[:])

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

    # Loop "forever" (2^30).
    for _ in range(1073741824):
        subpath = path[path_i:] if path_i < len(path) else None
        subexpr = expr_parts[expr_i] if expr_i < len(expr_parts) else None

        # The next part of the expression.
        next_pp = expr_parts[expr_i + 1] if expr_i + 1 < len(expr_parts) else None

        stop_at_leading_path_separator = not match_path_separator and subpath != None and subpath.startswith("/")
        stop_at_contained_path_separator = not match_path_separator and subpath != None and subpath.find("/") != -1

        if (subexpr == "*" and subpath != None and not stop_at_leading_path_separator) or (subexpr == "**" and subpath != None):
            # A wildcard or globstar in the expression and something to consume.
            if next_pp == None and not stop_at_contained_path_separator:
                # This wildcard is the last and matches everything beyond here.
                return True

            # If the next part of the expression matches the current subpath
            # then advance past the wildcard and consume that next expression.
            if next_pp != None and subpath.startswith(next_pp):
                # Persist the alternative of using the wildcard instead of advancing.
                branches.append([expr_i, path_i + 1])
                expr_i = expr_i + 1
            else:
                # Otherwise consume the next character.
                path_i = path_i + 1

        elif subexpr == "*" and subpath != None and stop_at_leading_path_separator and next_pp != None and subpath.startswith(next_pp):
            # A wildcard that has hit a path separator but we can branch
            # Persist the alternative of using the wildcard instead of advancing.
            branches.append([expr_i, path_i + 1])
            expr_i = expr_i + 1

        elif subexpr == "?" and subpath != None and not stop_at_leading_path_separator:
            # The string matches a ? wildcard at the current location in the path.
            expr_i = expr_i + 1
            path_i = path_i + 1

        elif subexpr and subpath != None and subpath.startswith(subexpr):
            # The string matches the current location in the path.
            expr_i = expr_i + 1
            path_i = path_i + len(subexpr)

        elif subpath == None and expr_i == len(expr_parts) - 1 and (subexpr == "*" or subexpr == "**"):
            # Reached the package on a final empty "*" or "**" expression
            return True

        elif len(branches) > 0:
            # The string does not match, backup to the previous branch.
            [restored_pattern_i, restored_path_i] = branches.pop()

            path_i = restored_path_i
            expr_i = restored_pattern_i

        else:
            # The string does not match, with no branches to rollback to, there is no match.
            return False

        if path_i == len(path) and expr_i == len(expr_parts):
            # Reached the end of the expression and package.
            return True

    fail("glob_match: reached the end of the (in)finite loop")
