#!/usr/bin/env bash
# Metadata setup. Safe to run at any time; does not install or launch anything.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HOME/.config/mactrans"

mkdir -p "$CONFIG/data" "$CONFIG/logs"
[ -L "$ROOT/AGENTS.md" ] || ln -sf CLAUDE.md "$ROOT/AGENTS.md"
chmod +x "$ROOT/scripts/"*.sh

echo "config:  $CONFIG"
echo "install: ./scripts/install.sh"
