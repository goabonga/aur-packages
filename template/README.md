# example-pkg

<!--
  This file becomes the new package's README. Write it as such, not as
  documentation of the template, and replace the description below with
  what the package actually does.
-->

One-line description of what this package installs and why.

## Contents

| Path | What it is |
| --- | --- |
| `/usr/bin/example-pkg` | the payload |
| `/etc/example-pkg.conf` | configuration, listed in `backup=()` so pacman keeps your edits |

## Build and install

```bash
cd packages/example-pkg
makepkg -si
```

## Working on it

```bash
updpkgsums                          # after editing any source file
makepkg --printsrcinfo > .SRCINFO
```

`.SRCINFO` is generated, never hand-edited: the AUR reads it and it has
to agree with the `PKGBUILD` byte for byte.
