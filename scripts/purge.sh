#!/usr/bin/env bash
set -euo pipefail
EXEC=0; PURGE_SECRETS=0
while [[ $# -gt 0 ]]; do case "$1" in --help|-h) echo "Usage: $0 [--exec] [--purge-secrets]"; exit 0;; --exec|-exe) EXEC=1;; --purge-secrets) PURGE_SECRETS=1;; esac; shift; done
[[ $EXEC -eq 1 ]] || { echo "SIMULATE: no deletion"; exit 0; }
rm -rf /usr/local/libexec/voice-login /usr/local/bin/voice-loginctl /opt/voice-login/venv
[[ $PURGE_SECRETS -eq 1 ]] && rm -rf /etc/voice-login/users
echo "Purged"
