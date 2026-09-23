#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  [API-STRESS] INSTALLER                                          ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

BOLD=$(tput bold 2>/dev/null || true)
GREEN=$(tput setaf 2 2>/dev/null || true)
YELLOW=$(tput setaf 3 2>/dev/null || true)
RED=$(tput setaf 1 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)

echo "${BOLD}==> Installing api-stress...${RESET}"

if ! command -v docker &> /dev/null; then
    echo "${YELLOW}[WARNING] Docker is not installed or not in PATH.${RESET}"
    echo "api-stress requires Docker to run isolated container environments."
fi

TARGET_DIR="${HOME}/.local/bin"
mkdir -p "$TARGET_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_BIN="${SCRIPT_DIR}/bin/api-stress"

if [ ! -f "$SOURCE_BIN" ]; then
    echo "${RED}[ERROR] Binary source not found at: ${SOURCE_BIN}${RESET}"
    exit 1
fi

chmod +x "$SOURCE_BIN"

# Copy binary to destination
cp "$SOURCE_BIN" "${TARGET_DIR}/api-stress"
chmod +x "${TARGET_DIR}/api-stress"

# Also symlink markab-docker-stress for backwards compatibility
ln -sf "${TARGET_DIR}/api-stress" "${TARGET_DIR}/markab-docker-stress"

echo "${GREEN}[OK] Installed successfully:${RESET}"
echo "     - ${TARGET_DIR}/api-stress"
echo "     - ${TARGET_DIR}/markab-docker-stress (symlink)"

if [[ ":$PATH:" != *":${TARGET_DIR}:"* ]]; then
    echo "${YELLOW}[NOTE] Make sure ${TARGET_DIR} is in your PATH:${RESET}"
    echo "       export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
echo "Try running: ${BOLD}api-stress --help${RESET}"
