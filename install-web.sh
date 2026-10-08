#!/usr/bin/env bash
# One-line installer for macOS:
#
#   curl -fsSL https://raw.githubusercontent.com/am1dreaming/Flying-Island-dark-for-VS-code/main/install-web.sh | bash
#
# Downloads the repository (main branch) into a temp folder and runs install.sh from it.
set -euo pipefail

REPO="am1dreaming/Flying-Island-dark-for-VS-code"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Downloading Flying Island from github.com/$REPO"
curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP"
SRC="$(dirname "$(find "$TMP" -maxdepth 2 -name install.sh | head -n 1)")"
[ -f "$SRC/install.sh" ] || { echo "install.sh not found in the downloaded archive"; exit 1; }

# bash explicitly: files uploaded through the GitHub website lose the executable bit.
bash "$SRC/install.sh"
