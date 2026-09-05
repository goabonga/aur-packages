## Description

<!-- What does this change, and why? -->

## Type

<!-- Check the one that applies. The scope of your commits must be the
     package name whenever you touched packages/<name>/. -->

- [ ] `feat(<package>)` — new capability, new file installed (minor)
- [ ] `fix(<package>)` — the package was wrong and now is not (patch)
- [ ] `build(<package>)` — packaging changed, payload did not (patch)
- [ ] `docs` — documentation only
- [ ] `ci` / `chore` / `refactor` / `test` — no release

## Packages touched

<!-- One per line, matching packages/<name>/ exactly. -->

-

## Related issues

<!-- Closes #123 -->

## Checklist

- [ ] Commits follow [Conventional Commits](https://www.conventionalcommits.org/), **scoped to the package name**
- [ ] No `Co-Authored-By` or tool-attribution trailer
- [ ] Branch is up to date with `main`
- [ ] `python3 scripts/check-packages.py` passes
- [ ] `uv tool run multicz validate --strict` passes
- [ ] `python3 scripts/gen-package-docs.py --check` passes (if a package README changed)
- [ ] `scripts/lint-package.sh` passes on every PKGBUILD

If you touched a package:

- [ ] `.SRCINFO` regenerated with `scripts/srcinfo.sh <name>`
- [ ] Checksums refreshed with `updpkgsums` (never `SKIP` for local files)
- [ ] `scripts/lint-package.sh <name>` passes
- [ ] `pkgrel` bumped (or `pkgver`, for an upstream move) — a release
      whose AUR content is unchanged fails the publish job
- [ ] For a heavy package, the `build-package` workflow was run once

If you touched `scripts/` or `.github/workflows/`:

- [ ] `ruff check` / `ruff format --check` clean, `shellcheck scripts/*.sh` clean
- [ ] SPDX headers present (`python3 scripts/add_license_header.py --path scripts --types py,sh --check`)
- [ ] `actionlint .github/workflows/*.yml` clean
