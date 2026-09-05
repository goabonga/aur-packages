# The package template

The skeleton every package in this repository is copied from. Copy the
directory, rename it and its payload files, and replace `example-pkg`
throughout with the real package name.

It sits **outside any `packages/` directory** on purpose: a template is
not a package, and must never be versioned, tagged or published as one.
`example-pkg` is a placeholder, not something anyone installs.

## What it demonstrates

| Feature | Where |
| --- | --- |
| Local sources committed next to the `PKGBUILD` | `source=()` with real `sha256sums`, never `SKIP` |
| Config preserved across upgrades | `backup=('etc/example-pkg.conf')` |
| A scriptlet that only prints, never mutates | `example-pkg.install` |
| Licence where namcap expects it | `usr/share/licenses/example-pkg/LICENSE` |
| Architecture-independent payload | `arch=('any')` |

## Contents

```
template/
├── TEMPLATE.md          # this file - describes the template itself
├── PKGBUILD
├── .SRCINFO             # generated: makepkg --printsrcinfo > .SRCINFO
├── README.md            # becomes the new package's README
├── LICENSE              # installed by package()
├── example-pkg.install  # pacman scriptlet
├── example-pkg.sh       # payload -> /usr/bin/<name>
└── example-pkg.conf     # payload -> /etc/<name>.conf
```

## After copying it

On an Arch machine:

```bash
updpkgsums                          # the renamed files need new checksums
makepkg --printsrcinfo > .SRCINFO
makepkg -si
```
