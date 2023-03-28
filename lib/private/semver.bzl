"Implementation for semantic versioning utilities"

def _invalid_semver(version):
    fail("Invalid semver: %s" % version)

def _parse(version):
    """Parse a semver string into a struct containing info about the semver.

    E.g.
    ```
    sv = semver.parse("v1.2.3-alpha1+1234")

    sv.major # "1"
    sv.minor # "2"
    sv.patch # "3"
    sv.prerelease # True
    sv.identifiers # "alpha1"
    sv.build_metadata # "1234"
    sv.v # True (whether prefixed with "v")

    ```

    Args:
        version: Semver string

    Returns:
        Semver struct
    """
    if type(version) != "string":
        _invalid_semver(version)

    v = False
    if version.startswith("v"):
        v = True
        version = version[1:]

    components = version.split(".", 2)
    if len(components) != 3:
        _invalid_semver(version)

    major = components[0]
    if not major.isdigit():
        _invalid_semver(version)

    minor = components[1]
    if not minor.isdigit():
        _invalid_semver(version)

    patch = components[2]
    identifiers = None
    build_metadata = None
    dash_index = patch.find("-")
    plus_index = patch.find("+")
    prerelease = dash_index != -1
    has_build_metadata = plus_index != -1

    patch_version = patch
    if prerelease:
        patch_version = patch[0:dash_index]
    elif has_build_metadata:
        patch_version = patch[0:plus_index]

    if not patch_version.isdigit():
        _invalid_semver(version)

    if prerelease:
        if not has_build_metadata:
            identifiers = patch[dash_index + 1:]
        else:
            identifiers = patch[dash_index + 1:plus_index]

        for identifier in identifiers.split("."):
            _validate_identifier(identifier, version)

    if has_build_metadata:
        build_metadata = patch[plus_index + 1:]
        for identifier in build_metadata.split("."):
            _validate_identifier(identifier, version)

    return struct(
        v = v,
        major = major,
        minor = minor,
        patch = patch_version,
        prerelease = prerelease,
        identifiers = identifiers,
        build_metadata = build_metadata,
    )

def _validate_identifier(identifier, version):
    # Identifiers may not be empty
    if len(identifier) == 0:
        _invalid_semver(version)

    # Identifiers may not start with leading 0
    if identifier.startswith("0"):
        _invalid_semver(version)

    # Identifiers must be comprised of alphanumeric chars or dashes
    if not identifier.replace("-", "").isalnum():
        _invalid_semver(version)

def _key(semver):
    values = [semver.major, semver.minor, semver.patch, not semver.prerelease]
    if semver.prerelease:
        values.extend([semver.identifiers.split(".")])
    return tuple(values)

def _sort(semvers):
    """Sort a list of semver structs in order of precedence.

    Precedence is defined by the semver spec: https://semver.org/.

    Args:
        semvers: List of semver structs

    Returns:
        List of semvers sorted in order of precedence.
    """
    return sorted(
        semvers,
        key = _key,
    )

def _to_str(semver):
    """Convert a semver struct to a string.

    Args:
        semver: Semver struct

    Returns:
        The semver in string form.
    """
    return "{maybe_v}{major}.{minor}.{patch}{maybe_identifiers}{maybe_build_metadata}".format(
        maybe_v = "v" if semver.v else "",
        major = semver.major,
        minor = semver.minor,
        patch = semver.patch,
        maybe_identifiers = "-%s" % semver.identifiers if semver.identifiers else "",
        maybe_build_metadata = "+%s" % semver.build_metadata if semver.build_metadata else "",
    )

def make(major, minor, patch, identifiers = None, build_metadata = None, v = False):
    return struct(
        v = v,
        major = major,
        minor = minor,
        patch = patch,
        prerelease = identifiers != None,
        identifiers = identifiers,
        build_metadata = build_metadata,
    )

semver = struct(
    parse = _parse,
    sort = _sort,
    to_str = _to_str,
)
