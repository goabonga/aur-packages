# Get started

## Requirements

An Arch machine — the GPD Pocket, or any Arch box — with the packaging
tooling:

```bash
sudo pacman -S --needed base-devel git namcap pacman-contrib uv shellcheck
```

`base-devel` provides `makepkg`, `pacman-contrib` provides `updpkgsums`,
and `uv` runs the documentation build.

Everything except `makepkg` also works off Arch: the helper scripts
degrade each unavailable check to a warning rather than a failure.

## Clone

```bash
git clone https://github.com/goabonga/aur-packages
cd aur-packages
```

## Add a package

```bash
scripts/new-package.sh gpd-pocket-config
```

That copies `template/` into `packages/gpd-pocket-config/`, renames the
payload files and rewrites the placeholder name throughout. Then replace
the payload and refresh the metadata:

```bash
cd packages/gpd-pocket-config
updpkgsums                  # the renamed files need new checksums
cd ../.. && scripts/srcinfo.sh gpd-pocket-config
```

## Check it

```bash
scripts/lint-package.sh gpd-pocket-config
```

shellcheck, `.SRCINFO` drift, checksum verification and namcap. With no
argument it checks every `PKGBUILD` in the tree, the template included.

## Build and install it

```bash
cd packages/gpd-pocket-config
makepkg -si
```

## Build the documentation

```bash
uv sync --frozen --only-group doc
uv run zensical serve
```
