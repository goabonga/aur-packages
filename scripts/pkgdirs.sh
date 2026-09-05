#!/usr/bin/env bash

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# Shared discovery: every directory in the repository that holds a
# PKGBUILD. Sourced by srcinfo.sh and lint-package.sh so both agree on
# what a target is.
#
# `template/` counts. It is not a package, but it is a PKGBUILD, and the
# same checks apply to it - a template that stopped producing valid
# metadata is exactly as broken as a package that did.

# Usage: pkgdirs [name...] -> prints one directory path per line.
# With no arguments, every PKGBUILD-bearing directory. With arguments,
# the named ones, resolved as packages/<name> or as a bare path.
pkgdirs() {
    local root=$1
    shift
    if [[ $# -gt 0 ]]; then
        local name
        for name in "$@"; do
            if [[ -f $root/packages/$name/PKGBUILD ]]; then
                printf '%s\n' "$root/packages/$name"
            elif [[ -f $root/$name/PKGBUILD ]]; then
                printf '%s\n' "$root/$name"
            else
                printf 'no PKGBUILD for target: %s\n' "$name" >&2
                return 1
            fi
        done
        return 0
    fi
    [[ -f $root/template/PKGBUILD ]] && printf '%s\n' "$root/template"
    if [[ -d $root/packages ]]; then
        local dir
        while IFS= read -r dir; do
            [[ -f $dir/PKGBUILD ]] && printf '%s\n' "$dir"
        done < <(find "$root/packages" -mindepth 1 -maxdepth 1 -type d | sort)
    fi
    return 0
}
