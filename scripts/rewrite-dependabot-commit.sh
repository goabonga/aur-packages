#!/usr/bin/env bash

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# Re-author and GPG-sign a Dependabot commit, normalising its subject to
# a Conventional Commit this repository's rules accept.
#
# The shared version of this script sorts bumps into `fix(deps)` for
# runtime dependencies and `chore(deps)` for tooling, because a runtime
# bump ships to users and therefore earns a patch release. Here nothing
# does: the repository publishes PKGBUILDs, and every Python dependency
# belongs to a tooling group (`dev`, `doc`, `favicon`) that exists only
# to lint the scripts or build the site. So the classification is simply:
#
#   .github/workflows/*  -> ci
#   everything else      -> chore(deps)
#
# Neither type is in `[project.bump_rules]`, which is correct - a
# Zensical or ruff bump changes no package, and must not push anything
# to the AUR.
#
# Run by `git rebase --exec` in .github/workflows/dependabot-rewrite.yml.

set -euo pipefail

changed=$(git show --name-only --pretty='' HEAD)
subject=$(git log -1 --pretty=%s HEAD)
# Dependabot signs its commits as a co-author; this repository forbids
# that trailer, so it is stripped rather than carried through.
body=$(git log -1 --pretty=%b HEAD | sed '/^[Cc]o-authored-by:/d')

# Drop any leading conventional prefix Dependabot already added, so the
# subject is not double-prefixed, then lowercase the first letter:
# Dependabot writes "Bump x from ...", and this repository's convention
# is a lowercase imperative description.
text=$(printf '%s' "$subject" | sed -E 's/^[a-z]+(\([^)]+\))?!?:[[:space:]]*//')
text=$(printf '%s' "$text" | sed -E 's/^(.)/\L\1/')

if printf '%s' "$changed" | grep -q '[.]github/workflows/'; then
    prefix="ci"
else
    prefix="chore(deps)"
fi

if [ -n "$body" ]; then
    new_msg=$(printf '%s: %s\n\n%s' "$prefix" "$text" "$body")
else
    new_msg=$(printf '%s: %s' "$prefix" "$text")
fi

git commit --amend --reset-author -m "$new_msg" --quiet
