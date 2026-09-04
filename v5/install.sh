#!/bin/sh
# voice-type v5 installer.
#
# Fetches the static Go binary for this architecture from GitHub Releases,
# verifies its checksum, installs it, and writes a config. Runtime and package
# setup belong elsewhere.
#
#   curl -sSL https://raw.githubusercontent.com/eriknovikov/voice-type/main/v5/install.sh | sh
#
# Installs one voice-type: the binary, config, and port are shared across
# majors, so this replaces whatever is already installed.
set -eu

REPO="eriknovikov/voice-type"
BINARY_NAME="voice-type"
MAIN_PKG="cmd/voice-type"
PORT=3232

MODE="prod"          # prod | version | local
VERSION_TAG=""
# The one install location. It is deliberately not configurable: the binary, the
# config, and the port are shared across majors, and a second copy somewhere else
# on PATH is what silently answers `voice-type` with an old build.
PREFIX="/usr/local"
API_KEY=""
CONFIG_CREATED=0
CONFIG_TMP=""
TMP_DIR=""

RED=$(printf '\033[31m'); YELLOW=$(printf '\033[33m')
GREEN=$(printf '\033[32m'); RESET=$(printf '\033[0m')

log_info() { printf '%s==>%s %s\n' "$GREEN" "$RESET" "$1" >&2; }
log_warn() { printf '%s!!%s  %s\n' "$YELLOW" "$RESET" "$1" >&2; }
log_error() { printf '%sxx%s  %s\n' "$RED" "$RESET" "$1" >&2; }

cleanup() {
    [ -z "$CONFIG_TMP" ] || rm -f "$CONFIG_TMP"
    [ -z "$TMP_DIR" ] || rm -rf "$TMP_DIR"
}

# Wraps a path in an OSC 8 hyperlink so the config is click-to-open in terminals
# that support them (GNOME Terminal, Kitty, WezTerm, iTerm2, Konsole). Emitted
# only when stderr is a terminal, so redirected output keeps plain paths instead
# of escape sequences. Spaces are the one character that must be encoded for the
# file:// URL to survive.
link_path() {
    if [ ! -t 2 ]; then
        printf '%s' "$1"
        return 0
    fi
    printf '\033]8;;file://%s\007%s\033]8;;\007' "$(printf '%s' "$1" | sed 's/ /%20/g')" "$1"
}

usage() {
    cat >&2 << EOF
Usage: install.sh [--version vX.Y.Z | --local]

  --version vX.Y.Z   install a specific v5 release
  --local            build from the working tree with the Go toolchain
EOF
}

# Piped through curl, stdin is the script itself -- every prompt must come from
# the terminal, and there may not be one. Testing permissions on the device node
# is not enough: /dev/tty exists but cannot be opened when the process has no
# controlling terminal (systemd, cron, setsid), and an unguarded prompt then dies
# under `set -e` before the config is written.
# The probe runs in a subshell with `true`, not `:`. A redirection failure on a
# special built-in like `:` terminates the shell outright -- neither `2>/dev/null`
# nor `||` can catch it -- which silently killed the installer before it wrote
# the config.
has_tty() {
    ( true < /dev/tty ) 2> /dev/null || return 1
    ( true > /dev/tty ) 2> /dev/null
}

prompt_yn() {
    _msg="$1"; _default="$2"
    if ! has_tty; then
        echo "$_default"
        return 0
    fi
    case "$_default" in
        [Yy]*) _opts="Y/n"; _label="Y" ;;
        *) _opts="y/N"; _label="N" ;;
    esac
    printf '%s (%s) [default %s] ' "$_msg" "$_opts" "$_label" > /dev/tty
    read -r _answer < /dev/tty || _answer=""
    [ -z "$_answer" ] && _answer="$_default"
    echo "$_answer"
}

need_cmd() {
    command -v "$1" > /dev/null 2>&1 || {
        log_error "'$1' is required but not installed."
        exit 1
    }
}

# Root's own commands run directly; everyone else goes through sudo.
as_root() {
    if [ "$(id -u)" = "0" ]; then
        "$@"
    else
        need_cmd sudo
        sudo "$@"
    fi
}

detect_arch() {
    if [ "$(uname -s)" != "Linux" ]; then
        log_error "Unsupported operating system: $(uname -s). voice-type v5 requires Linux."
        exit 1
    fi
    case "$(uname -m)" in
        x86_64 | amd64) echo "x64" ;;
        aarch64 | arm64) echo "arm64" ;;
        *)
            log_error "Unsupported architecture: $(uname -m). voice-type ships x64 and arm64 Linux builds."
            exit 1
            ;;
    esac
}

get_latest_tag() {
    curl -sSfL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name":' \
        | sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/' \
        | head -n 1
}

# This repository publishes several majors from one release stream, and their
# assets are not interchangeable. Accept v5 tags only; anything older ships a
# different runtime that this script would misconfigure.
guard_major_version() {
    _tag="$1"
    if ! printf '%s\n' "$_tag" \
        | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$'; then
        log_error "Invalid release tag: $_tag"
        exit 1
    fi
    _major=$(echo "${_tag#v}" | cut -d. -f1)
    [ "$_major" -lt 5 ] || return 0

    if [ "$MODE" = "version" ]; then
        log_error "$_tag is not a v5 release; this installer only handles v5 and later."
        exit 1
    fi

    log_error "The latest published release is $_tag -- no v5 release exists yet."
    if [ -f go.mod ] && [ -f "$MAIN_PKG/main.go" ]; then
        log_error "You are in a source tree; build and install it with:  v5/install.sh --local"
    else
        log_error "This installer only installs v5; retry after its first release is published."
    fi
    exit 1
}

install_binary_file() {
    _src="$1"
    _target_dir="$PREFIX/bin"

    if [ ! -d "$_target_dir" ]; then
        mkdir -p "$_target_dir" 2> /dev/null || as_root mkdir -p "$_target_dir"
    fi

    log_info "Installing to $_target_dir/$BINARY_NAME"
    if [ -w "$_target_dir" ]; then
        install -m 755 "$_src" "$_target_dir/$BINARY_NAME"
    else
        as_root install -m 755 "$_src" "$_target_dir/$BINARY_NAME"
    fi

    case ":$PATH:" in
        *":$_target_dir:"*) ;;
        *) log_warn "$_target_dir is not in your PATH. Add it to run '$BINARY_NAME'." ;;
    esac
}

# The binary always goes to $PREFIX/bin, but a copy earlier on PATH -- typically
# an old build in ~/.local/bin -- keeps answering `voice-type` and makes the
# install look like it did nothing. Each directory is resolved with `pwd -P` so a
# trailing slash or a symlink does not read as a second copy. With no terminal to
# ask at, say so rather than delete unasked.
clear_path_shadows() {
    _dir=$(cd "$PREFIX/bin" 2> /dev/null && pwd -P) || return 0
    _target="$_dir/$BINARY_NAME"
    _copies=$(
        printf '%s\n' "$PATH" | tr ':' '\n' | while IFS= read -r _entry; do
            [ -n "$_entry" ] || _entry="."
            _real=$(cd "$_entry" 2> /dev/null && pwd -P) || continue
            if [ -f "$_real/$BINARY_NAME" ] && [ -x "$_real/$BINARY_NAME" ] &&
                [ "$_real/$BINARY_NAME" != "$_target" ]; then
                printf '%s\n' "$_real/$BINARY_NAME"
            fi
        done | sort -u
    )
    [ -n "$_copies" ] || return 0

    while IFS= read -r _copy; do
        [ -n "$_copy" ] || continue
        log_warn "Another $BINARY_NAME on your PATH: $(link_path "$_copy")"
        if ! has_tty; then
            log_warn "It will keep answering '$BINARY_NAME'. Remove it with: rm -f $_copy"
            continue
        fi
        case "$(prompt_yn "Remove it so $_target is the one that runs?" "Y")" in
            [Yy]*)
                if [ -w "$(dirname "$_copy")" ]; then
                    rm -f "$_copy"
                else
                    as_root rm -f "$_copy"
                fi
                log_info "Removed $_copy"
                ;;
            *) log_warn "Kept $_copy -- it will keep answering '$BINARY_NAME'" ;;
        esac
    done << EOF
$_copies
EOF
    log_info "Open shells may need 'hash -r' to pick up $_target."
}

build_local() {
    need_cmd go
    # The v5 tree lives in v5/, so --local works from anywhere in the checkout.
    _dir=$(dirname "$0")
    if [ -f "$_dir/go.mod" ]; then
        cd "$_dir"
    fi
    if [ ! -f "go.mod" ] || [ ! -f "$MAIN_PKG/main.go" ]; then
        log_error "--local must run from the v5 source tree (no go.mod/$MAIN_PKG/main.go here)."
        exit 1
    fi
    _ver="dev"
    [ -f VERSION ] && _ver=$(cat VERSION)
    log_info "Building $BINARY_NAME $_ver from source..."
    CGO_ENABLED=0 go build -ldflags="-s -w -X main.version=$_ver" -o "$TMP_DIR/$BINARY_NAME" "./$MAIN_PKG"
    install_binary_file "$TMP_DIR/$BINARY_NAME"
}

download_release() {
    need_cmd curl
    need_cmd tar

    if [ "$MODE" = "version" ]; then
        TAG="$VERSION_TAG"
    else
        log_info "Resolving the latest release..."
        TAG=$(get_latest_tag)
        [ -n "$TAG" ] || {
            log_error "Could not determine the latest release."
            exit 1
        }
    fi
    guard_major_version "$TAG"

    _file="${BINARY_NAME}-v5-linux-${ARCH}.tar.gz"
    _base="https://github.com/${REPO}/releases/download/${TAG}"

    log_info "Downloading $TAG ($ARCH)..."
    curl -sSfL "${_base}/${_file}" -o "$TMP_DIR/$_file"
    curl -sSfL "${_base}/checksums.txt" -o "$TMP_DIR/checksums.txt"

    _expected=$(grep " ${_file}\$" "$TMP_DIR/checksums.txt" | awk '{print $1}' | head -n 1)
    [ -n "$_expected" ] || {
        log_error "No checksum for $_file in checksums.txt."
        exit 1
    }

    if command -v sha256sum > /dev/null 2>&1; then
        _actual=$(sha256sum "$TMP_DIR/$_file" | awk '{print $1}')
    elif command -v shasum > /dev/null 2>&1; then
        _actual=$(shasum -a 256 "$TMP_DIR/$_file" | awk '{print $1}')
    else
        log_error "Neither sha256sum nor shasum found -- cannot verify the download."
        exit 1
    fi

    [ "$_expected" = "$_actual" ] || {
        log_error "Checksum mismatch for $_file. Refusing to install."
        exit 1
    }
    log_info "Checksum verified."

    tar -xzf "$TMP_DIR/$_file" -C "$TMP_DIR"

    _binary="$TMP_DIR/${BINARY_NAME}-${ARCH}/${BINARY_NAME}"
    _reported_version=$("$_binary" version)
    if [ "$_reported_version" != "${TAG#v}" ]; then
        log_error "Downloaded binary reports version $_reported_version, expected ${TAG#v}."
        exit 1
    fi
    install_binary_file "$_binary"
}

# Called when creating or replacing a config. An existing file is never edited to
# add a key.
#
# The key is a credential, so it is read with terminal echo off and echoed back
# as asterisks: it must not survive in scrollback, in a screen share, or in the
# terminal's own buffer. `stty -g` captures the exact prior state to restore --
# and the INT/TERM trap is mandatory, because a Ctrl-C between disabling echo and
# restoring it would hand the user back a shell that types invisibly.
ask_api_key() {
    # A key in the environment wins over the file, so there is nothing to ask.
    [ -z "${OPENROUTER_API_KEY:-}" ] || return 0
    has_tty || return 0

    # Echo goes off *before* the prompt is printed. Anything arriving between the
    # two -- unexpected input, a fast typist, an automated answer -- would otherwise be
    # echoed by the line discipline in that window.
    _stty_saved=$(stty -g < /dev/tty 2> /dev/null) || _stty_saved=""
    if [ -n "$_stty_saved" ]; then
        trap 'stty "$_stty_saved" < /dev/tty 2> /dev/null; exit 130' INT TERM
        stty -echo < /dev/tty 2> /dev/null || _stty_saved=""
    fi

    printf 'OpenRouter API key (hidden, blank to set it later): ' > /dev/tty
    read -r API_KEY < /dev/tty || API_KEY=""

    if [ -n "$_stty_saved" ]; then
        stty "$_stty_saved" < /dev/tty 2> /dev/null || true
        trap 'exit 130' INT TERM
        # Echo off swallowed the user's newline too, so this line both masks the
        # key and terminates the prompt. With no stty the terminal echoed the key
        # itself and there is nothing to mask.
        printf '%s\n' "$(printf '%s' "$API_KEY" | sed 's/./*/g')" > /dev/tty
    fi
}

# Writes a config, asking before it touches one that already exists. The prompt
# names the action it performs, so the default answer is the safe one: only an
# explicit yes replaces the file, and it does so without a backup.
write_config() {
    CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
    CONFIG_FILE="$CONFIG_DIR/voice-type.jsonc"
    _config_action="Wrote"

    if [ -f "$CONFIG_FILE" ]; then
        case "$(prompt_yn "Replace the existing config at $(link_path "$CONFIG_FILE")?" "N")" in
            [Yy]*) _config_action="Replaced" ;;
            *)
                chmod 600 "$CONFIG_FILE" || {
                    log_error "Could not restrict $CONFIG_FILE to mode 600."
                    exit 1
                }
                log_info "Keeping existing config at $(link_path "$CONFIG_FILE")"
                return 0
                ;;
        esac
    fi

    ask_api_key
    mkdir -p "$CONFIG_DIR"
    CONFIG_TMP=$(mktemp "$CONFIG_DIR/.voice-type.jsonc.XXXXXX")
    # The key lands on disk, so write a private same-directory temporary file
    # and atomically replace the config only after the complete write succeeds.
    (
        umask 077
        _json_key=$(printf '%s' "$API_KEY" | sed 's/\\/\\\\/g; s/"/\\"/g')
        printf '{\n    "api_key": "%s", // or set OPENROUTER_API_KEY, which wins\n' "$_json_key" > "$CONFIG_TMP"
        cat >> "$CONFIG_TMP" << 'EOF'
    "port": 3232,           // int 1024-65535

    // Run `voice-type models` for choices, prices, and vocabulary support.
    "model": "gpt-4o-transcribe",

    // Names and jargon the model would otherwise misspell, one list per
    // workspace. "general" rides along with every dictation; pick one of the
    // rest with `voice-type vocab set <name>`. Keep them short.
    "vocabulary": {
        "general": []
    },

    // Hand edits take effect on the next dictation; voice-type never writes
    // this file (a `vocab set` is recorded under ~/.local/state/voice-type).
}
EOF
    )
    chmod 600 "$CONFIG_TMP"
    mv -f "$CONFIG_TMP" "$CONFIG_FILE"
    CONFIG_TMP=""
    CONFIG_CREATED=1
    log_info "$_config_action $(link_path "$CONFIG_FILE")"
}

# Read from the file rather than from what this run happened to type: on a
# reinstall the key is already in the config and warning about it is a lie.
config_has_key() {
    [ -f "$CONFIG_FILE" ] || return 1
    sed 's|//.*||g' "$CONFIG_FILE" 2> /dev/null \
        | grep -Eq '"api_key"[[:space:]]*:[[:space:]]*"[^"]+"'
}

print_summary() {
    _installed=$("$PREFIX/bin/$BINARY_NAME" version 2> /dev/null) || _installed="unknown version"
    log_info "Installed $_installed at $(link_path "$PREFIX/bin/$BINARY_NAME")"

    if [ "$CONFIG_CREATED" = "1" ]; then
        log_info "Keyboard shortcuts, to set in your desktop environment:"
        log_info "  Dictate:            curl -s http://localhost:$PORT/toggle"
        log_info "  Start/stop daemon:  sh -c \"curl -s http://localhost:$PORT/exit || voice-type\""
    fi

    # Both of these leave voice-type unable to work, so they stay.
    if [ -z "${OPENROUTER_API_KEY:-}" ] && ! config_has_key; then
        log_warn "No API key yet. Set OPENROUTER_API_KEY, or add \"api_key\" to $(link_path "$CONFIG_FILE")"
    fi
}

main() {
    ARCH=$(detect_arch)

    TMP_DIR=$(mktemp -d)
    trap cleanup EXIT
    trap 'exit 130' INT TERM

    if [ "$MODE" = "local" ]; then
        build_local
    else
        download_release
    fi
    clear_path_shadows

    write_config
    print_summary
}

while [ $# -gt 0 ]; do
    case "$1" in
        --version)
            [ $# -ge 2 ] || { log_error "--version needs a tag, e.g. --version v5.0.0"; exit 1; }
            VERSION_TAG="$2"; MODE="version"; shift 2
            ;;
        --local) MODE="local"; shift ;;
        *) log_error "Unknown option: $1"; usage; exit 1 ;;
    esac
done

main
