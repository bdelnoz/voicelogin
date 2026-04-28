<!--
Document : SPECIFICATIONS.md
Author : Bruno DELNOZ
Email : bruno.delnoz@protonmail.com
Version : v1.2.0
Date : 2026-04-28 00:00:00 UTC
-->
# SPECIFICATIONS.md

## Purpose
Local voice biometric + PIN authentication path for XFCE/LightDM via PAM, optional and reversible, with password fallback always available.

## Scope
Repository executable baseline: shell orchestration scripts, Python helpers/CLI, venv-only dependency model, simulation-first flow.

## Existing verified behavior
Documentation-first repository was present without executable implementation; this task introduces baseline scripts and Python prototypes.

## Functional requirements
- Voice path success requires voice match AND PIN match.
- Fail-closed on any operational/security error.
- Provide scripts in `scripts/`: check_prerequis, install, run, stop, simulate, purge, rollback.
- Provide runtime commands: voice-loginctl, voice-login-helper, voice-login-enroll, voice-login-test, voice-login-pin-change.
- `check_prerequis.sh` validates OS/Python/venv/pip/import path without global pip installation.
- `install.sh` creates tree, venv, installs dependencies in venv only, and keeps classic login safe.

## Non-functional requirements
- Python policy: venv mandatory, no global pip, runtime shebang uses `/opt/voice-login/venv/bin/python`.
- PIN hashing target: Argon2id.
- Logs: `/var/log/voice-login/*.log` without secrets.

## Inputs
CLI arguments, user context, local config, local audio, local PIN.

## Outputs
Exit codes, concise console messages, structured logs, local artifacts and backups.

## Files and directories concerned
- `scripts/*.sh`
- `src/voice_login/*.py`
- `requirements.txt`, `config/config.example.toml`, `.gitignore`
- runtime targets under `/etc/voice-login`, `/usr/local/libexec/voice-login`, `/usr/local/bin`, `/opt/voice-login`, `/run/voice-login`, `/var/log/voice-login`, `/var/backups/voice-login`.

## Interfaces and commands
- `voice-loginctl`: enroll, verify, set-pin, status, doctor, enable, disable, rollback, purge.
- Script `--help` mandatory; `--simulate` where relevant.

## Constraints and safety rules
- Preserve standard Linux password fallback.
- Never activate dangerous PAM/LightDM changes without backups.
- Never store secrets in logs.

## Validation and acceptance criteria
- Scripts exist and are executable.
- venv-only execution path is implemented.
- simulation path is available.
- repository docs and specs synchronized.

## Out-of-scope items
Cloud-required authentication, non-Linux targets, replacing standard password login.

## Changelog
- v1.2.0 (2026-04-28 00:00:00 UTC, Bruno DELNOZ): Added executable baseline with venv-first policy and script/runtime inventory.
- v1.1.0: Preserved historical entry.
- v1.0.0: Preserved historical entry.
