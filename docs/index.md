# aur-packages

The AUR packages I run on my Arch Linux **GPD Pocket 1**. Some are
specific to the machine; most are simply packages I want on Arch and
would rather maintain myself.

The AUR gives every package its own git repository, which stops scaling
the moment a set of them shares patches, a release cadence and a CI run.
So they live here together, and publication fans back out to the
individual AUR repositories.

## The one invariant

Four names are always the same string - the directory, `pkgbase`, the
multicz component, and the AUR repository - and that string is also the
Conventional Commit scope. [Authoring a package](authoring.md) explains
why it is `pkgbase` and not `pkgname`.

## Where to go next

- [Packages](packages/index.md) - what this repository ships
- [Get started](get-started.md) - requirements, add a package, check it
- [Authoring a package](authoring.md) - the invariant and the rules
- [Versioning and release](releasing.md) - the commit-to-AUR contract
- [Pipeline](pipeline.md) - what CI runs, and why nothing is built there

This site grows as the repository does; each page arrives with the thing
it documents.
