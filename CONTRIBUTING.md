# Contributing to WhatsApp for Omarchy

WhatsApp for Omarchy stays lean by keeping one narrow boundary: Quickshell owns the UI,
the helper reads the local mirror, and `wacli` owns every WhatsApp/network
write. Changes should preserve that split and avoid browser or Electron
runtimes.

## Before opening a pull request

```bash
./scripts/test
```

- Keep every write scoped to an exact locally indexed chat and, when relevant,
  message ID.
- Never add a real session, database, JID, phone number, message, media file, or
  conversation screenshot to a commit or issue.
- Use demo mode for UI evidence and include narrow plus wide coverage for layout
  changes.
- Update the parity, technical, or privacy docs when their contract
  changes.
- Explain any new runtime dependency. Browser and Electron dependencies are out
  of scope.

The full verification contract is in [docs/TESTING.md](docs/TESTING.md).

## Commit and pull request titles

This project follows [Conventional Commits](https://www.conventionalcommits.org).
Pull requests are squash-merged, so the pull request title becomes the commit
on `main`; a check keeps it in this form:

```text
<type>(<optional scope>): <what changes, in the imperative>

feat(accounts): mute notifications per account
fix(dropdown): make the Clear button clear the badge
docs: explain the richer wacli builds
```

| Type | Use it for | Next version |
|---|---|---|
| `feat` | Something new a user can do or see | minor |
| `fix` | A bug fix | patch |
| `perf` | Faster or lighter, same behavior | patch |
| `revert` | Undoing an earlier change | patch |
| `docs` | Documentation only | none |
| `refactor`, `test`, `build`, `ci`, `chore` | Everything else | none |

Mark a breaking change with `!` after the type (`feat!: …`) or a
`BREAKING CHANGE:` footer. Scopes are optional; the usual ones are `app`,
`dropdown`, `bar`, `settings`, `accounts`, `helper`, `installer`, `mcp` and
`skill`. Write titles and commit messages in English.

## Versions and releases

Versions follow [Semantic Versioning](https://semver.org):
`MAJOR.MINOR.PATCH`.

- **MAJOR**: an update that needs more than running the installer, such as
  a raised wacli minimum, a manual migration, or removing a setting, command or
  IPC call that users rely on. While the version is below 1.0, these raise the
  minor number instead.
- **MINOR**: new features that keep existing setups working.
- **PATCH**: fixes and performance.

The version lives in `manifest.json`, `plugins/omawhatsapp/manifest.json` and
`HELPER_VERSION` in `bin/omawhatsapp_core.py`, and `./scripts/test` fails if
they disagree. Nobody edits them by hand: after each merge to `main`,
[release-please](https://github.com/googleapis/release-please) keeps a release
pull request up to date with the next version and the changelog written from
the commit titles. Merging that pull request tags `vX.Y.Z` and publishes the
GitHub release; the app's update check and the Omarchy plugin store then see
it.
