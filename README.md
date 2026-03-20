# WRAITH

Real-time speech-to-text dictation for Linux Wayland. Type into any application using your voice.

## Features

- **Instant Dictation**: Press a hotkey and start speaking. Text appears in real-time in whatever window you have focused.
- **Auto-Correction**: If the AI corrects a word mid-sentence, it automatically backspaces and types the corrected version.
- **System-Wide**: Works in any application - text editors, browsers, terminals, messaging apps, etc.
- **Visual & Audio Feedback**: Get instant confirmation when listening starts, stops, or if there's an error.
- **Zero Latency**: Browser runs persistently in the background - no startup delay when you press the hotkey.
- **No API Keys**: Uses Chrome's built-in Web Speech API - no paid services or local AI models needed.

## Quick Start

### 1. Install Dependencies

```bash
# Arch Linux
sudo pacman -S --needed dotool libnotify paplay google-chrome

# Ubuntu/Debian
sudo apt install dotool libnotify-bin pulseaudio-utils google-chrome-stable

# Fedora
sudo dnf install dotool libnotify pulseaudio-utils google-chrome-stable
```

### 2. Clone and Install

```bash
git clone <your-repo-url>
cd wraith
bun install
```

### 3. Set Up Keyboard Shortcuts

Open GNOME Settings → Keyboard → Custom Shortcuts, then add:

**Start Dictation (F9):**
- Name: Wraith Start
- Command: `curl http://127.0.0.1:3232/start`
- Shortcut: F9

**Stop Dictation (F10):**
- Name: Wraith Stop
- Command: `curl http://127.0.0.1:3232/stop`
- Shortcut: F10

### 4. Run

```bash
bun run .
```

You'll see a notification when the daemon is ready. Press F9 to start dictating, F10 to stop.

## How It Works

1. Press F9 to start listening
2. Speak into your microphone
3. Text appears in real-time in your focused window
4. Press F10 to stop

The daemon runs in the background and handles all the transcription, diffing, and text injection automatically.

## Technology

- **Bun + TypeScript**: Fast runtime and type safety
- **Puppeteer**: Manages a headless Chrome browser
- **Chrome Web Speech API**: High-quality cloud transcription
- **dotool**: Wayland-compatible virtual keyboard input
- **libnotify**: Desktop notifications
- **paplay**: Sound playback for feedback

## Requirements

- Linux with Wayland (GNOME recommended)
- Google Chrome Stable
- Bun runtime
- Microphone

## License

Version 1.0.0
