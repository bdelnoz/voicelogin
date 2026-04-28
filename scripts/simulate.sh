#!/usr/bin/env bash
set -euo pipefail
USER_NAME=""; VENV_DIR="/opt/voice-login/venv"
while [[ $# -gt 0 ]]; do case "$1" in --help|-h) echo "Usage: $0 --user NAME [--venv-dir DIR]"; exit 0;; --user) USER_NAME="$2"; shift;; --venv-dir) VENV_DIR="$2"; shift;; *) shift;; esac; shift; done
[[ -n "$USER_NAME" ]] || { echo "Missing --user"; exit 2; }
"$VENV_DIR/bin/python" src/voice_login/voice_loginctl.py verify --user "$USER_NAME" --simulate
