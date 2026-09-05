#!/usr/bin/env python3

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

"""Enforce the one invariant the repository rests on.

For every package, four names have to be the same string::

    packages/<dir>/                 the directory
    pkgbase = <name>                in the PKGBUILD and the .SRCINFO
    [components.<name>]             in multicz.toml
    <name>                          the AUR repository

That is also the Conventional Commit scope, so it is the single input
that routes a bump to a package and, from there, to its AUR repository.
Break the chain anywhere and the failure is silent: the commit lands,
multicz reports nothing to bump, and the package quietly stops being
released.

``pkgbase`` rather than ``pkgname``: a split package - a kernel and its
headers, say - declares ``pkgname=(a b)``, and only ``pkgbase``
identifies the source package. For a single package makepkg defaults
``pkgbase`` to ``pkgname``, so the two coincide.
"""

from __future__ import annotations

import argparse
import re
import sys
import tomllib
from pathlib import Path

# Files the AUR and the release path assume exist. CHANGELOG.md is not
# among them: multicz creates it on the package's first release.
REQUIRED_FILES = ("PKGBUILD", ".SRCINFO", "README.md")

# Components tracked by multicz that own no packages/ directory.
NON_PACKAGE_COMPONENTS = frozenset({"docs"})

# Arch's own rule for a valid pkgname, enforced here so a name the AUR
# would refuse is caught at commit time rather than at push time.
PKGNAME_RE = re.compile(r"^[a-z0-9][a-z0-9@._+-]*$")


def _pkgbase(pkgbuild: Path) -> str | None:
    """The pkgbase of a PKGBUILD, explicit or defaulted from pkgname."""
    text = pkgbuild.read_text(encoding="utf-8")
    explicit = re.search(
        r"""^pkgbase=(?:["']?)([^"'\s#()]+)(?:["']?)\s*$""", text, re.MULTILINE
    )
    if explicit:
        return explicit.group(1)
    # A scalar pkgname doubles as the pkgbase. An array without an
    # explicit pkgbase is invalid, so it is reported as missing.
    scalar = re.search(
        r"""^pkgname=(?:["']?)([^"'\s#()]+)(?:["']?)\s*$""", text, re.MULTILINE
    )
    return scalar.group(1) if scalar else None


def _srcinfo_pkgbase(srcinfo: Path) -> str | None:
    match = re.search(
        r"^pkgbase = (.+)$", srcinfo.read_text(encoding="utf-8"), re.MULTILINE
    )
    return match.group(1).strip() if match else None


def check(root: Path) -> list[str]:
    errors: list[str] = []

    config_path = root / "multicz.toml"
    if not config_path.is_file():
        return [f"{config_path} is missing"]
    config = tomllib.loads(config_path.read_text(encoding="utf-8"))
    components: dict[str, dict] = config.get("components", {})

    packages_dir = root / "packages"
    dirs = (
        sorted(p.name for p in packages_dir.iterdir() if p.is_dir())
        if packages_dir.is_dir()
        else []
    )

    declared = {name for name in components if name not in NON_PACKAGE_COMPONENTS}
    for name in sorted(declared - set(dirs)):
        errors.append(
            f"multicz.toml declares [components.{name}] but packages/{name}/ "
            f"does not exist"
        )
    for name in sorted(set(dirs) - declared):
        errors.append(
            f"packages/{name}/ exists but multicz.toml has no "
            f"[components.{name}] - it would never be versioned or published"
        )

    for name in dirs:
        pkg_dir = packages_dir / name

        if not PKGNAME_RE.match(name):
            errors.append(
                f"packages/{name}/: not a valid pkgname - Arch allows lowercase "
                f"alphanumerics plus @ . _ + - and no leading hyphen or dot"
            )

        for filename in REQUIRED_FILES:
            if not (pkg_dir / filename).is_file():
                errors.append(f"packages/{name}/{filename} is missing")

        pkgbuild = pkg_dir / "PKGBUILD"
        if pkgbuild.is_file():
            base = _pkgbase(pkgbuild)
            if base is None:
                errors.append(
                    f"packages/{name}/PKGBUILD: no pkgbase, and no scalar "
                    f"pkgname to default it from (a split package must set "
                    f"pkgbase explicitly)"
                )
            elif base != name:
                errors.append(
                    f"packages/{name}/PKGBUILD: pkgbase={base} does not match "
                    f"the directory name {name}"
                )

        srcinfo = pkg_dir / ".SRCINFO"
        if srcinfo.is_file():
            base = _srcinfo_pkgbase(srcinfo)
            if base is None:
                errors.append(f"packages/{name}/.SRCINFO: no pkgbase line")
            elif base != name:
                errors.append(
                    f"packages/{name}/.SRCINFO: pkgbase = {base} does not match "
                    f"the directory name {name} (run scripts/srcinfo.sh {name})"
                )

        component = components.get(name)
        if component is None:
            continue

        prefix = f"packages/{name}/"
        for path in component.get("paths", []):
            if not path.startswith(prefix):
                errors.append(
                    f"[components.{name}] paths entry {path!r} escapes {prefix} - "
                    f"component paths must stay disjoint or one edit bumps two "
                    f"packages"
                )

        changelog = component.get("changelog")
        if changelog != f"{prefix}CHANGELOG.md":
            errors.append(
                f"[components.{name}] changelog is {changelog!r}, expected "
                f"'{prefix}CHANGELOG.md'"
            )

        # bump_files is optional: a package whose pkgver tracks upstream
        # leaves both version numbers to the maintainer. When it is set,
        # it has to write the PKGBUILD - anywhere else and the released
        # version never reaches the package.
        targets = {entry.get("file") for entry in component.get("bump_files", [])}
        if targets and f"{prefix}PKGBUILD" not in targets:
            errors.append(
                f"[components.{name}] bump_files does not write {prefix}PKGBUILD"
            )

    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="repository root (default: the parent of scripts/)",
    )
    args = parser.parse_args(argv)

    errors = check(args.root)
    if errors:
        print("check-packages: FAIL", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print("check-packages: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
