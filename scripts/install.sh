#!/usr/bin/env bash
# /workspace/voicelogin/scripts/install.sh
# Author: Bruno DELNOZ
# Email: bruno.delnoz@protonmail.com
# Purpose: Install voice-login files with strict venv-only Python dependency management.
# Version: v1.1.0
# Date: 2026-04-28
# Changelog:
# - v1.1.0 (2026-04-28): Enforced strict venv path, critical import validation, and explicit Python 3.13.x compatibility logging.
# - v1.0.0 (2026-04-28): Initial implementation.
set -euo pipefail

SIMULATE=1
DEST_DIR="/opt/voice-login"
VENV_DIR="/opt/voice-login/venv"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) echo "Usage: $0 [--simulate|-s] [--exec|-exe] [--dest_dir DIR] [--venv-dir DIR]"; exit 0 ;;
    --simulate|-s) SIMULATE=1 ;;
    --exec|-exe) SIMULATE=0 ;;
    --dest_dir) DEST_DIR="$2"; shift ;;
    --venv-dir) VENV_DIR="$2"; shift ;;
    *) echo "Unknown: $1"; exit 2 ;;
  esac
  shift
done

PYTHON_VERSION="$(python3 -c 'import platform; print(platform.python_version())')"
echo "System Python: ${PYTHON_VERSION}"
echo "Target venv: ${VENV_DIR}"

if [[ $SIMULATE -eq 1 ]]; then
  echo "SIMULATE mode enabled; no changes applied."
  exit 0
fi

[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
mkdir -p "$DEST_DIR" /var/backups/voice-login "$(dirname "$VENV_DIR")"

python3 -m venv "$VENV_DIR" || { echo "KO: venv creation failed at $VENV_DIR"; exit 1; }
"$VENV_DIR/bin/python" -m ensurepip --upgrade >/dev/null 2>&1 || { echo "KO: pip missing in venv"; exit 1; }
"$VENV_DIR/bin/python" -m pip install --upgrade pip
"$VENV_DIR/bin/python" -m pip install -r requirements.txt

CRITICAL_MODULES=(numpy scipy sounddevice argon2 torch speechbrain)
for mod in "${CRITICAL_MODULES[@]}"; do
  "$VENV_DIR/bin/python" -c "import $mod" >/dev/null 2>&1 || { echo "KO: import failed in venv: $mod"; exit 1; }
done

if [[ "$PYTHON_VERSION" == 3.13.* ]]; then
  echo "Python 3.13.x compatibility: OK (critical imports verified in venv)"
fi

mkdir -p /usr/local/libexec/voice-login /usr/local/bin
install -m 0755 src/voice_login/voice_loginctl.py /usr/local/bin/voice-loginctl
for f in voice_login_helper.py voice_login_enroll.py voice_login_test.py voice_login_pin_change.py; do
  install -m 0755 "src/voice_login/$f" "/usr/local/libexec/voice-login/${f%.py}"
done

echo "Install complete"
