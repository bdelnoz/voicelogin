# INSTALL

## Current repository state
This repository is currently documentation-first.
No installable runtime binary is shipped yet.

## Planned installation target
The project intends to support Debian/Kali Linux with XFCE + LightDM and PAM.

## Status
- Documentation baseline: available.
- Implementation scripts/binaries: pending.

## Prototype Quick Start (2026-04-28)

1. Run prerequisite check:
   - `scripts/check_prerequis.sh --help`
2. Simulate installation:
   - `scripts/install.sh --simulate`
3. Run simulation flow:
   - `scripts/simulate.sh --help`

Use `--exec` only in controlled root environment.
