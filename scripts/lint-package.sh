#!/usr/bin/env bash

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# Check every PKGBUILD in the tree, the template included.
#
# Four checks:
#   - the PKGBUILD and its scriptlets are valid bash (shellcheck)
#   - .SRCINFO matches what `makepkg --printsrcinfo` produces
#   - the committed sha256sums verify (`makepkg --verifysource`)
#   - namcap reports no errors
#
# (the list is indented past a leading `-` on purpose: a comment line
# whose first word is `shellcheck` is parsed as a shellcheck directive
# and fails the file)
#
# Each check degrades to a warning when its tool is missing, so this is
# still useful on a non-Arch workstation - it runs shellcheck and skips
# the three makepkg-dependent checks.
#
# Usage:
#   scripts/lint-package.sh                     # everything
#   scripts/lint-package.sh template            # just the template
#   scripts/lint-package.sh gpd-pocket-config   # one package
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/pkgdirs.sh
source "$ROOT/scripts/pkgdirs.sh"

# See the comment at the shellcheck call below for how this list was
# derived and why each code is on it.
PKGBUILD_EXCLUDE=SC2034,SC2154,SC2086,SC2164,SC2155,SC2206,SC2295

status=0
warn() { printf '  ~ %s\n' "$1"; }
fail() { printf '  x %s\n' "$1" >&2; status=1; }
pass() { printf '  + %s\n' "$1"; }

mapfile -t targets < <(pkgdirs "$ROOT" "$@")
if [[ ${#targets[@]} -eq 0 ]]; then
    echo "lint-package: no PKGBUILD found"
    exit 0
fi

for dir in "${targets[@]}"; do
    printf '\n%s\n' "${dir#"$ROOT"/}"

    if command -v shellcheck > /dev/null 2>&1; then
        # The PKGBUILD ruleset. Derived empirically by running the
        # linter against Arch's own official PKGBUILDs: every code below
        # fires on them, because each one is a deliberate PKGBUILD idiom
        # rather than a defect. (A comment line whose first word is the
        # linter's name is parsed as a directive, hence the phrasing.)
        #
        #   SC2034/SC2154  makepkg predefines srcdir, pkgdir and the whole
        #                  metadata namespace
        #   SC2206         `source=(... .tar.{xz,sign})` - brace expansion
        #                  in an array is the point
        #   SC2164         `cd $_srcname` - makepkg already runs under
        #                  `set -e`
        #   SC2086         word splitting of makepkg-provided flags
        #                  ($STRIP_SHARED and friends) is intended
        #   SC2155/SC2295  style, and universal in upstream PKGBUILDs
        #
        # The real gates for a PKGBUILD are makepkg and namcap, both of
        # which run below.
        if shellcheck --shell=bash --exclude="$PKGBUILD_EXCLUDE" "$dir/PKGBUILD"; then
            pass "shellcheck: PKGBUILD"
        else
            fail "shellcheck: PKGBUILD"
        fi
        for scriptlet in "$dir"/*.install "$dir"/*.sh; do
            [[ -e $scriptlet ]] || continue
            # .install files are sourced by pacman and carry no shebang.
            if shellcheck --shell=bash --exclude=SC2148 "$scriptlet"; then
                pass "shellcheck: $(basename "$scriptlet")"
            else
                fail "shellcheck: $(basename "$scriptlet")"
            fi
        done
    else
        warn "shellcheck not installed - skipped"
    fi

    if command -v makepkg > /dev/null 2>&1; then
        generated=$(cd "$dir" && makepkg --printsrcinfo)
        if diff -u --label "$dir/.SRCINFO" --label 'makepkg --printsrcinfo' \
               "$dir/.SRCINFO" <(printf '%s\n' "$generated"); then
            pass ".SRCINFO is up to date"
        else
            fail ".SRCINFO is stale - run scripts/srcinfo.sh"
        fi
        # --skippgpcheck: the upstream signing keys are not in a fresh
        # container's keyring, and every source is already pinned
        # byte-for-byte by its sha256sum. Without it this reports a
        # checksum failure for what is really a missing key.
        #
        # The output is not swallowed: a checksum mismatch names the file
        # that changed, and hiding it turns a two-second diagnosis into a
        # guess.
        if ( cd "$dir" && makepkg --verifysource --noconfirm --skippgpcheck ); then
            pass "sha256sums verify"
        else
            fail "sha256sums do not verify - run updpkgsums"
        fi
    else
        warn "makepkg not installed - .SRCINFO and checksum checks skipped"
    fi

    if command -v namcap > /dev/null 2>&1; then
        # namcap exits 0 even when it reports problems, so its output is
        # the signal. Only E: fails: many W: findings are advisory and
        # several are wrong for an arch=('any') config package.
        output=$(cd "$dir" && namcap PKGBUILD) || true
        [[ -n $output ]] && printf '%s\n' "$output"
        if printf '%s\n' "$output" | grep -q ' E: '; then
            fail "namcap reported errors"
        else
            pass "namcap: no errors"
        fi
    else
        warn "namcap not installed - skipped"
    fi
done

exit "$status"
