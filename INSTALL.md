# INSTALL

## Current repository state
This repository now provides a runnable prototype baseline with shell orchestration
scripts and Python CLI helpers for local validation workflows.

## Planned installation target
The project intends to support Debian/Kali Linux with XFCE + LightDM and PAM.

## Status
- Documentation baseline: available.
- Implementation scripts: available in `scripts/`.
- Python command prototypes: available in `src/voice_login/`.

## Prototype Quick Start (2026-04-28)

1. Run prerequisite check:
   - `scripts/check_prerequis.sh --help`
2. Simulate installation:
   - `scripts/install.sh --simulate`
3. Run simulation flow:
   - `scripts/simulate.sh --help`
4. Run doctor checks from CLI prototype:
   - `voice-loginctl doctor`

Use `--exec` only in controlled root environment.

## Python and venv policy
- Python virtual environment is mandatory.
- The installer uses only `"$VENV_DIR/bin/python" -m pip ...` for dependency installation.
- Python 3.13.12 is explicitly validated through critical module import checks.
