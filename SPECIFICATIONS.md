<!--
Document : SPECIFICATIONS.md
Author : Bruno DELNOZ
Email : bruno.delnoz@protonmail.com
Version : v1.2.0
Date : 2026-04-28 12:00 UTC
-->

# SPECIFICATIONS.md

## Purpose
Define the task-scoped specification for the Voice Biometric Login repository.

## Scope
Task-scoped repository contract for local voice + PIN login on Linux/XFCE.

## Existing verified behavior
- Repository currently contains documentation-only baseline (`README.md`, `SPECIFICATIONS.md`, `SPECIFICATIONS_FR.md`, `AGENTS.md`).
- No executable authentication implementation is versioned yet.
- Intended architecture and behavior are defined in the existing specification texts.

## Functional requirements
1. Keep standard Linux username/password login always available.
2. Add optional voice-biometric path with mandatory PIN second factor.
3. Fail closed on capture/model/config/PIN errors.
4. Keep biometric and PIN materials local with strict permissions.
5. Provide reversible install/rollback approach for PAM/LightDM integration.

## Non-functional requirements
- Local-first security model (no cloud dependency for core authentication).
- Deterministic and auditable behavior via structured logs.
- Debian/Kali + XFCE + LightDM + PAM compatibility.

## Inputs
- Microphone audio sample.
- User identity context and enrolled voiceprint.
- PIN/code input.
- Local configuration files.

## Outputs
- Authentication decision (accept/reject).
- Operational and audit log events (without secret leakage).

## Files and directories concerned
- `README.md`
- `SPECIFICATIONS.md`
- `SPECIFICATIONS_FR.md`
- `SPECIFICATIONS_GLOBAL.md`
- Future runtime target directories described in README/specification.

## Interfaces and commands
Planned CLI surface (documented baseline):
- `voice-loginctl enroll --user <name>`
- `voice-loginctl verify --user <name> --simulate`
- `voice-loginctl set-pin --user <name>`
- `voice-loginctl status`

## Constraints and safety rules
- Voice-only authentication is forbidden.
- PIN-only access through voice path is forbidden.
- Fallback password login must remain enabled.
- Secrets/biometrics must not be logged.

## Validation and acceptance criteria
- Documentation files remain synchronized between EN/FR specs.
- Task-scoped spec stays consistent with README baseline.
- Any behavior change must be reflected in EN + FR specs in same task.

## Out-of-scope items
- Full source implementation of PAM helper/module in this task.
- Cloud authentication workflows.
- Non-Linux desktop/login stacks.

## Changelog
- v1.2.0 — 2026-04-28 12:00 UTC — Bruno DELNOZ
  - Add full metadata block.
  - Normalize to mandatory section structure.
  - Synchronize task-scoped baseline with current repository state.
  - Reason: complete markdown revision requested by user.
- v1.1.0 — 2026-04-28
  - Date alignment update from 2026-04-29 to 2026-04-28.
