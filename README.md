# aur-packages

The AUR packages I run on my Arch Linux GPD Pocket 1.

## Add a package

```bash
scripts/new-package.sh gpd-pocket-config
```

Copies `template/` into `packages/gpd-pocket-config/`, renames the payload
files and rewrites the placeholder name throughout. Everything
package-specific is left for you to replace.

`template/` deliberately sits outside `packages/`: a template is not a
package and must never be versioned, tagged or published as one.

## License

Distributed under the [MIT License](LICENSE).
