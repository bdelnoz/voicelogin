#!/usr/bin/env bash
# /workspace/voicelogin/scripts/check_prerequis.sh
# Author: Bruno DELNOZ
# Email: bruno.delnoz@protonmail.com
# Purpose: Validate local prerequisites for voice-login.
# Version: v1.0.0
# Date: 2026-04-28
# Changelog:
# - v1.0.0 (2026-04-28): Initial implementation.
set -euo pipefail
SIMULATE=0; VERBOSE=0; PYTHON_BIN="python3"
while [[ $# -gt 0 ]]; do case "$1" in --help|-h) echo "Usage: $0 [--simulate] [--verbose] [--python PATH]"; exit 0;; --simulate|-s) SIMULATE=1;; --verbose) VERBOSE=1;; --python) PYTHON_BIN="$2"; shift;; *) echo "Unknown: $1"; exit 2;; esac; shift; done
missing=0
for c in lightdm python3 bash; do command -v "$c" >/dev/null || { echo "MISSING: $c"; missing=1; }; done
PYV="$($PYTHON_BIN -V 2>/dev/null || true)"; echo "Detected Python: ${PYV:-unavailable}"
$PYTHON_BIN -m venv ./.venv_check >/dev/null 2>&1 || { echo "KO: cannot create venv"; missing=1; }
if [[ -x ./.venv_check/bin/python ]]; then ./.venv_check/bin/python -m ensurepip >/dev/null 2>&1 || missing=1; fi
rm -rf ./.venv_check
[[ $missing -eq 0 ]] && { echo "OK"; exit 0; } || { echo "KO"; exit 1; }
