<h1 align="center">WhatsApp for Omarchy</h1>

<p align="center"><strong>WhatsApp, native to the Omarchy shell. Not a browser tab.</strong></p>

<p align="center">
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-7aa2f7"></a>
  <img alt="Omarchy 4 Quattro" src="https://img.shields.io/badge/Omarchy-4%20Quattro-7aa2f7">
  <img alt="wacli 0.17.1 or newer" src="https://img.shields.io/badge/wacli-0.17.1%2B-7aa2f7">
</p>

![WhatsApp for Omarchy: the full app and the bar dropdown](preview.png)

A fast, local-first WhatsApp client for [Omarchy](https://omarchy.org). Your
chats live in a private local mirror kept by
[`wacli`](https://github.com/openclaw/wacli); the app renders it in Quickshell,
follows your Omarchy theme, and lives in your bar. No Electron, no browser
wrapper, and no server of its own: messages go only to WhatsApp.

## Why it feels different

**Opens instantly, works offline.** Chats and messages come from a local
SQLite mirror, so the window never waits for the network. New messages appear
the moment sync writes them, without polling. Pause sync and the whole archive
stays readable and searchable.

**Reply from the bar.** Click the bar icon for a compact client: recent chats,
the conversation, and a real composer with files, emoji and voice notes. Most
replies never need the full window.

**Everything a chat needs.** Replies, edits, reactions, polls, stickers,
albums, up to 10 files with a caption, real `@` mentions, voice notes you
review before sending, forwarding to several chats at once with a note, and
deleting many messages together.

**Feels like the phone.** The chat on screen is read, replying marks it read,
and the contact sees you typing. Desktop notifications carry the chat photo,
open the chat on click and can be answered from the bar. Muted and archived
chats stay quiet.

**Several accounts, one list.** Link more than one number: the chat list
merges them, each account has its own color, and each can pause its sync or
silence its notifications on its own.

**Native to Omarchy.** Theme colors and fonts, keyboard-first everywhere, and
real layouts from a wide window down to 360 px. Quit with `Ctrl+Q`, and choose
whether it starts with the system.

**Private by design.** No account, server or telemetry of its own. Reading a
chat never sends a read receipt. Screenshots and tests use synthetic demo data
only. See [privacy](docs/PRIVACY.md).

**Ready for your agent.** An agent skill and an MCP server with 46 tools let
Claude Code and other agents read and act on WhatsApp for you, asking before
anything that changes WhatsApp.

## A closer look

| The full app | From the bar |
|---|---|
| ![Chat list and conversation](docs/screenshots/app.png) | ![Bar dropdown conversation](docs/screenshots/dropdown-chat.png) |

| Real group mentions | Native media viewer |
|---|---|
| ![Mention picker in a group](docs/screenshots/mentions-800x600.png) | ![Photo viewer](docs/screenshots/media-viewer-800x600.png) |

| One card per account | Down to 360 px |
|---|---|
| ![Settings, accounts](docs/screenshots/settings-accounts.png) | ![Single-pane mobile layout](docs/screenshots/mobile-360x640.png) |

Every screenshot is rendered from the repository's demo data. No real
conversation is included in this repository.

## Install

**Requirements**

- Omarchy 4 (Quattro), whose shell runs plugins
- [`wacli`](https://github.com/openclaw/wacli) 0.17.1 or newer at
  `~/.local/bin/wacli` (tested with 0.17.1, 0.18.3 and 0.19.0)
- Qt Multimedia and Image Formats, `wl-clipboard`, `zenity`,
  `inotify-tools`, `jq`, Python 3 and systemd user services
- Optional: `libnotify` for desktop notifications

**Install**

```bash
git clone https://github.com/atoslins/Omarchy-WhatsApp-v2.git
cd Omarchy-WhatsApp-v2
./scripts/install
```

The app needs its helper and background sync, so it installs with its own
script rather than `omarchy plugin add`. `./scripts/install --check` runs
the same checks without changing anything.
No sudo or pkexec is required; the installer only writes to your home directory:

| What | Where |
|---|---|
| The plugin, added to the right of your bar | `~/.config/omarchy/plugins/io.github.atoslins.whatsapp`, `~/.config/omarchy/shell.json` |
| The helper and the MCP server | `~/.local/bin/omawhatsapp`, `~/.local/bin/omawhatsapp-mcp` |
| Background sync, one user service per account | `~/.config/systemd/user/wacli-sync*.service` |
| The agent skill | `~/.agents/skills/omawhatsapp` |

It stages everything first, replaces it as one set, and rolls back an
interrupted install. It never copies a WhatsApp session anywhere.

**Link your phone.** On first run the app offers a Show QR code button. From
a terminal instead:

```bash
~/.local/bin/omawhatsapp wacli --interactive --authorize interactive -- auth
```

**Add the shortcut.** Copy the `Super+Shift+W` line from
[`omarchy/bindings.lua.example`](omarchy/bindings.lua.example) into
`~/.config/hypr/bindings.lua`.

**Coming from OmaWhatsApp?** Install over it. This app takes its place in the
bar and keeps the same helper, services, linked device and history, so nothing
needs to be linked again. Keybindings that call the old plugin ID are listed
at the end of the install so you can update them.

## Update and remove

**Update.** Settings → Updates checks this repository for a new release and
can install it in a terminal after you confirm. By hand: `git pull`, then run
`./scripts/install` again. Always run the installer: it updates the plugin,
the helper and the services together.

**Remove.**

```bash
./scripts/uninstall
```

This keeps the linked device and wacli's message store. Add
`--purge-runtime` to also remove this app's own disposable state.

## wacli: official and richer builds

Everything above works with official wacli releases. A few extras need wacli
additions that are not in an official release yet. The app detects them and
turns each one on by itself:

| Feature | Official wacli | With the additions |
|---|---|---|
| Chats, sending, media, groups, notifications, several accounts | ✓ | ✓ |
| Showing the contact that you are typing | ✓ | ✓ |
| Ticks for sent, delivered and read | no tick shown | ✓ |
| A contact's online, last seen and typing | not shown | ✓ |
| Starring messages | hidden | ✓ |
| `@` on chats whose unread messages mention you | not shown | ✓ |
| Forwarding and deleting without pausing sync | pauses sync for a few seconds | ✓ |

## Let your agent use WhatsApp

The installer places an agent skill at `~/.agents/skills/omawhatsapp`, so
compatible agents can use `$omawhatsapp` to search, summarize and, when you
ask, act on your chats. For Claude Code and other MCP clients, register the
server once:

```bash
claude mcp add --scope user whatsapp -- ~/.local/bin/omawhatsapp-mcp
```

Then ask in plain words: "who wrote to me that I have not read yet, and about
what", "what attachments did Bruno send this month", "reply to Carlos that I
am on my way", "tag these five as suppliers and tell each of them we are
closed tomorrow".

Both are fail-closed. Each of wacli's 104 operations is classified as a local
read, remote read, local write, sync, WhatsApp write, destructive or
interactive action; local reads run read-only, and everything else needs your
request. Tools that change WhatsApp are marked so the client asks you first
and shows the recipient and the text. Neither ever writes to WhatsApp's
database directly, invents a recipient or retries a send that may have gone
through. Details in the
[agent gateway reference](skills/omawhatsapp/references/wacli-parity.md).

## Documentation

| Page | For |
|---|---|
| [Using the app](docs/USAGE.md) | Every feature, the settings and all keyboard shortcuts |
| [Privacy](docs/PRIVACY.md) | What is stored, where, and what never leaves your machine |
| [Architecture](docs/ARCHITECTURE.md) | How the service, the window, the helper and wacli fit together |
| [Technical notes](docs/TECHNICAL.md) | Performance budgets, refresh and sync details |
| [WhatsApp parity](docs/PARITY.md) | Which WhatsApp features exist and how each one was verified |
| [Agent gateway](skills/omawhatsapp/references/wacli-parity.md) | How each of wacli's operations is classified and guarded |
| [Testing](docs/TESTING.md) | The release gate and the screenshot rules |
| [Changelog](CHANGELOG.md) | What changed in each release |

## Quality

```bash
./scripts/test
```

The release gate runs 339 helper, installer and agent tests, 533 offscreen
QML tests in 58 suites, an isolated installer preflight, manifest validation,
QML lint and shell checks. CI runs it against wacli 0.17.1, 0.18.3 and
0.19.0.

## Credits

WhatsApp for Omarchy began as a fork of
[OmaWhatsApp](https://github.com/MoizIbnYousaf/Omarchy-Whatsapp) by
MoizIbnYousaf, which built the resident service, the bar dropdown, the helper
boundary and the installer this app stands on. Its model was informed by
[Omamail](https://github.com/huacnlee/omamail), and WhatsApp itself is reached
through [wacli](https://github.com/openclaw/wacli). See the
[third-party notices](THIRD_PARTY_NOTICES.md).

WhatsApp for Omarchy is independent and not affiliated with WhatsApp or Meta.

## License

[MIT](LICENSE) © 2026 MoizIbnYousaf (the original OmaWhatsApp) and Atos Lins.
