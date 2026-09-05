<!-- Generated from packages/linux-hardened-usbgadget/README.md by scripts/gen-package-docs.py. Edit that file, not this one. -->

# linux-hardened-usbgadget

Arch's [`linux-hardened`](https://github.com/anthraxx/linux-hardened),
rebuilt with USB dual-role (OTG) and the gadget stack enabled, for the
GPD Pocket 1.

## Why

The Pocket 1's USB-C port is wired to the Cherry Trail SoC's DesignWare
USB3 controller, which is dual-role capable. Arch builds it host-only, so
the port can only ever act as a host: the machine can never present
itself as a serial console, a USB ethernet device or a mass-storage
device to another computer.

This package changes exactly one thing about `linux-hardened` — the
Kconfig fragment in `usbgadget.config` — and leaves the rest of Arch's
packaging alone.

## It installs alongside `linux-hardened`

Its modules live under its own `pkgbase`, so the stock kernel stays
installed and bootable. If this one fails to boot, pick the other entry
in your boot menu.

```bash
paru -S linux-hardened-usbgadget
```

Then add it to your bootloader and regenerate the initramfs as you would
for any extra kernel.

## What the fragment enables

| Area | Why |
| --- | --- |
| `USB_DWC3_DUAL_ROLE`, `USB_ROLE_SWITCH` | the controller's device side, which is what host-only builds omit |
| `EXTCON_INTEL_CHT_WC`, `TYPEC_FUSB302` | role and cable-orientation detection on Cherry Trail |
| `USB_GADGET`, `USB_LIBCOMPOSITE`, `USB_CONFIGFS` | the gadget core, configured at runtime through configfs |
| `USB_CONFIGFS_{ACM,ECM,RNDIS,NCM,MASS_STORAGE,F_HID,F_FS}` | the functions worth having: serial, ethernet both ways, storage, HID |

`prepare()` asserts the four load-bearing options survived
`make olddefconfig`, and fails the build otherwise — a renamed symbol
after a version bump would otherwise ship a kernel silently missing the
one feature this package exists for.

## Versioning

`pkgver` tracks the upstream `linux-hardened` release and `pkgrel` counts
packaging revisions. Both are maintained by hand: `pkgrel` has to remain
a positive integer, which a semantic version is not.

Bumping to a new upstream release means updating `pkgver`, the two
checksums and the pinned `config.x86_64` tag together — they all come
from the same Arch tag, so it is a mechanical rebase.

## Building it

A kernel build takes roughly an hour on the Pocket itself, and rather
less on a desktop:

```bash
cd packages/linux-hardened-usbgadget
makepkg -si
```
