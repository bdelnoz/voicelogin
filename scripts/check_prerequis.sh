#!/usr/bin/env bash
# /workspace/voicelogin/scripts/check_prerequis.sh
# Author: Bruno DELNOZ
# Email: bruno.delnoz@protonmail.com
# Purpose: Validate local prerequisites for voice-login with strict virtual environment checks.
# Version: v1.1.0
# Date: 2026-04-28
# Changelog:
# - v1.1.0 (2026-04-28): Added strict venv validation, Python 3.13.x compatibility checks, and critical import tests.
# - v1.0.0 (2026-04-28): Initial implementation.
set -euo pipefail

SIMULATE=0
VERBOSE=0
PYTHON_BIN="python3"
VENV_DIR="./.venv_check"

print_help() {
  cat <<'HELP'
Usage: scripts/check_prerequis.sh [OPTIONS]

Options:
  --help, -h             Show this help.
  --simulate, -s         Dry-run mode (reports checks without dependency installs).
  --verbose              Enable verbose shell tracing.
  --python PATH          Python interpreter to use (default: python3).
  --venv-dir PATH        Temporary venv path for checks (default: ./.venv_check).
HELP
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) print_help; exit 0 ;;
    --simulate|-s) SIMULATE=1 ;;
    --verbose) VERBOSE=1 ;;
    --python) PYTHON_BIN="$2"; shift ;;
    --venv-dir) VENV_DIR="$2"; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
  shift
done

[[ $VERBOSE -eq 1 ]] && set -x

missing=0
critical_fail=0

for cmd in lightdm bash "$PYTHON_BIN"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "MISSING command: $cmd"
    missing=1
  else
    echo "OK command: $cmd"
  fi
done

PYV_SYSTEM="$($PYTHON_BIN -c 'import platform; print(platform.python_version())' 2>/dev/null || true)"
echo "System Python version: ${PYV_SYSTEM:-unavailable}"

if ! "$PYTHON_BIN" -m venv --help >/dev/null 2>&1; then
  echo "KO: python3-venv support missing for interpreter: $PYTHON_BIN"
  missing=1
else
  echo "OK: python3-venv support available"
fi

rm -rf "$VENV_DIR"
if ! "$PYTHON_BIN" -m venv "$VENV_DIR" >/dev/null 2>&1; then
  echo "KO: cannot create virtual environment at $VENV_DIR"
  missing=1
else
  echo "OK: virtual environment created at $VENV_DIR"
fi

if [[ -x "$VENV_DIR/bin/python" ]]; then
  PYV_VENV="$($VENV_DIR/bin/python -c 'import platform; print(platform.python_version())' 2>/dev/null || true)"
  echo "Venv Python version: ${PYV_VENV:-unavailable}"

  if ! "$VENV_DIR/bin/python" -m ensurepip --upgrade >/dev/null 2>&1; then
    echo "KO: pip unavailable inside venv"
    missing=1
  else
    echo "OK: pip available inside venv"
  fi

  if [[ $SIMULATE -eq 0 ]]; then
    "$VENV_DIR/bin/python" -m pip install --upgrade pip >/dev/null
    "$VENV_DIR/bin/python" -m pip install -r requirements.txt >/dev/null
  fi

  CRITICAL_MODULES=(numpy scipy sounddevice argon2 torch speechbrain)
  for mod in "${CRITICAL_MODULES[@]}"; do
    if "$VENV_DIR/bin/python" -c "import $mod" >/dev/null 2>&1; then
      echo "OK import: $mod"
    else
      echo "KO import: $mod"
      critical_fail=1
    fi
  done

  if [[ "$PYV_VENV" == "3.13.12" || "$PYV_SYSTEM" == "3.13.12" ]]; then
    echo "INFO: Python 3.13.12 detected, compatibility tested module-by-module above."
  fi
fi

rm -rf "$VENV_DIR"

if [[ $missing -ne 0 || $critical_fail -ne 0 ]]; then
  echo "Prerequisites check: KO"
  exit 1
fi

echo "Prerequisites check: OK"
exit 0
