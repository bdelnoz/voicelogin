# SPECIFICATIONS.md

## Project Name

Voice Biometric Login for Linux/XFCE

## Version

1.1 — 2026-04-29

---

## Purpose

This project defines and implements a local Linux login workflow using voice biometric
speaker verification combined with a PIN or numeric code, while preserving the standard
username/password login as a mandatory fallback.

Target environment: Debian/Kali Linux, XFCE, LightDM.

The system must not destructively replace the existing Linux authentication stack.
It adds an optional authentication path that can be enabled, disabled, tested,
and fully removed without reinstalling the system.

---

## Core Concept

```text
LightDM login screen
  ├── Standard Linux login:
  │     username + password  (always available)
  │
  └── Voice biometric login:
        1. user triggers voice login
        2. random numeric challenge displayed
        3. user reads challenge aloud
        4. speaker verification (identity check, text-independent)
        5. optional: acoustic challenge verification (Phase 6)
        6. PIN/code entry
        7. session opened only if both voice AND PIN pass
```

The voice step answers **who is speaking**, not **what was said**.
The PIN step is the mandatory second local factor.
The classic Linux login is never disabled.

---

## Target Platform

Primary:

```text
OS:              Kali Linux / Debian
Desktop:         XFCE
Display manager: LightDM
Auth layer:      PAM
Audio stack:     ALSA / PipeWire / PulseAudio compatibility
Python:          3.10+
Shell:           POSIX-compatible (installer, control scripts)
```

Secondary:

```text
Other Debian-based distributions using LightDM and PAM
```

Out of scope:

```text
Windows / macOS
Cloud-only authentication
Remote SSH voice authentication (default off)
Full display manager replacement
```

---

## Functional Requirements

1. Standard Linux fallback login (username/password) always available.
2. Separate, optional voice biometric authentication path.
3. Local PIN/code verification after successful voice check.
4. Safe enrollment process (multiple samples, quality check).
5. Safe re-enrollment process.
6. Test mode: full auth check without touching real login behavior.
7. Disable and rollback mechanism.
8. Structured logging without leaking secrets (two separate log files).
9. Strict file permissions on all biometric and PIN material.
10. XFCE sessions launched through LightDM via normal PAM/logind path.

---

## Authentication Requirements

The voice-login path requires:

```text
voice biometric match
AND
PIN/code match
```

- Voice alone: **forbidden**.
- PIN alone via voice-login path: **forbidden**.
- Normal Linux login path: remains fully independent, uses existing PAM/password flow.

---

## Voice Biometric Requirements

### Speaker Verification Model

The recommended implementation for the prototype (Phase 2) and production (Phase 4+):

```text
Primary:   SpeechBrain + ECAPA-TDNN
           (pretrained model: spkrec-ecapa-voxceleb)
           Speaker embeddings: 192-dimensional float32 vectors
           Similarity metric: cosine similarity

Prototype alternative (Phase 2 only):
           resemblyzer
           (simpler, lower accuracy, acceptable for early testing)
```

SpeechBrain is the recommended long-term choice.
resemblyzer may be used for the Phase 2 offline prototype if SpeechBrain setup is
deferred, but the final system must use ECAPA-TDNN or equivalent.

### Embedding Storage Format

Enrolled voiceprint stored as:

```text
voiceprint.embedding    — NumPy .npy file, float32 array, shape (192,)
voiceprint.meta.json    — enrollment metadata (see Enrollment section)
```

NumPy `.npy` format is preferred: compact binary, loaded in a single call,
no parsing ambiguity.

### Verification Threshold

Initial recommended threshold (cosine similarity, ECAPA-TDNN):

```text
Threshold: 0.75  (configurable in config.toml)
```

A score >= threshold passes speaker verification.
The threshold value must be validated against real enrollment samples during Phase 2.
Threshold tuning guidance must be documented per model.

### Text-Independent Verification

The user may speak arbitrary content during verification.
The system verifies speaker identity, not the specific phrase.

For anti-replay, a random numeric challenge is displayed and the user reads it aloud.
This gives a short time window of known spoken content without requiring
full speech recognition.

### Challenge Mode

```text
1. Generate random 4–6 digit challenge.
2. Display at login UI.
3. User reads challenge aloud.
4. System performs speaker verification.
5. [Phase 6] Optional: STT-based acoustic challenge verification
             using whisper.cpp (local, no cloud dependency).
6. User enters PIN/code.
```

Challenge properties:

```text
Length:   4–6 digits (configurable)
TTL:      30 seconds (non-configurable minimum)
Reuse:    forbidden — each challenge is single-use
Storage:  in-memory only during the active login attempt
```

The system must clearly separate:

```text
Speaker verification  = who is speaking   (core, Phase 2)
Speech recognition    = what was said     (optional, Phase 6 only)
```

---

## PIN/Code Requirements

1. Stored only as a password hash (never in clear text).
2. Never logged under any circumstance.
3. Configurable length (minimum 4 digits, recommended 6+).
4. Lockout or progressive delay after repeated failures (Phase 3).
5. Changeable via dedicated administrative command.

Required hashing:

```text
Argon2id   (preferred)
yescrypt   (acceptable alternative)
bcrypt     (acceptable alternative)
```

**SHA-256 alone is not acceptable for PIN storage.**

Lockout policy (Phase 3):

```text
After 3 consecutive failures:  30-second delay
After 5 consecutive failures:  5-minute lockout
After 10 consecutive failures: administrative unlock required
```

Lockout applies per-user and is written to the audit log.
Lockout state is stored in `/var/lib/voice-login/runtime/<user>.state`.

---

## PAM Requirements

Final authentication decision flows through PAM.

Recommended architecture:

```text
LightDM greeter / helper trigger
  ↓
PAM service: /etc/pam.d/voice-login  (dedicated, not lightdm)
  ↓
pam_exec  →  voice-login-helper  (root-owned, not writable by users)
  ↓
exit 0 = accepted
exit 1 = rejected
```

Phase 4+ may implement a custom PAM module (`pam_voice_login.so`) to replace
the `pam_exec` approach for robustness and cleaner error handling.

PAM integration must not affect:

```text
sudo
su
TTY login
SSH login
existing LightDM password login
```

Unless explicitly and intentionally configured by the administrator.

The dedicated PAM service (`/etc/pam.d/voice-login`) must be tested in isolation
before any modification to `/etc/pam.d/lightdm`.

---

## LightDM/XFCE Requirements

The system must launch XFCE sessions through the standard display manager path
(LightDM → PAM → logind). Direct invocation of `startxfce4` is forbidden
in any production or semi-production context.

Integration options (in order of preference):

1. Wrapper around the existing LightDM GTK greeter (recommended for Phase 5).
2. Dedicated custom greeter (acceptable but higher complexity).
3. Manual PAM-only testing without greeter modification (Phase 4 only).

The voice login UI button must not appear unless the voice-login system is
fully enrolled and enabled for the target user.

---

## Security Model

### Threats Considered

1. Replay attack using a recorded voice sample.
2. AI voice cloning / voice synthesis.
3. Voice conversion (speaker style transfer).
4. Live impersonation.
5. Theft of voiceprint embedding files.
6. Theft of PIN hash file.
7. Local privilege escalation via helper scripts.
8. Greeter compromise (UI injection).
9. Microphone unavailability or hardware spoofing.
10. Denial of service via repeated failed attempts.
11. Accidental user lockout.
12. Debug logs leaking sensitive material.
13. Shell injection via usernames, audio file paths, or greeter inputs.

### Minimum Security Rules

1. Voice-only login: **forbidden**.
2. PIN/code required after voice match.
3. Normal password login: **always available**.
4. Biometric files: readable only by `root` (or dedicated service user if implemented).
5. PIN hash files: same as biometric files.
6. Helper binaries/scripts: not writable by normal users (`root:root 755`).
7. No shell injection from any external input.
8. No world-writable runtime directory.
9. No secrets in command-line arguments.
10. No secrets in logs (PIN, audio, full biometric vector, hash value).
11. No enrollment from unauthenticated context.
12. No destructive PAM/LightDM modification without timestamped backup.

### Dedicated Service User (Phase 4+)

A dedicated system user `voice-login` (no shell, no home) may be introduced
to run the helper, reducing the attack surface compared to running everything as root.
This is optional in the prototype phase but recommended before production deployment.

```text
voice-login system user:
  UID/GID: allocated by adduser --system
  shell:   /usr/sbin/nologin
  home:    none
  groups:  audio (for microphone access)
```

---

## File Layout

```text
/etc/voice-login/                   root:root 700
  config.toml                       root:root 600
  users/                            root:root 700
    <user>/                         root:root 700
      voiceprint.embedding          root:root 600  (numpy .npy, float32 192-dim)
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

/run/voice-login/                   root:root 700  (tmpfs, cleared on reboot)
  <session-id>.wav                  root:root 600  (deleted after processing)

/var/lib/voice-login/               root:root 700
  runtime/                          root:root 700
    <user>.state                    root:root 600  (lockout state)
  cache/                            root:root 700

/var/log/voice-login/               root:adm 750
  voice-login.log                   root:adm 640  (operational + debug events)
  audit.log                         root:adm 640  (auth decisions only, no scores)

/var/backups/voice-login/
  YYYY-MM-DD_HHMMSS/
    pam.d_lightdm
    pam.d_lightdm-greeter
    lightdm.conf
    lightdm-gtk-greeter.conf
```

### Log Separation Policy

`audit.log` must contain only:

```text
timestamp | component | user | action | result | reason_category
```

Example:

```text
2026-04-29T10:00:00Z voice-login-helper user=nox action=verify result=failed reason=voice_below_threshold
2026-04-29T10:01:00Z voice-login-helper user=nox action=verify result=failed reason=pin_mismatch
2026-04-29T10:02:00Z voice-login-helper user=nox action=lockout reason=threshold_exceeded duration=300s
```

`voice-login.log` may additionally contain:

```text
score=0.61 threshold=0.75
model=spkrec-ecapa-voxceleb
sample_duration=4.2s
```

**Neither log may contain: PIN, spoken phrase, raw audio, full biometric vector, hash value.**

---

## Audio Capture Requirements

1. Use explicitly configured microphone device where possible (set in `config.toml`).
2. Fail closed immediately if no microphone is available.
3. Fixed sample rate: **16000 Hz** (required by ECAPA-TDNN; configurable for other models).
4. Temporary audio stored exclusively in `/run/voice-login/` (`root:root 700`).
5. Temporary file deleted immediately after embedding extraction.
6. Raw audio never retained by default (debug mode requires explicit flag).
7. Minimum valid sample duration: **2 seconds of active speech** (silence-rejected).
8. Maximum recording duration: **10 seconds** (timeout enforced).

---

## Enrollment Requirements

Enrollment must occur only after successful local authentication (password or sudo).

Enrollment procedure:

```text
Collect 5 to 10 voice samples
  - 3 to 8 seconds of active speech each
  - different spoken content per sample
  - varying speaking rhythm and pace
  - reject samples below SNR threshold or below 2s active speech
Average embeddings or store per-sample + compute centroid
Write voiceprint.embedding (numpy .npy)
Write voiceprint.meta.json
```

`voiceprint.meta.json` must contain:

```text
{
  "model":          "spkrec-ecapa-voxceleb",
  "model_version":  "<version string>",
  "sample_rate":    16000,
  "embedding_dim":  192,
  "created_at":     "2026-04-29T10:00:00Z",
  "n_samples":      7,
  "threshold":      0.75,
  "enrolled_by":    "voice-login-enroll"
}
```

`voiceprint.meta.json` must **not** contain any PIN, audio data, or secret material.

---

## Verification Requirements

1. Capture a fresh audio sample (microphone, `/run/voice-login/`).
2. Validate sample quality (duration, SNR).
3. Extract speaker embedding (ECAPA-TDNN → float32 192-dim vector).
4. Compute cosine similarity with enrolled voiceprint.
5. Compare score against configured threshold.
6. If voice passes: proceed to PIN/code verification.
7. If voice fails: reject immediately, log reason, do not request PIN.
8. Return strict success (0) or failure (1).
9. Delete temporary audio immediately after step 3.

---

## Anti-Replay and Liveness

Phase 2: basic challenge display (numeric, 30s TTL, non-reusable).

Phase 6: optional acoustic challenge verification via `whisper.cpp` (local STT):

```text
1. Generate 4–6 digit random challenge.
2. Display at login UI.
3. Record user reading the challenge.
4. Verify speaker identity (ECAPA-TDNN).
5. [Phase 6] Run whisper.cpp locally to transcribe.
6. [Phase 6] Compare transcript to expected challenge.
7. Prompt for PIN/code.
```

`whisper.cpp` is the approved STT component (local, no network, already
known to this project). Model: `ggml-small.bin` or `ggml-base.bin` for CPU.

---

## Python Dependencies

```text
Required (Debian/Kali packages):
  python3 (>=3.10)
  python3-numpy
  python3-scipy
  python3-pip
  python3-venv
  portaudio19-dev
  libsndfile1

Required (Python venv, pip):
  speechbrain       >= 0.5
  sounddevice
  argon2-cffi
  torch             (CPU build acceptable for prototype)

Optional (Phase 6 only):
  whisper.cpp       (compiled locally, no pip package)
  ggml-small.bin    (whisper model, downloaded once)
```

All packages must come from Kali/Debian official repositories or local pip install
into a dedicated venv. **No external repository is added automatically.**

---

## Command-Line Tools

### voice-loginctl

```bash
voice-loginctl enroll    --user <user>
voice-loginctl verify    --user <user> [--simulate]
voice-loginctl test-audio
voice-loginctl set-pin   --user <user>
voice-loginctl status    [--user <user>]
voice-loginctl doctor
voice-loginctl enable
voice-loginctl disable
voice-loginctl rollback
voice-loginctl purge     [--user <user>]
```

### Required Shell Script Options

All shell scripts must implement:

```text
--help        print usage
--simulate    dry run, no system changes, no PAM interaction
--exec        required to perform any real action
--install     install the component
--uninstall   remove the component
--status      print current state
--rollback    restore previous configuration from backup
--purge       full removal including user data (requires --exec)
--changelog   print version history
--prerequis   check and list prerequisites
```

No destructive operation executes without an explicit `--exec` flag.

---

## Failure Behavior

The voice-login path fails closed in all of the following cases:

```text
Microphone unavailable or fails to open
Model file missing or fails to load
Configuration file invalid or missing
Audio sample too short or silent
Voice score below threshold
PIN mismatch
Challenge TTL expired
Voiceprint file corrupt or unreadable
Permission error on any required file
Unexpected exception in helper
```

In all cases:
- The voice-login attempt is rejected (exit 1).
- The failure reason is logged (category only, no secrets).
- The normal password login path remains available.

---

## Backup and Rollback

Before modifying any system file, the installer creates a timestamped backup:

```text
/var/backups/voice-login/YYYY-MM-DD_HHMMSS/
  pam.d_lightdm
  pam.d_lightdm-greeter
  lightdm.conf
  lightdm-gtk-greeter.conf
```

`voice-loginctl rollback` restores all backed-up files to their original paths.
Rollback is available at any phase and requires `--exec`.

---

## Development Phases

### Phase 1 — Repository Skeleton

Deliver:

```text
README.md
SPECIFICATIONS.md
SPECIFICATIONS_FR.md
CHANGELOG.md
WHY.md
AGENTS.md
.gitignore
```

### Phase 2 — Offline Voice Prototype

Deliver (no PAM/LightDM change):

```text
voice-login-enroll    (CLI, SpeechBrain or resemblyzer)
voice-login-test      (audio capture test, model load test)
verify prototype      (CLI, cosine similarity, configurable threshold)
config.toml           (model path, sample rate, threshold, device)
threshold calibration notes
```

### Phase 3 — PIN + Rate Limiting

Deliver (no PAM/LightDM change):

```text
voice-login-pin-change   (Argon2id hash creation)
PIN verification         (integrated with verify flow)
lockout/delay policy     (3/5/10 attempts, per-user state)
audit.log                (auth decisions, no scores)
voice-login.log          (debug events, scores permitted)
```

### Phase 4 — PAM Test Integration

Deliver (test PAM service only, do not touch lightdm PAM):

```text
/etc/pam.d/voice-login   (dedicated service, not lightdm)
pam_exec prototype
voice-loginctl rollback
voice-loginctl doctor
manual test procedure
```

### Phase 5 — LightDM/XFCE Integration

Deliver (with backup, with rollback):

```text
voice login UI trigger in greeter
challenge display
audio capture from greeter context
PIN dialog
full PAM-backed auth flow
fallback to standard login
```

### Phase 6 — Hardening

Deliver:

```text
whisper.cpp acoustic challenge verification (optional)
anti-replay improvements
rate limiting review
permissions audit
log review
dedicated service user (voice-login system user)
Debian package skeleton
```

---

## Non-Goals

1. Replacing Linux passwords globally.
2. Enabling voice authentication for SSH by default.
3. Storing raw voice samples permanently by default.
4. Depending on cloud voice services.
5. Using online APIs for local login.
6. Modifying firewall rules.
7. Modifying unrelated desktop services.
8. Installing non-Debian/non-Kali repositories without explicit approval.
9. Breaking TTY or recovery access.
10. Hiding authentication failures.

---

## Privacy Requirements

1. All biometric data stays local.
2. No cloud processing of any kind.
3. No telemetry.
4. No raw audio retention by default.
5. Exact inventory of stored data documented per user directory.
6. `purge` command removes all voiceprint, PIN, and state data for a user.
7. Re-enrollment from scratch supported at any time.

---

## Acceptance Criteria

The system is acceptable when all of the following pass:

1. Standard username/password login works correctly and independently.
2. Voice-login prototype runs fully from CLI without modifying LightDM.
3. Wrong speaker is consistently rejected (score below threshold).
4. Wrong PIN is rejected after correct voice match.
5. Session opens only when both voice and PIN pass.
6. Any audio/model/config failure causes closed-failure rejection.
7. `rollback` restores original PAM/LightDM configuration exactly.
8. Audit log is useful; contains no PIN, audio, vector, or hash.
9. All biometric and PIN files have correct strict permissions.
10. The system can be fully disabled via `voice-loginctl disable` without reinstall.

---

## Initial Recommended Implementation Target

```text
User:     nox (single local user)
Machine:  single local machine (casablanca or koutoubia)
Session:  XFCE via LightDM
Model:    SpeechBrain ECAPA-TDNN (spkrec-ecapa-voxceleb)
PIN hash: Argon2id
No SSH integration
No cloud dependency
```
