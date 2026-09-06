# Authoring a package

Everything below is for changing what this repository ships. If you only
want to install a package, [Get started](get-started.md) is shorter.

## Set up

```bash
sudo pacman -S --needed base-devel git namcap pacman-contrib uv shellcheck
git clone https://github.com/goabonga/aur-packages
cd aur-packages
```

`base-devel` provides `makepkg`, `pacman-contrib` provides `updpkgsums`,
and `uv` runs the documentation build.

Everything except `makepkg` also works off Arch: the helper scripts
degrade each unavailable check to a warning rather than a failure.

Optionally, let the hooks run the checks for you:

```bash
uv run --only-group dev pre-commit install
```

## The one invariant

Four names are always the same string:

```
packages/<name>/          the directory
pkgbase = <name>          in the PKGBUILD and the .SRCINFO
[components.<name>]       in multicz.toml
<name>                    the AUR repository
```

…and that string is also the **Conventional Commit scope**.

`pkgbase`, not `pkgname`: a split package - a kernel and its headers, say
- declares `pkgname=(a b)`, and only `pkgbase` identifies the source
package. For a single package `pkgbase` defaults to `pkgname`, so the two
coincide.

## Create it

```bash
scripts/new-package.sh gpd-pocket-config
```

Then replace the payload, and:

```bash
cd packages/gpd-pocket-config
updpkgsums
cd ../.. && scripts/srcinfo.sh gpd-pocket-config
```

## Rules

### `.SRCINFO` is generated, never hand-edited

The AUR reads it to build the package page and resolve dependencies, and
it must agree with the `PKGBUILD` byte for byte. `scripts/srcinfo.sh`
wraps the only correct generator, `makepkg --printsrcinfo`.

### Checksums are real

`sha256sums=('SKIP')` is for VCS sources only. Files committed next to
the `PKGBUILD` get real checksums from `updpkgsums`.

### Scriptlets print, they do not mutate

A `.install` file runs as root on every user's machine with no
confirmation. Use it to tell people what to do next. Anything that
changes system state belongs in a systemd unit the user enables.

### Licences are installed

`usr/share/licenses/<pkgname>/LICENSE`, or namcap complains - unless the
licence is one of the common ones already in
`/usr/share/licenses/common`, which namcap will tell you.

## Choosing `arch`

`arch=('any')` for pure configuration, scripts and data. `arch=('x86_64')`
for anything compiled: that is the only architecture built here, since
the machine these packages are installed on is x86_64.

## Two versioning shapes

**The package owns its content** - a configuration package, a set of
quirks, a script you wrote. `pkgver` is the repository's own semver.

**The package wraps upstream software** - a kernel, a patched build of
someone else's release. `pkgver` must track the upstream version and
`pkgrel` counts packaging revisions, resetting to `1` whenever `pkgver`
moves. Both are maintained by hand: `pkgrel` has to stay a positive
integer, which a semantic version is not.

## Checking your work

```bash
scripts/lint-package.sh <name>              # shellcheck, .SRCINFO, sums, namcap
python3 scripts/check-packages.py           # the invariant
uv tool run multicz validate --strict       # config and version drift
cd packages/<name> && makepkg -f && namcap ./*.pkg.tar.zst
```

With no argument, `lint-package.sh` checks every `PKGBUILD` in the tree,
the template included. All of it runs in CI too.

## Building the documentation

```bash
uv sync --frozen --only-group doc
uv run zensical serve
```
