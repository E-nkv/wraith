# What's Voice Type?

A Linux first system-wide dictation tool to transcribe Speech To Text (STT) with unmatched accuracy and speed, totally free.

## Features

- **Instant Dictation**: Press a hotkey and start speaking. Text appears in real-time in whatever window you have focused in the system.
- **Auto-Correction**: If the AI corrects a word mid-sentence, it automatically backspaces and types the corrected version.
- **System-Wide**: Works in any application - text editors, browsers, terminals, messaging apps, etc.
- **Visual & Audio Feedback**: Get instant confirmation when listening starts, stops, or if there's an error.
- **Zero Latency**: Browser runs persistently in the background - no startup delay when you press the hotkey.
- **Totally free**: Uses Chrome's built-in Web Speech API - so no paid services required.
- **No local models required**: The browser Web Speech Api handles the transcription process entirely, so there's no need to install and setup models locally (like vosk or whisper).

## Installation and setup

### System Dependencies

Voice Type requires the following system dependencies:

- **dotool** - Wayland-compatible virtual keyboard input
- **libnotify** - Desktop notifications
- **pulseaudio-utils** - Sound playback (paplay) for feedback
- **Google Chrome** - For the Web Speech API (most accurate and fast)

> Since you already are a Linux user, I'm sure you will be able to install the required system dependencies yourself. Just ask your favorite AI how to install each library, considering your distro and your desktop environment (gnome, kde, etc).

### Install Voice Type

Once you have all dependencies installed, run:

```bash
curl -fsSL https://github.com/E-nkv/voice-type/releases/latest/download/install.sh | bash
```

The installer will verify that all dependencies are present before proceeding with the installation.

## Keyboard Shortcuts

Voice Type runs as a daemon and listens for HTTP requests to start/stop dictation. You'll want to set up keyboard shortcuts so you can actually use it without manually running curl commands.

### GNOME

Open GNOME Settings → Keyboard → Custom Shortcuts, then add:

**Start Dictation (F9):**

- Name: Voice Type Start
- Command: `curl http://127.0.0.1:3232/start`
- Shortcut: F9

**Stop Dictation (F10):**

- Name: Voice Type Stop
- Command: `curl http://127.0.0.1:3232/stop`
- Shortcut: F10

### Other Desktop Environments

Non-GNOME shortcut configuration documentation is coming. For now, manually bind F9 to `curl http://127.0.0.1:3232/start` and F10 to `curl http://127.0.0.1:3232/stop`.

## Usage

1. Run `voice-type` to start the daemon
2. Press F9 to start dictating
3. Speak into your microphone
4. Press F10 to stop

## How It Works

1. Press F9 to start listening
2. Speak into your microphone
3. Text appears in real-time in your focused window
4. Press F10 to stop listening

## Development

You can also run the app with bun or node. to do that:

- clone the repo
- cd into it
- install node_modules with your package manager (a.k.a: `bun install`)
- run it `bun run ./src/index.ts`

## Contributing

Voice Type is totally free and open source, and you can contribute in many ways! You could:

- report/fix a bug or issue
- improve documentation
- or suggesting / adding a new feautre

Either way, feel free to contact me, open an issue, or drop a PR.
