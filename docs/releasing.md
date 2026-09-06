# Versioning and release

Nothing in the release path is typed by hand. The commit message is the
whole interface.

## The commit is the release

```
<type>(<scope>): <description>
```

`<scope>` is the package name - the same string as the directory, the
`pkgbase` and the AUR repository.

| Type | Effect on the scoped package |
| --- | --- |
| `feat` | minor |
| `fix`, `perf`, `revert` | patch |
| `build` | patch - packaging changed, payload did not |
| `docs` | bumps the documentation site only |
| `test`, `style`, `chore`, `refactor`, `ci` | nothing |

`!` after the scope, or a `BREAKING CHANGE:` footer, makes it major.

## Two versioning shapes

This distinction decides what a release actually changes, so it is worth
getting right before adding a package.

### The package owns its content

A configuration package, a set of quirks, a script you wrote. `pkgver` is
the repository's own semantic version, and multicz writes it: the
component declares `bump_files` pointing at the `PKGBUILD`.

### The package wraps upstream software

A kernel, a patched build of someone else's release. `pkgver` must track
the upstream version, and `pkgrel` counts packaging revisions.

**multicz cannot own either number.** `pkgrel` has to be a positive
integer and a semantic version is not one - multicz would write
`pkgrel=1.0.1`, which pacman rejects. So the component declares **no**
`bump_files`: multicz owns the component's own version line, its
changelog and its tag, and the two numbers inside the `PKGBUILD` stay
with you.

That leaves one trap. A release says "this packaging changed", but the
AUR only notices if `pkgrel` (or `pkgver`) moved with it. So
`aur-publish` **fails** when a released package's AUR content is
unchanged, rather than pushing nothing and reporting success.

## What happens on a push to `main`

1. **`detect`** asks `multicz changed` which components moved since their
   own last tag.
2. **`package`** rechecks those, and only those.
3. **`release`** runs `multicz bump --commit --tag --push`: writes the
   changelogs, commits as `chore(release):`, tags each bumped component,
   and pushes. Signed when the GPG secrets exist.
4. **`aur-publish`** pushes each released package to
   `ssh://aur@aur.archlinux.org/<name>.git` and creates the GitHub
   Release.
5. **`docs`** rebuilds this site from the release commit.

## Preview before you push

```bash
uv tool run multicz plan          # what would bump, and why
uv tool run multicz explain <name>
uv tool run multicz graph         # the cascade DAG
```

`multicz plan` prints the driving commit next to every bump, so a
surprise in the plan is traceable to the commit that caused it.

## The `docs` component

This site is tracked too: it has a version, a tag, and `depends_on` every
package, so a package release cascades a docs patch and the site is
rebuilt with the new version rendered. Its version lives in
`zensical.toml` under `project.extra.versions.docs`.

## Drift detection

`.multicz/state.json` records the last released version of every
component. `multicz validate --strict` compares it against the tags and
fails on disagreement.
