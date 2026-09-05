#!/usr/bin/env bash

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# Regenerate .SRCINFO with the authoritative generator.
#
# The AUR reads .SRCINFO to populate the package page and resolve
# dependencies, and it has to agree with the PKGBUILD byte for byte. Only
# `makepkg --printsrcinfo` produces it correctly - field order, array
# expansion and architecture-suffixed sources are makepkg's business, not
# something to reproduce by hand.
#
# Requires Arch, or an archlinux container.
#
# Usage:
#   scripts/srcinfo.sh                     # every PKGBUILD in the tree
#   scripts/srcinfo.sh template            # just the template
#   scripts/srcinfo.sh gpd-pocket-config   # one package
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/pkgdirs.sh
source "$ROOT/scripts/pkgdirs.sh"

if ! command -v makepkg > /dev/null 2>&1; then
    cat >&2 <<'MSG'
srcinfo: makepkg not found.

.SRCINFO can only be generated on Arch. On another machine, run it in a
container:

    podman run --rm -v "$PWD:/repo" -w /repo archlinux:base-devel \
        bash -c 'useradd -m b && chown -R b . && su b -c "scripts/srcinfo.sh"'
MSG
    exit 1
fi

mapfile -t targets < <(pkgdirs "$ROOT" "$@")
if [[ ${#targets[@]} -eq 0 ]]; then
    echo "srcinfo: no PKGBUILD found"
    exit 0
fi

for dir in "${targets[@]}"; do
    ( cd "$dir" && makepkg --printsrcinfo > .SRCINFO )
    printf 'srcinfo: regenerated %s/.SRCINFO\n' "${dir#"$ROOT"/}"
done
