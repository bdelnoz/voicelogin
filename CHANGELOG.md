# CHANGELOG

## v1.4.1 - 2026-04-28
- Updated Markdown documentation set to reflect current executable prototype structure.
- Expanded repository file inventory in `README.md`.
- Updated install status and quick-start guidance in `INSTALL.md`.
- Extended project rationale in `WHY.md`.

## v1.2.0 - 2026-04-28
- Full markdown revision pass completed.
- Added normalized metadata and mandatory sections in `SPECIFICATIONS.md` and `SPECIFICATIONS_FR.md`.
- Added `SPECIFICATIONS_GLOBAL.md` as repository-wide baseline.

## v1.1.0 - 2026-04-28
- Updated date alignment in EN/FR specifications.

## v1.3.0 - 2026-04-28
- Added executable repository skeleton (`scripts/`, `src/voice_login/`, `config/`, `tests/`, `infos/`).
- Added venv-first shell scripts for prerequisite check, install, simulate, run, stop, rollback, and purge.
- Added Python prototype commands (`voice-loginctl`, helper/enroll/test/pin-change stubs).
- Added `.gitignore` and `requirements.txt` for local dev/runtime dependency control.
- Updated `SPECIFICATIONS.md`, `SPECIFICATIONS_FR.md`, and `SPECIFICATIONS_GLOBAL.md` to reflect approved behavior.

## v1.4.0 - 2026-04-28
- Hardened `scripts/check_prerequis.sh` with strict venv creation/pip/module import checks and explicit Python 3.13.12 handling.
- Hardened `scripts/install.sh` to refuse global pip usage, require venv success, and fail on critical import incompatibility.
- Implemented real `voice-loginctl doctor` checks with non-zero exit on failures.
- Synchronized specification and documentation files for mandatory venv + Python 3.13.12 behavior.
