#!/usr/bin/env python3

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

"""Render ``docs/packages/<name>.md`` from each ``packages/<name>/README.md``.

A package's README is what someone reads on GitHub, in the AUR tarball and
on the documentation site. Keeping three copies in sync by hand is how two
of them go stale, so the README is the single source and this script
projects it into the site.

The projection is not a copy: relative links that made sense from inside
``packages/<name>/`` are rewritten to resolve from ``docs/packages/``, and
a banner is prepended so nobody edits the generated file.

``--check`` compares without writing and exits non-zero on drift, which is
what the ``consistency`` CI job runs.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

BANNER = (
    "<!-- Generated from packages/{name}/README.md by "
    "scripts/gen-package-docs.py. Edit that file, not this one. -->\n\n"
)

# Links written relative to packages/<name>/ that have to be re-pointed
# once the text is rendered from docs/packages/. `../../scripts/x` means
# the repository root, which on the site is only reachable as a GitHub
# URL; the rest resolve inside the site.
REPO_BLOB = "https://github.com/goabonga/aur-packages/blob/main"


def render(package_dir: Path) -> str:
    name = package_dir.name
    body = (package_dir / "README.md").read_text(encoding="utf-8")

    # `](../../CONTRIBUTING.md)` and friends: anything climbing out of
    # packages/<name>/ points at a repository file, not a site page.
    body = re.sub(
        r"\]\(\.\./\.\./([^)]+)\)",
        rf"]({REPO_BLOB}/\1)",
        body,
    )
    # `](../other-pkg/...)` -> the sibling package's generated page.
    body = re.sub(r"\]\(\.\./([a-z0-9@._+-]+)/README\.md\)", r"](\1.md)", body)
    # Files inside the package directory itself.
    body = re.sub(
        r"\]\((?!https?:|mailto:|#|\.\./)([^)]+)\)",
        rf"]({REPO_BLOB}/packages/{name}/\1)",
        body,
    )

    return BANNER.format(name=name) + body


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="repository root (default: the parent of scripts/)",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="do not write; exit non-zero if any generated page is stale",
    )
    args = parser.parse_args(argv)

    packages = args.root / "packages"
    out_dir = args.root / "docs" / "packages"
    out_dir.mkdir(parents=True, exist_ok=True)

    stale: list[str] = []
    written: list[str] = []
    generated: set[str] = set()

    package_dirs = (
        sorted(p for p in packages.iterdir() if p.is_dir()) if packages.is_dir() else []
    )
    for package_dir in package_dirs:
        readme = package_dir / "README.md"
        if not readme.is_file():
            print(
                f"gen-package-docs: {package_dir.name} has no README.md",
                file=sys.stderr,
            )
            return 1

        target = out_dir / f"{package_dir.name}.md"
        generated.add(target.name)
        content = render(package_dir)

        current = target.read_text(encoding="utf-8") if target.is_file() else None
        if current == content:
            continue
        if args.check:
            stale.append(str(target.relative_to(args.root)))
        else:
            target.write_text(content, encoding="utf-8")
            written.append(str(target.relative_to(args.root)))

    # A page left behind by a package that was removed would keep showing
    # up in the site and in the nav; report it rather than deleting a file
    # nobody asked this script to own.
    orphans = sorted(
        p.name
        for p in out_dir.glob("*.md")
        if p.name != "index.md" and p.name not in generated
    )
    for orphan in orphans:
        print(
            f"gen-package-docs: docs/packages/{orphan} has no matching package "
            f"- delete it and drop its nav entry from zensical.toml",
            file=sys.stderr,
        )

    if args.check and (stale or orphans):
        for path in stale:
            print(f"gen-package-docs: {path} is out of date", file=sys.stderr)
        print(
            "gen-package-docs: FAIL - run `python3 scripts/gen-package-docs.py`",
            file=sys.stderr,
        )
        return 1
    if orphans:
        return 1

    if args.check:
        print("gen-package-docs: OK - every package page is up to date")
    else:
        print(
            f"gen-package-docs: {len(written)} page(s) written"
            + (f": {', '.join(written)}" if written else "")
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
