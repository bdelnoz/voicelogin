<!--
Document : SPECIFICATIONS_FR.md
Author : Bruno DELNOZ
Email : bruno.delnoz@protonmail.com
Version : v1.2.0
Date : 2026-04-28 00:00:00 UTC
-->
# SPECIFICATIONS_FR.md
## Objectif
Chemin d'authentification local Linux par biométrie vocale + PIN via PAM/LightDM, optionnel et réversible, avec fallback mot de passe toujours actif.
## Périmètre
Baseline exécutable du dépôt: scripts shell, helpers/CLI Python, venv obligatoire, flux simulation-first.
## Comportement vérifié
Dépôt initial documentation-first sans implémentation exécutable; cette tâche ajoute une baseline prototype.
## Exigences fonctionnelles
- Succès chemin vocal = voix ET PIN.
- Fail-closed sur toute erreur.
- Scripts requis dans `scripts/` et commandes runtime prévues.
- `check_prerequis.sh` teste OS/Python/venv/imports sans pip global.
- `install.sh` installe via venv uniquement et protège le login classique.
## Exigences non fonctionnelles
- venv obligatoire, aucun pip global, shebang runtime `/opt/voice-login/venv/bin/python`.
- logs sans secrets.
## Entrées
Options CLI, utilisateur, config locale, audio local, PIN.
## Sorties
Codes retour, messages courts, logs structurés, artefacts locaux.
## Fichiers et dossiers concernés
Scripts, package Python `src/voice_login`, `requirements.txt`, `config/config.example.toml`, `.gitignore`, cibles runtime Linux.
## Interfaces et commandes
`voice-loginctl` avec sous-commandes enroll/verify/set-pin/status/doctor/enable/disable/rollback/purge; `--help` obligatoire.
## Contraintes
Fallback mot de passe toujours disponible; backups avant changements sensibles PAM/LightDM; aucun secret en logs.
## Validation
Scripts exécutables, chemin venv opérationnel, simulation disponible, docs synchronisées.
## Hors périmètre
Cloud obligatoire, non-Linux, remplacement du login password.
## Changelog
- v1.2.0 (2026-04-28 00:00:00 UTC, Bruno DELNOZ): Ajout baseline exécutable venv-first et inventaire scripts/runtime.
- v1.1.0: Entrée historique conservée.
- v1.0.0: Entrée historique conservée.
