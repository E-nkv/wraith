# Voice Type

System-wide speech-to-text for Linux. Press a key, speak, press again — the text
appears wherever your cursor is in the system. Super accurate and cheap.

# Why I built it

I needed high quality transcription, near real time, cheap or free, while using minimal system resources, that works mainly in Arch Linux and Fedora, both x64 and ARM64. Most solutions don't meet these requirements. 

# V4

Uses a hidden chromium instance to take advantage of Google's Speech to Text infrastructure. Install with 

```bash
curl -sSL https://raw.githubusercontent.com/eriknovikov/voice-type/main/v4/install.sh | bash
```

Uninstall with

```bash
curl -sSL https://raw.githubusercontent.com/eriknovikov/voice-type/main/v4/uninstall.sh | bash
```

# V5
Single Go Binary that records audio and sends to some OpenRouter voice model (parakeet v3 from Nvidia). Install with

```bash
curl -sSL https://raw.githubusercontent.com/eriknovikov/voice-type/main/v5/install.sh | bash
```

Uninstall with

```bash
curl -sSL https://raw.githubusercontent.com/eriknovikov/voice-type/main/v5/uninstall.sh | bash
```

## Vocabulary workspaces

Names and jargon a transcriber would otherwise mangle live in
`~/.config/voice-type.jsonc`, grouped into workspaces:

```jsonc
"vocabulary": {
    "general":    ["Erik Novikov", "OpenRouter"],  // sent with every dictation
    "numbero":    ["Keyloop", "Audaris", "Numbero"],
    "voice-type": ["dotool", "JSONC", "parakeet"]
}
```

`general` always rides along; exactly one of the others is active at a time, and
what gets sent is the two merged. Pick one from the terminal:

```bash
voice-type vocab ls                   # every list in config order, * on the active one
voice-type vocab set numbero
voice-type vocab set none             # general only
```

`voice-type vocab` on its own is the same as `vocab ls`:

```
sending: 5
current: numbero
general: 2
numbero*: 3
voice-type: 3
```

`sending` is how many terms the next dictation carries (general merged with the
active list, duplicates folded); each row is one list and its own term count,
in the order your config file writes them.

The choice is recorded in `~/.local/state/voice-type/workspace` and applies to
the next dictation -- no restart. A flat `"vocabulary": [...]` array still works
and means the general list. `voice-type models` says which models read a
vocabulary at all.

The binary always goes to `/usr/local/bin/voice-type` -- there is no `--prefix`
and no `~/.local/bin` fallback. If another `voice-type` is on your `PATH` (an old
hand-built copy in `~/.local/bin` outranks `/usr/local/bin` on most setups) the
installer says so and offers to remove it, because otherwise that copy keeps
answering `voice-type` and the new install looks like it did nothing. The
uninstaller sweeps the same way.

Only one version can be installed at a time: both use the `voice-type` command,
`~/.config/voice-type.jsonc`, and port 3232, so installing one replaces the other.



