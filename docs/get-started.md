# Get started

Everything here is published to the [AUR](https://aur.archlinux.org/),
so installing a package is the same as installing any other AUR package.

## Install an AUR helper

Arch does not build AUR packages for you. `yay` does:

```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
```

Once it is installed you never need those steps again - `yay` builds
itself from then on.

## Install a package

```bash
yay -S <name>
```

`yay` fetches the `PKGBUILD`, shows it to you, builds it and hands the
result to pacman. Read the `PKGBUILD` when it offers: that is the point
of the AUR, and it is the only review these packages get from you.

## Keep them up to date

```bash
yay -Sua
```

Updates every AUR package on the system, this repository's included.
Plain `yay -Syu` does the repositories and the AUR in one pass.

## What is available

See [Packages](packages/index.md) for the list and what each one is for.

## Contributing one

If you want to add or change a package rather than install one, start at
[Authoring a package](authoring.md).
