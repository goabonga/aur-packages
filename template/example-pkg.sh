#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>
#
# Payload of the `example-pkg` template package. Real packages in this
# repository replace this with the script they actually ship - a display
# rotation helper, an ALSA UCM applier, a sensor quirk installer.
#
# It reads the packaged configuration from /etc so that the `backup=()`
# array in the PKGBUILD has something to protect: pacman then preserves
# local edits across upgrades instead of overwriting them.
set -euo pipefail

CONFIG=${EXAMPLE_PKG_CONFIG:-/etc/example-pkg.conf}

if [[ ! -r $CONFIG ]]; then
    printf 'example-pkg: configuration not found: %s\n' "$CONFIG" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG"

printf 'example-pkg: greeting=%s target=%s\n' "${GREETING:-unset}" "${TARGET:-unset}"
