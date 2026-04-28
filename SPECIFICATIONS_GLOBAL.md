<!--
Document : SPECIFICATIONS_GLOBAL.md
Author : Bruno DELNOZ
Email : bruno.delnoz@protonmail.com
Version : v1.0.0
Date : 2026-04-28 12:00 UTC
-->

# SPECIFICATIONS_GLOBAL.md

## Purpose
Define the stable, repository-wide baseline for Voice Biometric Login.

## Global scope
Repository-level architecture, constraints, interfaces, and long-term expectations.

## Stable verified repository behavior
- Documentation-first repository currently.
- Main design target: local biometric speaker verification + PIN for Linux graphical login.
- Standard Linux password login remains mandatory fallback.

## Repository architecture
- Documentation baseline in root Markdown files.
- Planned implementation areas: PAM integration, voice helper tooling, enrollment and policy management.

## Global functional requirements
1. Two-factor local flow on voice path (voice + PIN).
2. Reversible integration with safe rollback.
3. Local storage and strict permissions for sensitive artifacts.

## Global non-functional requirements
- Security-first default and fail-closed behavior.
- No secret leakage in logs.
- Debian/Kali + LightDM/PAM compatibility baseline.

## Global inputs
- Audio capture.
- User identity and local enrollment data.
- Local policy/configuration.

## Global outputs
- Authentication pass/fail decision.
- Structured audit/operational logs.

## Global files and directories
- Root docs: `README.md`, `AGENTS.md`, `SPECIFICATIONS*.md`.
- Planned runtime paths under `/etc/voice-login`, `/var/lib/voice-login`, `/var/log/voice-login`, `/run/voice-login`.

## Global interfaces and commands
Planned control entrypoint: `voice-loginctl` and helper tools described in README/spec.

## Global constraints and safety rules
- Never disable standard password login implicitly.
- Never allow voice-only or PIN-only on voice path.
- Keep biometric and PIN assets local and protected.

## Global validation and acceptance criteria
- Repository docs remain coherent across README and specifications.
- Global vs task-scoped boundaries are explicit and non-contradictory.

## Task-scoped specification boundary
Task-level deltas and operational refinements belong to:
- `SPECIFICATIONS.md`
- `SPECIFICATIONS_FR.md`

## Out-of-scope items
- Production packaging/release pipeline details.
- Kernel/audio-driver tuning guidance per hardware.

## Changelog
- v1.0.0 — 2026-04-28 12:00 UTC — Bruno DELNOZ
  - Initial global baseline created from current repository state.
  - Reason: mandatory global specification file setup.
