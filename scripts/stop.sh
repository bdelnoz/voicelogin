#!/usr/bin/env bash
set -euo pipefail
pkill -f voice-login-helper || true
rm -rf /run/voice-login/* 2>/dev/null || true
echo "Stopped"
