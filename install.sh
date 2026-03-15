#!/usr/bin/env bash
#
# Install Stream Spool as the command 'streamspool'.
# Run from the directory that contains stream-spool.sh.
#

set -euo pipefail

SCRIPT_SOURCE="${SCRIPT_SOURCE:-stream-spool.sh}"
INSTALL_NAME="streamspool"

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)}"
SRC="$SCRIPT_DIR/$SCRIPT_SOURCE"

if [[ ! -f "$SRC" ]]; then
    echo "Error: $SRC not found. Run this script from the folder that contains $SCRIPT_SOURCE." >&2
    exit 1
fi

if [[ -w /usr/local/bin ]]; then
    install -m 755 "$SRC" "/usr/local/bin/$INSTALL_NAME"
    echo "Installed to /usr/local/bin/$INSTALL_NAME. Run: $INSTALL_NAME"
elif command -v sudo &>/dev/null; then
    echo "Installing to /usr/local/bin (may prompt for password)."
    sudo install -m 755 "$SRC" "/usr/local/bin/$INSTALL_NAME"
    echo "Installed to /usr/local/bin/$INSTALL_NAME. Run: $INSTALL_NAME"
else
    INSTALL_DIR="${HOME}/.local/bin"
    mkdir -p "$INSTALL_DIR"
    install -m 755 "$SRC" "$INSTALL_DIR/$INSTALL_NAME"
    echo "Installed to $INSTALL_DIR/$INSTALL_NAME"
    if ! echo ":$PATH:" | grep -q ":$INSTALL_DIR:"; then
        echo "Add $INSTALL_DIR to your PATH (e.g. in ~/.bashrc):"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
    echo "Then run: $INSTALL_NAME"
fi
