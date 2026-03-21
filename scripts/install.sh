#!/bin/bash
# install.sh - WRAITH installation script

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing WRAITH Speech-to-Text Daemon${NC}"

# Download latest binary
echo -e "${GREEN}Downloading WRAITH binary...${NC}"
LATEST_URL="https://github.com/E-nkv/wraith/releases/latest/download/wraith-linux-x64"
curl -L -o /tmp/wraith "$LATEST_URL"
chmod +x /tmp/wraith

# Download assets (sounds)
echo -e "${GREEN}Downloading sound assets...${NC}"
ASSETS_DIR="/usr/local/share/wraith"
sudo mkdir -p "$ASSETS_DIR/sounds"
curl -L -o /tmp/sounds.tar.gz "https://github.com/E-nkv/wraith/releases/latest/download/sounds.tar.gz"
sudo tar -xzf /tmp/sounds.tar.gz -C "$ASSETS_DIR/sounds"

# Install binary
echo -e "${GREEN}Installing binary to /usr/local/bin...${NC}"
sudo mv /tmp/wraith /usr/local/bin/wraith

echo -e "${GREEN}Installation complete!${NC}"

# Check for system dependencies
MISSING_DEPS=()

if ! command -v dotool >/dev/null 2>&1; then
    MISSING_DEPS+=("dotool")
fi

if ! command -v notify-send >/dev/null 2>&1; then
    MISSING_DEPS+=("libnotify")
fi

if ! command -v paplay >/dev/null 2>&1; then
    MISSING_DEPS+=("pulseaudio-utils")
fi

if ! command -v google-chrome >/dev/null 2>&1 && ! command -v google-chrome-stable >/dev/null 2>&1; then
    MISSING_DEPS+=("Google Chrome")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Warning: The following system dependencies are missing:${NC}"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo "Run the following to install them:"
    echo ""
    echo "  curl -fhsSL https://github.com/E-nkv/wraith/releases/latest/download/sysdeps.sh | bash"
    echo ""
    echo "Or install them manually:"
    echo "  - dotool (Wayland virtual input)"
    echo "  - libnotify (desktop notifications)"
    echo "  - pulseaudio-utils (paplay for sound)"
    echo "  - Google Chrome (for Web Speech API)"
fi
