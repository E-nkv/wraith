# ARCHITECTURE.md - WRAITH Real-Time Dictation Injector

## 1. Overview

**Wraith** is a high-performance, persistent background daemon designed for real-time text input on Linux systems. It isolates speech transcription into a dedicated, headless Chrome instance while the core logic runs in a Node.js server. The key feature is **real-time text correction** achieved via kernel-level input simulation, completely bypassing the clipboard.

### Key Features

- **Real-Time Correction:** Implements a "Phantom Backspace" logic driven by interim STT results.
- **Persistent Daemon:** The Node.js Daemon runs constantly as a **User Systemd Service**.
- **Clipboard Bypass:** Uses the `dotool` utility for direct, low-latency text injection into any active window.
- **HotKey Control:** External system hotkeys (F9/F10) trigger simple HTTP endpoints on the local daemon.

## 2. Core Components and Workflow

The system is structured around a central Daemon that manages a separate, persistent Transcription Worker.

### A. Component Structure

1.  **Server Daemon (Node.js/Express):** The brain. Manages the HTTP server and the Server to Browser interactions, holds the session state, and calls the OS injection layer.
2.  **Transcription Worker (Puppeteer/Chrome):** A persistent, headless browser instance controlled by the Daemon. Its sole purpose is to listen via the Web Speech API.
3.  **OS Input Layer (`dotool`):** The low-level utility that simulates keystrokes. It runs as a root-managed service for kernel access.

### B. Data Flow and Communication

1.  **Trigger Flow (F9/F10):** User presses F9 $\rightarrow$ GNOME executes `curl http://127.0.0.1:3232/start`. The Node HTTP server receives this and sends a command to the persistent Worker via **WebSocket**.
2.  **Transcription Flow (Real-Time):** The Worker's Web Speech API generates results $\rightarrow$ The Worker pushes these structured JSON updates back to the Daemon via the **WebSocket**.
3.  **Injection Flow (OS Interaction):** The Daemon receives the text $\rightarrow$ Applies Phantom Backspace logic $\rightarrow$ Calls the OS Abstraction layer, which executes `dotool` via Node's `child_process.spawn`.

## 3. Key Implementation Details

### A. Persistent Worker Management (Puppeteer)

- The browser is launched **once** at daemon startup using specific Chrome flags to auto-grant microphone permission (`--use-fake-ui-for-media-stream`) and prevent throttling.
- The Daemon controls the WSA via `page.evaluate(startListening)` and `page.evaluate(stopListening)`.

### B. Real-Time Text Correction (The "Phantom Backspace")

- The Daemon Daemon maintains state variables: `finalTextBuffer`, `currentInterimText`, and most importantly, `lastSentLength`.
- When a new text update arrives, the Node process calculates the character difference from `lastSentLength`.
- If the difference is negative (a correction), Node spawns `dotool` to send that many **Backspace** events before sending the new text chunk.

### C. OS Interaction and Permissions (`dotool`)

- **Daemon:** `dotool` is run by the root-managed Systemd Service, which has permission to access the kernel input device (`/dev/uinput`).
- **Client:** The Node.js Daemon runs as the **User** for security. It communicates with the root daemon by explicitly setting the environment variable `YDOTOOL_SOCKET=/var/run/ydotoold.sock` when spawning the `dotool` client process.

### D. Robustness and Error Handling

- **Network Interruptions:** If the WSA stops unexpectedly (due to silence timeout or network loss), the Worker's `onend` listener will auto-restart the WSA if the user has not manually stopped the session via `/stop`.
