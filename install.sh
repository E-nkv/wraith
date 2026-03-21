#!/bin/bash
# install.sh - voice-type installation script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing Voice Type Speech-to-Text Daemon${NC}"

# Check for system dependencies first
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

# If any dependencies are missing, exit with error
if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo -e "${RED}MISSING DEPENDENCIES${NC}"
    echo ""
    echo -e "${YELLOW}The following system dependencies are missing:${NC}"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo -e "${YELLOW}Please install them manually and run this script again.${NC}"
    exit 1
fi

echo -e "${GREEN}All system dependencies are installed!${NC}"

# Download latest binary
echo -e "${GREEN}Downloading Voice Type binary...${NC}"
LATEST_URL="https://github.com/E-nkv/voice-type/releases/latest/download/voice-type-linux-x64"
curl -L -o /tmp/voice-type "$LATEST_URL"
chmod +x /tmp/voice-type

# Download assets (sounds)
echo -e "${GREEN}Downloading sound assets...${NC}"
ASSETS_DIR="/usr/local/share/voice-type"
sudo mkdir -p "$ASSETS_DIR/sounds"
curl -L -o /tmp/sounds.tar.gz "https://github.com/E-nkv/voice-type/releases/latest/download/sounds.tar.gz"
sudo tar -xzf /tmp/sounds.tar.gz -C "$ASSETS_DIR/sounds"

# Install binary
echo -e "${GREEN}Installing binary to /usr/local/bin...${NC}"
sudo mv /tmp/voice-type /usr/local/bin/voice-type

echo -e "${GREEN}Voice Type binary and assets installed!${NC}"
echo -e "${GREEN}Installation complete!${NC}"