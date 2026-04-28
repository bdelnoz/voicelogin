#!/usr/bin/env bash
# /workspace/voicelogin/scripts/install.sh
# Author: Bruno DELNOZ
# Email: bruno.delnoz@protonmail.com
# Purpose: Install voice-login files and Python venv.
# Version: v1.0.0
# Date: 2026-04-28
# Changelog:
# - v1.0.0 (2026-04-28): Initial implementation.
set -euo pipefail
SIMULATE=1; EXEC=0; DEST_DIR="/opt/voice-login"; VENV_DIR="/opt/voice-login/venv"
while [[ $# -gt 0 ]]; do case "$1" in --help|-h) echo "Usage: $0 [--simulate] [--exec] [--dest_dir DIR] [--venv-dir DIR]"; exit 0;; --simulate|-s) SIMULATE=1;; --exec|-exe) EXEC=1; SIMULATE=0;; --dest_dir) DEST_DIR="$2"; shift;; --venv-dir) VENV_DIR="$2"; shift;; *) echo "Unknown: $1"; exit 2;; esac; shift; done
echo "Python: $(python3 -V)"; echo "Venv: $VENV_DIR"
if [[ $SIMULATE -eq 1 ]]; then echo "SIMULATE mode"; exit 0; fi
[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
mkdir -p "$DEST_DIR" /var/backups/voice-login "$(dirname "$VENV_DIR")"
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/python" -m pip install --upgrade pip
"$VENV_DIR/bin/pip" install -r requirements.txt
mkdir -p /usr/local/libexec/voice-login /usr/local/bin
install -m 0755 src/voice_login/voice_loginctl.py /usr/local/bin/voice-loginctl
for f in voice_login_helper.py voice_login_enroll.py voice_login_test.py voice_login_pin_change.py; do install -m 0755 "src/voice_login/$f" "/usr/local/libexec/voice-login/${f%.py}"; done
echo "Install complete"
