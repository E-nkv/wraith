# WRAITH

Real-time speech-to-text dictation for Linux. Type into any application using your voice.

## Features

- **Instant Dictation**: Press a hotkey and start speaking. Text appears in real-time in whatever window you have focused.
- **Auto-Correction**: If the AI corrects a word mid-sentence, it automatically backspaces and types the corrected version.
- **System-Wide**: Works in any application - text editors, browsers, terminals, messaging apps, etc.
- **Visual & Audio Feedback**: Get instant confirmation when listening starts, stops, or if there's an error.
- **Zero Latency**: Browser runs persistently in the background - no startup delay when you press the hotkey.
- **No API Keys**: Uses Chrome's built-in Web Speech API - no paid services or local AI models needed.

## Installation

### Quick Install (with system dependencies)

```bash
curl -fhsSL https://github.com/E-nkv/wraith/releases/latest/download/install-sysdeps.sh | bash
curl -fhsSL https://github.com/E-nkv/wraith/releases/latest/download/install.sh | bash
```

### Manual Install

If you prefer to install system dependencies yourself, or if the automated sysdeps script has issues on your system:

1. Install system dependencies manually:
   - **Arch Linux**: `yay -S dotool google-chrome` (plus `libnotify` and `paplay` from official repos)
   - **Debian/Ubuntu**: `sudo apt install dotool libnotify-bin pulseaudio-utils google-chrome-stable`
   - **Fedora**: `sudo dnf install dotool libnotify pulseaudio-utils google-chrome-stable`

2. Install WRAITH:
```bash
curl -fhsSL https://github.com/E-nkv/wraith/releases/latest/download/install.sh | bash
```

### System Dependencies

WRAITH requires the following:
- **dotool** - Wayland-compatible virtual keyboard input
- **libnotify** - Desktop notifications
- **pulseaudio-utils** - Sound playback (paplay) for feedback
- **Google Chrome** - For the Web Speech API (most accurate and fast)

## Keyboard Shortcuts

### GNOME

Open GNOME Settings → Keyboard → Custom Shortcuts, then add:

**Start Dictation (F9):**

- Name: WRAITH Start
- Command: `curl http://127.0.0.1:3232/start`
- Shortcut: F9

**Stop Dictation (F10):**

- Name: WRAITH Stop
- Command: `curl http://127.0.0.1:3232/stop`
- Shortcut: F10

### Other Desktop Environments

Non-GNOME shortcut configuration documentation is coming soon. For now, manually bind F9 to `curl http://127.0.0.1:3232/start` and F10 to `curl http://127.0.0.1:3232/stop`.

## Usage

1. Run `wraith` to start the daemon
2. Press F9 to start dictating
3. Speak into your microphone
4. Press F10 to stop

## How It Works

1. Press F9 to start listening
2. Speak into your microphone
3. Text appears in real-time in your focused window
4. Press F10 to stop listening

## Technology

- **Bun + TypeScript**: Fast runtime and type safety
- **Puppeteer**: Manages a headless Chrome browser
- **Chrome Web Speech API**: High-quality cloud transcription
- **dotool**: Wayland-compatible virtual keyboard input
- **libnotify**: Desktop notifications
- **paplay**: Sound playback for feedback

## Requirements

- Linux with Wayland (GNOME recommended)
- Google Chrome Stable (Its Web Speech Api is by far the most superior, in accuracy and speed)
- Microphone
