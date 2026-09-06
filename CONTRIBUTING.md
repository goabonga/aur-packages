# Contributing

This repository packages software for Arch Linux, so the conventions
below are Arch's as much as ours.

## Requirements

```bash
sudo pacman -S --needed base-devel git namcap pacman-contrib uv shellcheck
```

Everything except `makepkg` also works off Arch - the helper scripts
degrade each unavailable check to a warning - but a package cannot be
built or its `.SRCINFO` regenerated anywhere else.

## The one invariant

Four names are always the same string:

```
packages/<name>/   ·   pkgbase   ·   [components.<name>]   ·   the AUR repository
```

…and that string is also the **commit scope**. `pkgbase`, not `pkgname`:
a split package declares `pkgname=(a b)` and only `pkgbase` identifies
the source package.

## Adding a package

```bash
scripts/new-package.sh gpd-pocket-config
```

Then replace the payload and refresh the metadata:

```bash
cd packages/gpd-pocket-config && updpkgsums
cd ../.. && scripts/srcinfo.sh gpd-pocket-config
```

`template/` is not a package and does not live under `packages/`. Changes
to it are covered by the `template` CI job, which scaffolds a throwaway
package from it and builds it.

## Commit messages

Conventional Commits. **The scope is the package name** whenever the
change touches `packages/<name>/`:

```
feat(gpd-pocket-config): add a Wayland output profile for the rotated panel
fix(gpd-pocket-audio): install the UCM profile under the right card name
build(gpd-pocket-config): depend on xorg-xrandr instead of xrandr
```

### Valid scopes

Package names, and nothing else. Repository-level work takes **no
scope**: `ci: pin the archlinux container`, `build: add the sync hook`,
`docs: document the release contract`.

### Types

| Type | Effect on the scoped package |
| --- | --- |
| `feat` | minor |
| `fix`, `perf`, `revert` | patch |
| `build` | patch - packaging changed, payload did not |
| `docs` | bumps the documentation site only |
| `test`, `style`, `chore`, `refactor`, `ci` | no release |

`!` after the scope, or a `BREAKING CHANGE:` footer, makes it major.

`build` is the packaging-specific type: the same upstream content,
assembled differently. On Arch that is exactly what `pkgrel` is for.

### Rules

Keep commits **atomic**: one logical change each, refactoring separate
from behaviour, every commit leaving the repository working. Stage
explicitly (`git add <paths>`), never `git add -A`.

Do not add `Co-Authored-By` or tool-attribution trailers.

Merges must preserve commit messages - rebase or merge, never
squash-to-title, or multicz loses the types and scopes it releases from.

## Packaging rules

**`.SRCINFO` is generated.** `scripts/srcinfo.sh <name>`, never an
editor. The AUR reads it and it must agree with the `PKGBUILD` byte for
byte.

**Checksums are real.** `SKIP` is for VCS sources only; use `updpkgsums`.

**Scriptlets print, they do not mutate.** A `.install` runs as root on
every user's machine without confirmation.

**Install the licence** to `usr/share/licenses/<pkgname>/LICENSE`.

**`pkgrel` is a positive integer.** For a package that wraps upstream
software, `pkgver` tracks the upstream release and `pkgrel` counts
packaging revisions, resetting to `1` when `pkgver` moves. Both are
maintained by hand.

## Before opening a pull request

```bash
scripts/lint-package.sh                 # every PKGBUILD, template included
uv tool run multicz validate --strict
```

If you touched `scripts/`:

```bash
uv run --frozen --only-group dev ruff check scripts/
uv run --frozen --only-group dev ruff format --check scripts/
shellcheck -x scripts/*.sh
python3 scripts/add_license_header.py --path scripts --types py,sh --check
```

Every one of these runs in CI.

## Code of Conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
Security issues: follow [SECURITY.md](SECURITY.md).
