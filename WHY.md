# WHY

## Why this project exists
Linux graphical login generally relies on username/password only.
This project documents a local, reversible voice-biometric + PIN path to strengthen local authentication.

## Security rationale
- Voice alone is not enough.
- PIN alone through voice path is not enough.
- Standard password fallback always remains available.

## Design priorities
- Local processing first.
- Fail-closed behavior.
- Strict permissions and auditable operational logs.
