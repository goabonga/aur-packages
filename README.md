<h1 align="center">
  <img src="docs/aur-packages.svg" alt="aur-packages" width="120" /><br/>
  aur-packages
</h1>

<p align="center">
  <em>The AUR packages I run on my Arch Linux GPD Pocket 1.</em>
</p>

<p align="center">
  <a href="https://github.com/goabonga/aur-packages/actions/workflows/ci.yml"><img src="https://github.com/goabonga/aur-packages/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI"/></a>
  <a href="https://goabonga.github.io/aur-packages/"><img src="https://img.shields.io/badge/docs-zensical-1793D1.svg" alt="Documentation"/></a>
  <a href="https://github.com/goabonga/aur-packages/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"/></a>
  <a href="https://github.com/goabonga/multicz"><img src="https://img.shields.io/badge/versioning-multicz-blueviolet.svg" alt="multicz"/></a>
</p>

Some are specific to the machine; most are simply packages I want on Arch
and would rather maintain myself. The AUR gives every package its own git
repository, which stops scaling the moment a set of them shares patches,
a release cadence and a CI run - so they live here together, and
publication fans back out to the individual AUR repositories.

## Documentation

Published from `main` to GitHub Pages:
<https://goabonga.github.io/aur-packages/>.

## The one invariant

Four names are always the same string - `packages/<name>/`, `pkgbase`,
the multicz component and the AUR repository - and that string is also
the Conventional Commit scope. `scripts/check-packages.py` enforces it on
every push, because a break in it fails *silently*: the commit lands,
multicz reports nothing to bump, and the package quietly stops being
released.

## Packages

_No packages yet - see [Add a package](#add-a-package)._

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

## Versioning and release

Each package owns its version, changelog and git tag, bumped from
[Conventional Commits](https://www.conventionalcommits.org/) by
[multicz](https://github.com/goabonga/multicz) - the scope is the package
name. Merging to `main` is the release: CI tags, pushes to each package's
AUR repository and rebuilds the site.

```bash
uv tool run multicz plan     # what would be released, and why
```

A package wrapping upstream software keeps `pkgver` and `pkgrel` by hand;
multicz cannot own `pkgrel`, because pacman requires a positive integer
and a semantic version is not one. Full contract:
[Versioning and release](https://goabonga.github.io/aur-packages/releasing/).

## Pipeline

`detect` asks multicz which packages moved since their own last tag, and
the per-package checks run over that list alone. **Nothing is built in
CI** - the AUR distributes sources, and one of these packages is a
kernel; building it is the manual `build-package` workflow. See
[Pipeline](https://goabonga.github.io/aur-packages/pipeline/).

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
