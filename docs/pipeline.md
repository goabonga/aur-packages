# Pipeline

Two workflows. `ci.yml` runs on pull requests to `main` and on pushes to
`main`; only the push path releases. `build-package.yml` is manual.

## What runs

| Job | Runs on | What it proves |
| --- | --- | --- |
| `checks` | ubuntu | SPDX headers, ruff, shellcheck, actionlint, the multicz config, the name invariant, generated pages |
| `template` | `archlinux` | `template/` still scaffolds a package that builds and installs |
| `detect` | ubuntu | which components moved since their own last tag |
| `package` | `archlinux` | per changed package: shellcheck, `.SRCINFO` drift, checksums against upstream, namcap |
| `release` | ubuntu | bumps, changelogs, tags, pushes |
| `aur-publish` | `archlinux` | pushes each released package to its AUR repository |
| `docs` | ubuntu | rebuilds and deploys the site |

## Why `detect` asks multicz

A path diff answers "what did this push touch?". That is not the question
the release job asks minutes later — it asks "what is unreleased?".
`multicz changed` with no `--since` compares each component against its
own last tag, which is that second question. Using one source for both
keeps the tested set and the released set identical: a package whose
previous release failed still gets rechecked.

On a pull request there are no new tags yet, so the comparison is against
the target branch instead.

## Nothing is built in `ci`

The AUR distributes **sources**. No step in the release path needs a
compiled package, and one of the packages here is a kernel — an hour of
wall clock and more disk than a hosted runner leaves free.

So `ci` runs only the cheap metadata checks, and building is a separate
manual workflow:

```
Actions → build-package → Run workflow → package: linux-hardened-usbgadget
```

It frees the runner's preinstalled toolchains (~25 GB) first, because a
kernel build does not fit otherwise.

The one exception is `template`, which does build — its package is
`arch=('any')` and takes seconds.

## `makepkg` cannot run as root

Every Arch-container job creates an unprivileged `builder` user with
passwordless `pacman` rights and runs the build as them.

## The `aur-publish` guard

A release means "this packaging changed", but the AUR only notices if
`pkgrel` or `pkgver` moved. For a package whose `pkgver` tracks upstream
those are maintained by hand, so it is possible to release something that
ships nothing.

The job stages the files it would push and **fails** when the result is
identical to what the AUR already has, naming the missing `pkgrel` bump.

## Repository setup, once

| What | Where |
| --- | --- |
| `AUR_SSH_PRIVATE_KEY` | Settings → Secrets → Actions |
| `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE` | Settings → Secrets → Actions (optional; unsigned otherwise) |
| `AUR_SSH_KNOWN_HOSTS` | Settings → Variables (optional; pins the AUR host key) |
| Pages source: GitHub Actions | Settings → Pages |
| `aur-<name>` environments | Settings → Environments, one per package |

Without `AUR_SSH_PRIVATE_KEY` the publish job runs as a dry run and
reports what it would have pushed, so the pipeline is safe to run before
the secret exists.
