<h1 align="center">
  <img src="docs/aur-packages.svg" alt="aur-packages" width="120" /><br/>
  aur-packages
</h1>

<p align="center">
  <em>The AUR packages I run on my Arch Linux GPD Pocket 1.</em>
</p>

## Add a package

```bash
scripts/new-package.sh gpd-pocket-config
```

Copies `template/` into `packages/gpd-pocket-config/`, renames the payload
files and rewrites the placeholder name throughout. Everything
package-specific is left for you to replace.

`template/` deliberately sits outside `packages/`: a template is not a
package and must never be versioned, tagged or published as one.

## Check a package

```bash
scripts/lint-package.sh              # every PKGBUILD, template included
scripts/lint-package.sh <name>       # one of them
scripts/srcinfo.sh <name>            # regenerate its .SRCINFO
```

`lint-package.sh` runs shellcheck, diffs `.SRCINFO` against
`makepkg --printsrcinfo`, verifies the committed checksums and runs
namcap. Each check degrades to a warning when its tool is missing, so it
is still useful off Arch.

## Branding

`assets/aur-packages.svg` is the master logo. Regenerate the derived
assets after editing it:

```bash
scripts/regen-icons.sh   # -> docs/aur-packages.svg, docs/favicon.ico
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow, the commit
convention and the packaging rules. By participating you agree to the
[Code of Conduct](CODE_OF_CONDUCT.md).

Security issues: follow the process in [SECURITY.md](SECURITY.md).

## License

Distributed under the [MIT License](LICENSE).
