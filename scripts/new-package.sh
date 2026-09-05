#!/usr/bin/env bash

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# Create a package from the template.
#
# Copies template/ into packages/<name>/, renames the payload files and
# rewrites the placeholder name throughout. What it does NOT do is decide
# anything: the copy is mechanical, and everything package-specific is
# left for you to replace.
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

# Rename the payload files before rewriting contents, so the source=()
# entries and the install= line end up pointing at files that exist.
for f in "$TEMPLATE_NAME".*; do
    [[ -e $f ]] || continue
    mv "$f" "$name.${f#"$TEMPLATE_NAME".}"
done

# `-w` matters: without it, a name that is a prefix of another token gets
# mangled inside URLs and paths.
grep -rlZ "$TEMPLATE_NAME" . | xargs -0 -r sed -i "s/\b$TEMPLATE_NAME\b/$name/g"

cat <<EOF

new-package: packages/$name is ready.

Next, on an Arch machine:
  1. replace the payload in packages/$name/
  2. cd packages/$name
  3. updpkgsums                          # the renamed files need new sums
  4. makepkg --printsrcinfo > .SRCINFO
  5. makepkg -si
EOF
