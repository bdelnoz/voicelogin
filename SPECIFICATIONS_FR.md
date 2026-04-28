<!--
Document : SPECIFICATIONS_FR.md
Author : Bruno DELNOZ
Email : bruno.delnoz@protonmail.com
Version : v1.2.0
Date : 2026-04-28 12:00 UTC
-->

# SPECIFICATIONS_FR.md

## Purpose
Définir la spécification de portée tâche pour le dépôt Voice Biometric Login.

## Scope
Contrat documentaire de portée tâche pour une connexion locale voix + PIN sur Linux/XFCE.

## Existing verified behavior
- Le dépôt contient actuellement une base documentaire uniquement (`README.md`, `SPECIFICATIONS.md`, `SPECIFICATIONS_FR.md`, `AGENTS.md`).
- Aucune implémentation exécutable d'authentification n'est encore versionnée.
- L'architecture et le comportement visés sont décrits dans les spécifications existantes.

## Functional requirements
1. Conserver en permanence le login Linux classique utilisateur/mot de passe.
2. Ajouter un chemin optionnel biométrie vocale avec second facteur PIN obligatoire.
3. Fonctionnement en échec fermé sur erreur capture/modèle/configuration/PIN.
4. Stockage local strict des données biométriques et PIN avec permissions fortes.
5. Intégration PAM/LightDM réversible avec capacité de rollback.

## Non-functional requirements
- Modèle de sécurité local-first (pas de dépendance cloud pour le cœur d'authentification).
- Comportement déterministe et auditable via logs structurés.
- Compatibilité Debian/Kali + XFCE + LightDM + PAM.

## Inputs
- Échantillon audio microphone.
- Contexte utilisateur et empreinte vocale enrôlée.
- Saisie PIN/code.
- Fichiers de configuration locaux.

## Outputs
- Décision d'authentification (accepté/refusé).
- Événements de logs opérationnels et d'audit (sans fuite de secrets).

## Files and directories concerned
- `README.md`
- `SPECIFICATIONS.md`
- `SPECIFICATIONS_FR.md`
- `SPECIFICATIONS_GLOBAL.md`
- Répertoires runtime cibles décrits dans README/spécifications.

## Interfaces and commands
Surface CLI prévue (base documentaire):
- `voice-loginctl enroll --user <name>`
- `voice-loginctl verify --user <name> --simulate`
- `voice-loginctl set-pin --user <name>`
- `voice-loginctl status`

## Constraints and safety rules
- Authentification uniquement par la voix interdite.
- Accès uniquement par PIN via chemin vocal interdit.
- Le fallback mot de passe doit rester actif.
- Les secrets/biométries ne doivent jamais apparaître dans les logs.

## Validation and acceptance criteria
- Synchronisation obligatoire EN/FR des spécifications.
- Cohérence entre spécification de tâche et baseline README.
- Toute évolution de comportement doit être reportée dans EN + FR dans la même tâche.

## Out-of-scope items
- Implémentation source complète du helper/module PAM dans cette tâche.
- Flux d'authentification cloud.
- Piles de login non Linux.

## Changelog
- v1.2.0 — 2026-04-28 12:00 UTC — Bruno DELNOZ
  - Ajout du bloc metadata obligatoire.
  - Normalisation avec les sections obligatoires.
  - Synchronisation de la baseline de tâche avec l'état actuel du dépôt.
  - Contexte: révision complète des fichiers Markdown demandée.
- v1.1.0 — 2026-04-28
  - Alignement de date depuis 2026-04-29 vers 2026-04-28.
