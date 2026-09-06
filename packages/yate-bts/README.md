# yate-bts

[YateBTS](https://yatebts.com/) - an open source GSM base station,
running on top of the Yate telephony engine.

Imported from [the AUR package](https://aur.archlinux.org/packages/yate-bts)
and brought back to life.

## Install

```bash
yay -S yate-bts
```

Or build it from this repository:

```bash
cd packages/yate-bts
makepkg -si
```

It builds against `yate`, which is in Arch's `extra` repository.

## Configuration

Four files under `/etc/yate/` are listed in `backup=()`, so pacman keeps
your edits across upgrades and leaves the new versions as `.pacnew`:

- `ybts.conf` - the radio and network configuration
- `subscribers.conf` - the subscriber database
- `snmp_data.conf`, `tmsidata.conf` - runtime state, created empty
