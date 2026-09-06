#!/usr/bin/env bash

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# Create a package from the template.
#
# Adding a package touches four places, and forgetting any one of them
# fails silently: the package is never checked, never versioned, never
# published, or never documented. So this does all four:
#
#   1. packages/<name>/          copied from template/, renamed
#   2. multicz.toml              [components.<name>] + docs depends_on
#   3. zensical.toml             nav entry under Packages
#   4. docs/packages/<name>.md   generated from the new README
#
# Everything package-specific is still left for you to replace.
#
# Usage: scripts/new-package.sh gpd-pocket-config
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# The template lives outside packages/ because it is not a package.
TEMPLATE_DIR=$ROOT/template
# The placeholder package name used throughout the template files. Every
# whole-word occurrence of it is rewritten to the new name.
TEMPLATE_NAME=example-pkg

if [[ $# -ne 1 ]]; then
    printf 'usage: %s <pkgname>\n' "$(basename "$0")" >&2
    exit 2
fi
name=$1

# Arch's own pkgname rule. Rejecting here means an invalid name cannot
# reach the AUR and be refused there.
if [[ ! $name =~ ^[a-z0-9][a-z0-9@._+-]*$ ]]; then
    printf 'new-package: %s is not a valid pkgname (lowercase alphanumerics plus @ . _ + -, no leading hyphen or dot)\n' "$name" >&2
    exit 1
fi
if [[ -e $ROOT/packages/$name ]]; then
    printf 'new-package: packages/%s already exists\n' "$name" >&2
    exit 1
fi
if [[ ! -d $TEMPLATE_DIR ]]; then
    printf 'new-package: missing template directory %s\n' "$TEMPLATE_DIR" >&2
    exit 1
fi

mkdir -p "$ROOT/packages"
cp -r "$TEMPLATE_DIR" "$ROOT/packages/$name"
cd "$ROOT/packages/$name"

# TEMPLATE.md documents the template itself, not the package made from it.
# `rm -f` rather than a selective copy: a new file added to the template
# should reach the package by default.
rm -f TEMPLATE.md

# makepkg leaves its work behind in the directory it builds in, and those
# are gitignored - so `cp -r` above happily copies a stale build tree into
# the new package while `git status` stays silent about it.
rm -rf src pkg
rm -f ./*.pkg.tar.zst ./*.pkg.tar.zst.sig ./*.log

# Rename the payload files before rewriting contents, so the source=()
# entries and the install= line end up pointing at files that exist.
for f in "$TEMPLATE_NAME".*; do
    [[ -e $f ]] || continue
    mv "$f" "$name.${f#"$TEMPLATE_NAME".}"
done

# `-w` matters: without it, a name that is a prefix of another token gets
# mangled inside URLs and paths.
grep -rlZ "$TEMPLATE_NAME" . | xargs -0 -r sed -i "s/\b$TEMPLATE_NAME\b/$name/g"

# The steps below edit repository-level files, so leave the package
# directory the copy left us in.
cd "$ROOT"

# --- 2. multicz.toml -------------------------------------------------------
# The component is written in the "package owns its content" shape, which
# is what the template is: multicz writes pkgver, and pkgbuild-sync
# resets pkgrel and syncs .SRCINFO after it. A package that wraps
# upstream software drops the bump_files and post_bump lines by hand -
# see docs/releasing.md.
python3 - "$name" <<'PY'
import re
import sys
from pathlib import Path

name = sys.argv[1]
config = Path("multicz.toml")
text = config.read_text(encoding="utf-8")

block = f"""[components.{name}]
paths = ["packages/{name}/**"]
bump_files = [
    {{ file = "packages/{name}/PKGBUILD", key = "regex:^pkgver=([^\\\\s#]+)" }},
]
changelog = "packages/{name}/CHANGELOG.md"
post_bump = ["python3 scripts/pkgbuild-sync.py packages/{name}"]

"""

marker = "# The Zensical site is a release-tracked component"
if marker not in text:
    sys.exit("new-package: could not find the docs component in multicz.toml")
text = text.replace(marker, block + marker, 1)


def add_dependency(match):
    existing = re.findall(r'"([^"]+)"', match.group(1))
    if name not in existing:
        existing.append(name)
    return "depends_on = [" + ", ".join(f'"{d}"' for d in sorted(existing)) + "]"


text, count = re.subn(r"depends_on = \[([^\]]*)\]", add_dependency, text)
if count < 1:
    # No list yet - this is the first package. Create it on the docs
    # component, immediately above its bump_rules line.
    anchor = 'bump_rules = { docs = "patch" }'
    if anchor not in text:
        sys.exit("new-package: could not find the docs component in multicz.toml")
    text = text.replace(anchor, f'depends_on = ["{name}"]\n{anchor}', 1)

config.write_text(text, encoding="utf-8")
print(f"new-package: multicz.toml <- [components.{name}]")
PY

# --- 3. zensical.toml nav --------------------------------------------------
python3 - "$name" <<'PY'
import sys
from pathlib import Path

name = sys.argv[1]
config = Path("zensical.toml")
text = config.read_text(encoding="utf-8")

anchor = '      { "Overview" = "packages/index.md" },\n'
entry = f'      {{ "{name}" = "packages/{name}.md" }},\n'
if entry in text:
    print(f"new-package: zensical.toml nav already lists {name}")
elif anchor not in text:
    sys.exit("new-package: could not find the Packages nav section in zensical.toml")
else:
    head, _, tail = text.partition(anchor)
    lines = tail.split("\n")
    end = next(i for i, line in enumerate(lines) if line.strip() == "] },")
    merged = sorted(
        [ln for ln in lines[:end] if ln.strip()] + [entry.rstrip("\n")],
        key=lambda s: s.split('"')[1],
    )
    config.write_text(head + anchor + "\n".join(merged + lines[end:]), encoding="utf-8")
    print(f"new-package: zensical.toml nav <- {name}")
PY

# --- 4. generated docs page, then re-verify the whole tree -----------------
python3 "$ROOT/scripts/gen-package-docs.py"
python3 "$ROOT/scripts/check-packages.py"
uv tool run multicz validate --strict

cat <<EOF

new-package: packages/$name is ready.

Next, on an Arch machine:
  1. replace the payload in packages/$name/
  2. cd packages/$name && updpkgsums     # the renamed files need new sums
  3. scripts/srcinfo.sh $name
  4. scripts/lint-package.sh $name
  5. git add packages/$name multicz.toml zensical.toml docs/packages/$name.md
     git commit -m "feat($name): <what it does>"
EOF
