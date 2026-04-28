# Voice Biometric Login for Linux/XFCE

## Overview

This repository implements a local Linux login mechanism based on voice biometric
speaker verification combined with a PIN/code, targeting Debian/Kali Linux with
XFCE and LightDM.

This project does **not** replace the classic Linux username/password login.
It adds an optional, reversible authentication path:

```text
Voice biometric verification (speaker identity)
+ PIN/code verification (second local factor)
= local session login via PAM
```

The standard Linux login remains available at all times as a mandatory fallback.

---

## Intended Login Flow

```text
LightDM login screen
  ├── Standard login:
  │     username + password  (always available)
  │
  └── Voice login:
        1. click voice login button
        2. system displays a random numeric challenge (e.g. "4917")
        3. user reads the challenge aloud
        4. speaker verification against enrolled voiceprint
        5. optional: acoustic challenge verification (Phase 6)
        6. user enters PIN/code
        7. session opens only if voice AND PIN both pass
```

---

## Core Objective

**Speaker verification** — not speech recognition.

The system answers:

```text
Is this the enrolled user's voice?
```

Not:

```text
What exact phrase did the user say?
```

The design supports **text-independent** speaker verification.
The spoken phrase may vary; only speaker identity is verified.

---

## Security Position

Voice biometric alone is **never sufficient** to open a session.

This project enforces:

```text
voice biometric match
AND
PIN/code match
= authentication
```

The system **fails closed**: any failure in audio capture, model loading,
configuration, voiceprint integrity, or PIN check rejects the attempt immediately.

---

## Target Environment

```text
OS:             Kali Linux / Debian
Desktop:        XFCE
Display manager: LightDM
Auth layer:     PAM
Audio stack:    ALSA / PipeWire / PulseAudio compatibility
Python:         3.10+  (speaker verification, PIN handling)
Shell:          POSIX-compatible scripts (installer, control tool)
```

Out of scope:

```text
Windows / macOS
Cloud authentication
SSH voice login (by default)
Voice-only login
```

---

## Repository Files

```text
README.md               — this file
SPECIFICATIONS.md       — English technical contract
SPECIFICATIONS_FR.md    — French reference version (authoritative)
CHANGELOG.md            — version history  [pending]
WHY.md                  — design rationale and threat model context  [pending]
AGENTS.md               — instructions for AI coding agents (Claude Code)
CLAUDE.md               — symlink → AGENTS.md
.gitignore
```

The primary technical contract is `SPECIFICATIONS.md` / `SPECIFICATIONS_FR.md`.

---

## Recommended Architecture

```text
LightDM greeter
  ↓
voice login button (UI trigger)
  ↓
voice-login-helper  (root-owned binary/script)
  ↓
  ├── audio capture  (/run/voice-login/, root:root 700)
  ├── speaker embedding extraction  (SpeechBrain / ECAPA-TDNN)
  ├── cosine similarity vs enrolled voiceprint
  ├── threshold check
  └── PIN/code verification  (Argon2id hash)
  ↓
PAM result (exit 0 / exit 1)
  ↓
XFCE session opened by display manager
```

PAM integration uses `pam_exec` in the prototype phase,
moving to a dedicated PAM module in Phase 4+.

---

## Expected Components

```text
voice-loginctl          — main control CLI  (/usr/local/bin/)
voice-login-helper      — core auth helper  (/usr/local/libexec/voice-login/)
voice-login-enroll      — enrollment tool
voice-login-test        — audio and model test (no PAM interaction)
voice-login-pin-change  — PIN management
PAM service file        — /etc/pam.d/voice-login
LightDM integration     — Phase 5
```

---

## File Layout

```text
/etc/voice-login/                   root:root 700
  config.toml                       root:root 600
  users/                            root:root 700
    <user>/                         root:root 700
      voiceprint.embedding          root:root 600  (numpy float32 array)
      voiceprint.meta.json          root:root 600
      pin.hash                      root:root 600  (Argon2id)
      policy.toml                   root:root 600

/usr/local/libexec/voice-login/     root:root 755
  voice-login-helper                root:root 755
  voice-login-enroll                root:root 755
  voice-login-test                  root:root 755
  voice-login-pin-change            root:root 755

/usr/local/bin/
  voice-loginctl                    root:root 755

/run/voice-login/                   root:root 700  (tmpfs, ephemeral audio)

/var/lib/voice-login/               root:root 700
  runtime/
  cache/

/var/log/voice-login/               root:adm 750
  voice-login.log                   root:adm 640  (operational events)
  audit.log                         root:adm 640  (auth decisions only)

/var/backups/voice-login/
  YYYY-MM-DD_HHMMSS/                (PAM/LightDM config snapshots)
```

---

## Minimum Security Rules

1. Voice alone never opens the session.
2. PIN alone never opens the session through the voice-login path.
3. Normal username/password login remains available at all times.
4. Biometric data is stored locally, never sent to a network service.
5. Biometric files are not world-readable (`root:root 600`).
6. PIN is stored as an Argon2id hash. Plain SHA-256 is not acceptable.
7. Raw audio is not retained after processing (unless debug mode explicitly enabled).
8. Logs must not contain PINs, audio, spoken phrases, or biometric vectors.
9. PAM and LightDM files are backed up before any modification.
10. A rollback command restores the previous working configuration.
11. No shell injection vector from usernames, audio paths, or greeter input.
12. No enrollment from an unauthenticated context.

---

## Example Control Commands

```bash
voice-loginctl enroll    --user nox
voice-loginctl verify    --user nox --simulate
voice-loginctl test-audio
voice-loginctl set-pin   --user nox
voice-loginctl status
voice-loginctl doctor
voice-loginctl enable
voice-loginctl disable
voice-loginctl rollback
voice-loginctl purge
```

---

## Development Roadmap

| Phase | Scope                                    | PAM/LightDM modified |
|-------|------------------------------------------|----------------------|
| 1     | Repository skeleton, documentation       | No                   |
| 2     | Offline CLI prototype (enroll + verify)  | No                   |
| 3     | PIN layer + rate limiting + audit log    | No                   |
| 4     | PAM test service (pam_exec prototype)    | Test service only    |
| 5     | LightDM/XFCE integration                 | Yes (with backup)    |
| 6     | Hardening, anti-replay, packaging        | Refinement           |

**Safe development rule:** do not modify the active LightDM/PAM stack until Phases 2 and 3
are fully stable and tested via CLI.

---

## Dependencies (indicative)

```text
Debian/Kali packages:
  python3 (>=3.10)
  python3-numpy
  python3-scipy
  python3-pip
  portaudio19-dev
  libsndfile1
  python3-venv

Python packages (via venv):
  speechbrain          (speaker verification, ECAPA-TDNN model)
  sounddevice          (audio capture)
  argon2-cffi          (PIN hashing)
  torch                (SpeechBrain dependency)

Optional (Phase 6 challenge verification):
  whisper.cpp          (local STT for challenge acoustic check)
```

No external repository is added automatically.
All packages must be available from Kali/Debian official repositories
or installed in a local Python venv.

---

## License

To be decided.
