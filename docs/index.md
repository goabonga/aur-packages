# aur-packages

The AUR packages I run on my Arch Linux **GPD Pocket 1**. Some are
specific to the machine; most are simply packages I want on Arch and
would rather maintain myself.

The AUR gives every package its own git repository, which stops scaling
the moment a set of them shares patches, a release cadence and a CI run.
So they live here together, and publication fans back out to the
individual AUR repositories.

## What is here today

- `template/` — the skeleton every package is copied from
- `scripts/new-package.sh` — copies it into `packages/<name>/`
- `scripts/lint-package.sh`, `scripts/srcinfo.sh` — the local checks

This site grows as the repository does; each page arrives with the thing
it documents.
