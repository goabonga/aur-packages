# Packages

| Package | AUR | What it is |
| --- | --- | --- |
| [`linux-hardened-usbgadget`](linux-hardened-usbgadget.md) | [AUR](https://aur.archlinux.org/packages/linux-hardened-usbgadget) | `linux-hardened` rebuilt with USB dual-role (OTG) and the gadget stack |

The per-package pages are generated from each `packages/<name>/README.md`
by `scripts/gen-package-docs.py`; edit the README, not the generated
page.

## Installing

```bash
paru -S <name>
```

Or build from this repository:

```bash
cd packages/<name> && makepkg -si
```
