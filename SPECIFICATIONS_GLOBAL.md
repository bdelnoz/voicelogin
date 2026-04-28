<!--
Document : SPECIFICATIONS_GLOBAL.md
Author : Bruno DELNOZ
Email : bruno.delnoz@protonmail.com
Version : v1.1.0
Date : 2026-04-28 00:00:00 UTC
-->
# SPECIFICATIONS_GLOBAL.md
## Purpose
Global repository baseline for local voice-login project targeting Kali/Debian XFCE/LightDM with PAM.
## Global scope
Documentation + implementation conventions, security model, venv-only Python policy, reversible auth integration.
## Stable verified repository behavior
Voice path is optional and must never remove username/password fallback.
## Repository architecture
Shell orchestration in `scripts/`; Python runtime logic in `src/voice_login`; local configuration in `config/`.
## Global functional requirements
Voice+PIN dual factor; fail-closed; rollback capability; non-destructive simulation path.
## Global non-functional requirements
No global pip installs; no secrets in logs; local-only biometric data; sensitive permissions enforced.
## Global inputs
CLI arguments, local user/audio/PIN/config data.
## Global outputs
Deterministic exits, logs, local artifacts, backups.
## Global files and directories
`scripts/`, `src/voice_login/`, `config/`, docs/specs, plus runtime Linux target directories.
## Global interfaces and commands
`voice-loginctl` command family and companion helpers.
## Global constraints and safety rules
Always keep classic login available; backup before PAM/LightDM changes; rollback mandatory.
## Global validation and acceptance criteria
Scripts and helpers executable, venv policy enforced, simulation available, docs synchronized.
## Task-scoped specification boundary
Task-specific implementation details remain in `SPECIFICATIONS.md` and `SPECIFICATIONS_FR.md`.
## Out-of-scope items
Cloud-mandatory auth, non-Linux targets, replacing standard password login.
## Changelog
- v1.1.0 (2026-04-28 00:00:00 UTC, Bruno DELNOZ): Aligned global baseline with executable venv-first prototype architecture.
- v1.0.0: Historical baseline entry preserved.
