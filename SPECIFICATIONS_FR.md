# SPECIFICATIONS_FR.md

## Nom du projet

Authentification vocale biométrique pour Linux/XFCE

## Version

1.1 — 2026-04-29

---

## Objectif

Ce projet définit et implémente un mécanisme local de connexion Linux basé sur la
vérification biométrique vocale de l'identité du locuteur, combinée à un PIN ou
code numérique, tout en conservant le login classique utilisateur/mot de passe comme
fallback obligatoire.

L'environnement cible est Debian/Kali Linux avec XFCE et LightDM.

Le système ne doit pas remplacer de manière destructive la pile d'authentification Linux
existante. Il ajoute une voie optionnelle, testable, désactivable et entièrement réversible.

---

## Concept principal

```text
Écran de login LightDM
  ├── Login Linux classique :
  │     utilisateur + mot de passe  (toujours disponible)
  │
  └── Login vocal biométrique :
        1. l'utilisateur déclenche le login vocal
        2. le système affiche un challenge numérique aléatoire
        3. l'utilisateur lit le challenge à voix haute
        4. vérification du locuteur (identité, indépendante du texte)
        5. [Phase 6] vérification acoustique du challenge (optionnel)
        6. saisie du PIN/code
        7. session ouverte uniquement si voix ET PIN sont valides
```

L'étape vocale répond à **qui parle**, pas à **ce qui est dit**.
L'étape PIN est le second facteur local obligatoire.
Le login Linux classique n'est jamais désactivé.

---

## Plateforme cible

Cible principale :

```text
Système :         Kali Linux / Debian
Bureau :          XFCE
Display manager : LightDM
Authentification: PAM
Audio :           ALSA / PipeWire / compatibilité PulseAudio
Python :          3.10+
Shell :           scripts POSIX compatibles (installeur, outils de contrôle)
```

Cible secondaire :

```text
Autres distributions basées sur Debian utilisant LightDM et PAM
```

Hors périmètre :

```text
Windows / macOS
Authentification cloud-only
Authentification vocale SSH distante (désactivée par défaut)
Remplacement complet du display manager
```

---

## Exigences fonctionnelles

1. Fallback login classique (utilisateur/mot de passe) toujours disponible.
2. Option séparée d'authentification biométrique vocale.
3. Vérification locale par PIN/code après validation vocale.
4. Processus d'enrôlement sécurisé (échantillons multiples, contrôle qualité).
5. Processus de ré-enrôlement sécurisé.
6. Mode test : vérification complète sans modifier le comportement de login réel.
7. Mécanisme de désactivation et de rollback.
8. Journalisation structurée sans fuite de secrets (deux fichiers log distincts).
9. Permissions strictes sur toutes les données biométriques et PIN.
10. Sessions XFCE lancées via LightDM → PAM → logind (chemin normal).

---

## Exigences d'authentification

Le chemin vocal exige les deux éléments :

```text
correspondance biométrique vocale
ET
correspondance PIN/code
```

- Voix seule : **interdit**.
- PIN seul via le chemin vocal : **interdit**.
- Login Linux classique : reste entièrement indépendant, utilise PAM/mot de passe existant.

---

## Exigences biométriques vocales

### Modèle de vérification du locuteur

Implémentation recommandée :

```text
Principale (prototype + production) :
  SpeechBrain + ECAPA-TDNN
  Modèle pré-entraîné : spkrec-ecapa-voxceleb
  Embeddings : vecteurs float32 de dimension 192
  Métrique de similarité : cosine similarity

Alternative pour prototype Phase 2 uniquement :
  resemblyzer
  (plus simple, précision moindre, acceptable pour test précoce)
```

SpeechBrain est le choix recommandé à long terme.
resemblyzer peut être utilisé pour la Phase 2 hors-ligne si nécessaire,
mais le système final doit utiliser ECAPA-TDNN ou équivalent.

### Format de stockage de l'empreinte

```text
voiceprint.embedding    — fichier NumPy .npy, float32, forme (192,)
voiceprint.meta.json    — métadonnées d'enrôlement
```

Le format NumPy `.npy` est préféré : binaire compact, chargé en une seule instruction,
sans ambiguïté de parsing.

### Seuil de vérification

Seuil initial recommandé (cosine similarity, ECAPA-TDNN) :

```text
Seuil : 0.75  (configurable dans config.toml)
```

Un score >= seuil valide la vérification vocale.
Le seuil doit être calibré sur les échantillons d'enrôlement réels en Phase 2.
La documentation doit inclure un guide de calibration par modèle.

### Vérification indépendante du texte

L'utilisateur peut prononcer un contenu arbitraire pendant la vérification.
Le système vérifie l'identité du locuteur, pas la phrase spécifique.

Le challenge aléatoire affiché fournit une fenêtre temporelle de contenu connu
sans nécessiter de reconnaissance vocale complète.

### Mode challenge

```text
1. Générer un challenge aléatoire de 4 à 6 chiffres.
2. Afficher à l'interface de login.
3. L'utilisateur lit le challenge à voix haute.
4. Vérification du locuteur (ECAPA-TDNN).
5. [Phase 6] Vérification acoustique via whisper.cpp local (optionnel).
6. Saisie du PIN/code.
```

Propriétés du challenge :

```text
Longueur :    4 à 6 chiffres (configurable)
TTL :         30 secondes (minimum non configurable)
Réutilisation : interdite — chaque challenge est à usage unique
Stockage :    en mémoire uniquement pendant la tentative active
```

Le projet doit distinguer clairement :

```text
Vérification du locuteur  = qui parle    (cœur du projet, Phase 2)
Reconnaissance vocale     = ce qui est dit  (optionnel, Phase 6 uniquement)
```

---

## Exigences PIN/code

1. Stocké uniquement sous forme de hash (jamais en clair).
2. Jamais journalisé sous quelque forme que ce soit.
3. Longueur configurable (minimum 4 chiffres, recommandé 6+).
4. Verrouillage ou délai progressif après échecs répétés (Phase 3).
5. Modifiable via commande administrative dédiée.

Hash requis :

```text
Argon2id   (préféré)
yescrypt   (alternative acceptable)
bcrypt     (alternative acceptable)
```

**SHA-256 seul est inacceptable pour stocker un PIN.**

Politique de verrouillage (Phase 3) :

```text
Après 3 échecs consécutifs  : délai 30 secondes
Après 5 échecs consécutifs  : verrouillage 5 minutes
Après 10 échecs consécutifs : déverrouillage administratif requis
```

L'état de verrouillage est stocké dans `/var/lib/voice-login/runtime/<user>.state`
et consigné dans `audit.log`.

---

## Exigences PAM

La décision finale d'authentification passe par PAM.

Architecture recommandée :

```text
Greeter LightDM / déclencheur
  ↓
Service PAM dédié : /etc/pam.d/voice-login
  ↓
pam_exec → voice-login-helper  (root-owned, non modifiable par les utilisateurs)
  ↓
exit 0 = accepté
exit 1 = refusé
```

La Phase 4+ peut implémenter un module PAM dédié (`pam_voice_login.so`) pour remplacer
`pam_exec` et améliorer la robustesse et la gestion d'erreurs.

L'intégration PAM ne doit pas affecter :

```text
sudo
su
login TTY
SSH
login LightDM classique par mot de passe
```

Sauf configuration explicite par l'administrateur.

Le service PAM dédié (`/etc/pam.d/voice-login`) doit être testé en isolation
avant toute modification de `/etc/pam.d/lightdm`.

---

## Exigences LightDM/XFCE

La session XFCE doit être lancée par le chemin normal du display manager
(LightDM → PAM → logind). L'invocation directe de `startxfce4` est interdite
en contexte de production ou semi-production.

Options d'intégration (par ordre de préférence) :

1. Wrapper autour du greeter LightDM GTK existant (recommandé pour Phase 5).
2. Greeter personnalisé dédié (acceptable, complexité plus élevée).
3. Test PAM manuel sans modification du greeter (Phase 4 uniquement).

Le bouton de login vocal ne doit pas apparaître si le système n'est pas enrôlé
et activé pour l'utilisateur cible.

---

## Modèle de sécurité

### Menaces considérées

1. Attaque par rejeu audio (enregistrement vocal).
2. Clonage vocal par IA / synthèse vocale.
3. Conversion de voix (style transfer).
4. Imitation humaine directe.
5. Vol des fichiers d'empreinte vocale.
6. Vol du fichier hash PIN.
7. Élévation de privilèges locale via helpers.
8. Compromission du greeter (injection UI).
9. Micro indisponible ou spoofé matériellement.
10. Déni de service par tentatives répétées.
11. Verrouillage accidentel de l'utilisateur.
12. Logs divulguant du matériel sensible.
13. Injection shell via nom d'utilisateur, chemins audio ou entrées du greeter.

### Règles minimales de sécurité

1. Login par voix seule : **interdit**.
2. PIN/code obligatoire après validation vocale.
3. Login classique par mot de passe : **toujours disponible**.
4. Fichiers biométriques : lisibles uniquement par `root` (ou utilisateur de service dédié).
5. Fichiers hash PIN : mêmes restrictions que biométrique.
6. Binaires/scripts helpers : non modifiables par les utilisateurs normaux (`root:root 755`).
7. Aucune injection shell possible depuis une entrée externe.
8. Aucun répertoire runtime world-writable.
9. Aucun secret en argument de ligne de commande.
10. Aucun secret dans les logs (PIN, audio, phrase, vecteur complet, valeur de hash).
11. Aucun enrôlement automatique depuis un contexte non authentifié.
12. Aucune modification destructive de PAM/LightDM sans sauvegarde horodatée.

### Utilisateur système dédié (Phase 4+)

Un utilisateur système dédié `voice-login` (sans shell, sans home) peut être créé
pour exécuter le helper, réduisant la surface d'attaque par rapport à root :

```text
Utilisateur :  voice-login
Type :         system user (adduser --system)
Shell :        /usr/sbin/nologin
Home :         aucun
Groupes :      audio (accès micro)
```

Optionnel pour le prototype, recommandé avant déploiement en production.

---

## Layout des fichiers

```text
/etc/voice-login/                   root:root 700
  config.toml                       root:root 600
  users/                            root:root 700
    <user>/                         root:root 700
      voiceprint.embedding          root:root 600  (numpy .npy, float32 dim 192)
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

/run/voice-login/                   root:root 700  (tmpfs, effacé au reboot)
  <session-id>.wav                  root:root 600  (supprimé après traitement)

/var/lib/voice-login/               root:root 700
  runtime/                          root:root 700
    <user>.state                    root:root 600  (état verrouillage)
  cache/                            root:root 700

/var/log/voice-login/               root:adm 750
  voice-login.log                   root:adm 640  (événements opérationnels + debug)
  audit.log                         root:adm 640  (décisions d'auth uniquement, sans scores)

/var/backups/voice-login/
  YYYY-MM-DD_HHMMSS/
    pam.d_lightdm
    pam.d_lightdm-greeter
    lightdm.conf
    lightdm-gtk-greeter.conf
```

### Politique de séparation des logs

`audit.log` contient uniquement :

```text
timestamp | composant | utilisateur | action | résultat | catégorie_raison
```

Exemple :

```text
2026-04-29T10:00:00Z voice-login-helper user=nox action=verify result=failed reason=voice_below_threshold
2026-04-29T10:01:00Z voice-login-helper user=nox action=verify result=failed reason=pin_mismatch
2026-04-29T10:02:00Z voice-login-helper user=nox action=lockout reason=threshold_exceeded duration=300s
```

`voice-login.log` peut contenir en plus :

```text
score=0.61 threshold=0.75
model=spkrec-ecapa-voxceleb
sample_duration=4.2s
```

**Aucun des deux logs ne peut contenir : PIN, phrase prononcée, audio brut, vecteur biométrique complet, valeur de hash.**

---

## Capture audio

1. Utiliser le périphérique micro configuré explicitement dans `config.toml`.
2. Échouer fermé immédiatement si aucun micro n'est disponible.
3. Sample rate fixe : **16000 Hz** (requis par ECAPA-TDNN ; configurable pour d'autres modèles).
4. Audio temporaire stocké exclusivement dans `/run/voice-login/` (`root:root 700`).
5. Fichier temporaire supprimé immédiatement après extraction de l'embedding.
6. Audio brut jamais conservé par défaut (mode debug nécessite un flag explicite).
7. Durée minimale valide : **2 secondes de parole active** (silence rejeté).
8. Durée maximale d'enregistrement : **10 secondes** (timeout forcé).

---

## Enrôlement

L'enrôlement doit être réalisé uniquement après authentification locale réussie
(mot de passe ou sudo).

Procédure :

```text
Collecter 5 à 10 échantillons vocaux
  - 3 à 8 secondes de parole active chacun
  - contenu parlé différent par échantillon
  - rythme et débit variés
  - rejeter les échantillons en dessous du seuil SNR ou < 2s de parole active
Moyenner les embeddings ou calculer le centroïde
Écrire voiceprint.embedding (numpy .npy)
Écrire voiceprint.meta.json
```

Contenu de `voiceprint.meta.json` :

```json
{
  "model":          "spkrec-ecapa-voxceleb",
  "model_version":  "<chaîne de version>",
  "sample_rate":    16000,
  "embedding_dim":  192,
  "created_at":     "2026-04-29T10:00:00Z",
  "n_samples":      7,
  "threshold":      0.75,
  "enrolled_by":    "voice-login-enroll"
}
```

`voiceprint.meta.json` ne doit contenir **aucun PIN, audio ou matériel secret**.

---

## Vérification

1. Capturer un nouvel échantillon audio (micro, `/run/voice-login/`).
2. Valider la qualité de l'échantillon (durée, SNR).
3. Extraire l'embedding du locuteur (ECAPA-TDNN → float32 dim 192).
4. Calculer la cosine similarity avec l'empreinte enrôlée.
5. Comparer le score au seuil configuré.
6. Si voix validée : passer à la vérification PIN/code.
7. Si voix rejetée : rejeter immédiatement, journaliser la raison, ne pas demander le PIN.
8. Retourner succès strict (0) ou échec (1).
9. Supprimer l'audio temporaire immédiatement après l'étape 3.

---

## Anti-rejeu et présence

Phase 2 : challenge numérique basique (aléatoire, TTL 30s, non réutilisable).

Phase 6 : vérification acoustique du challenge via `whisper.cpp` (STT local) :

```text
1. Générer un challenge de 4 à 6 chiffres aléatoires.
2. Afficher à l'interface de login.
3. Enregistrer l'utilisateur lisant le challenge.
4. Vérifier l'identité du locuteur (ECAPA-TDNN).
5. [Phase 6] Exécuter whisper.cpp localement pour transcrire.
6. [Phase 6] Comparer la transcription au challenge attendu.
7. Demander le PIN/code.
```

`whisper.cpp` est le composant STT approuvé (local, sans réseau).
Modèle recommandé : `ggml-small.bin` ou `ggml-base.bin` pour CPU.

---

## Dépendances Python

```text
Paquets Debian/Kali requis :
  python3 (>=3.10)
  python3-numpy
  python3-scipy
  python3-pip
  python3-venv
  portaudio19-dev
  libsndfile1

Paquets Python requis (venv pip) :
  speechbrain       >= 0.5
  sounddevice
  argon2-cffi
  torch             (build CPU acceptable pour le prototype)

Optionnel (Phase 6 uniquement) :
  whisper.cpp       (compilé localement, pas de paquet pip)
  ggml-small.bin    (modèle whisper, téléchargé une seule fois)
```

Aucun dépôt externe n'est ajouté automatiquement.
Tous les paquets proviennent des dépôts officiels Kali/Debian ou d'un venv pip local dédié.

---

## Commandes prévues

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

### Options obligatoires pour les scripts shell

```text
--help        afficher l'aide
--simulate    simulation, aucun changement système
--exec        requis pour toute action réelle
--install     installer le composant
--uninstall   retirer le composant
--status      état actuel
--rollback    restaurer la configuration précédente
--purge       suppression complète données utilisateur (requiert --exec)
--changelog   historique des versions
--prerequis   vérifier et lister les prérequis
```

Aucune opération destructive sans flag `--exec` explicite.

---

## Comportement en échec

Le chemin voice-login échoue fermé dans tous les cas suivants :

```text
Micro indisponible ou impossible à ouvrir
Fichier modèle manquant ou échec de chargement
Configuration invalide ou manquante
Échantillon audio trop court ou silencieux
Score vocal sous le seuil
PIN incorrect
TTL du challenge expiré
Fichier voiceprint corrompu ou illisible
Erreur de permissions sur un fichier requis
Exception inattendue dans le helper
```

Dans tous les cas :
- La tentative voice-login est rejetée (exit 1).
- La raison est journalisée (catégorie uniquement, sans secrets).
- Le login classique par mot de passe reste disponible.

---

## Sauvegarde et rollback

Avant toute modification système, l'installateur crée une sauvegarde horodatée :

```text
/var/backups/voice-login/YYYY-MM-DD_HHMMSS/
  pam.d_lightdm
  pam.d_lightdm-greeter
  lightdm.conf
  lightdm-gtk-greeter.conf
```

`voice-loginctl rollback` restaure tous les fichiers sauvegardés à leurs chemins d'origine.
Le rollback est disponible à toute phase et requiert `--exec`.

---

## Phases de développement

### Phase 1 — Squelette du dépôt

```text
README.md
SPECIFICATIONS.md
SPECIFICATIONS_FR.md
CHANGELOG.md
WHY.md
AGENTS.md
.gitignore
```

### Phase 2 — Prototype vocal hors login

Sans modification PAM/LightDM :

```text
voice-login-enroll    (CLI, SpeechBrain ou resemblyzer)
voice-login-test      (test capture audio, test chargement modèle)
prototype verify      (CLI, cosine similarity, seuil configurable)
config.toml           (chemin modèle, sample rate, seuil, device)
notes de calibration du seuil
```

### Phase 3 — PIN + Rate limiting

Sans modification PAM/LightDM :

```text
voice-login-pin-change   (création hash Argon2id)
vérification PIN         (intégrée au flux verify)
politique verrouillage   (3/5/10 tentatives, état par utilisateur)
audit.log                (décisions auth, sans scores)
voice-login.log          (événements debug, scores autorisés)
```

### Phase 4 — Test PAM

Service PAM dédié uniquement, sans toucher au PAM lightdm :

```text
/etc/pam.d/voice-login   (service dédié)
prototype pam_exec
voice-loginctl rollback
voice-loginctl doctor
procédure de test manuel
```

### Phase 5 — Intégration LightDM/XFCE

Avec sauvegarde préalable et rollback disponible :

```text
bouton de login vocal dans le greeter
affichage du challenge
capture audio depuis le contexte greeter
dialogue PIN
flux auth complet via PAM
fallback login classique
```

### Phase 6 — Durcissement

```text
vérification acoustique du challenge via whisper.cpp (optionnel)
améliorations anti-rejeu
revue rate limiting
audit permissions
revue logs
utilisateur système dédié (voice-login)
squelette paquet Debian
```

---

## Non-objectifs

1. Remplacer les mots de passe Linux globalement.
2. Activer l'authentification vocale SSH par défaut.
3. Stocker l'audio brut de façon permanente par défaut.
4. Dépendre de services cloud vocaux.
5. Utiliser des API en ligne pour le login local.
6. Modifier les règles firewall.
7. Modifier des services desktop non liés.
8. Installer des dépôts non-Debian ou non-Kali sans accord explicite.
9. Casser l'accès TTY ou recovery.
10. Masquer les erreurs d'authentification.

---

## Confidentialité

1. Toutes les données biométriques restent en local.
2. Aucun traitement cloud d'aucune sorte.
3. Aucune télémétrie.
4. Aucune conservation d'audio brut par défaut.
5. Inventaire exact des données stockées documenté par répertoire utilisateur.
6. Commande `purge` supprime empreinte, PIN et état de verrouillage par utilisateur.
7. Ré-enrôlement complet depuis zéro disponible à tout moment.

---

## Critères d'acceptation

Le projet est acceptable quand tous les points suivants sont validés :

1. Le login classique utilisateur/mot de passe fonctionne correctement et indépendamment.
2. Le prototype voice-login s'exécute entièrement en CLI sans modifier LightDM.
3. Un mauvais locuteur est systématiquement rejeté (score sous le seuil).
4. Un mauvais PIN est rejeté après validation vocale correcte.
5. La session s'ouvre uniquement si voix et PIN sont tous les deux valides.
6. Toute erreur audio/modèle/config entraîne un rejet fermé.
7. Le rollback restaure exactement la configuration PAM/LightDM d'origine.
8. L'audit log est utile et ne contient aucun PIN, audio, vecteur ni hash.
9. Tous les fichiers biométriques et PIN ont les permissions strictes requises.
10. Le système peut être désactivé via `voice-loginctl disable` sans réinstaller.

---

## Cible initiale recommandée

```text
Utilisateur :  nox (utilisateur local unique)
Machine :      casablanca ou koutoubia (locale)
Session :      XFCE via LightDM
Modèle :       SpeechBrain ECAPA-TDNN (spkrec-ecapa-voxceleb)
Hash PIN :     Argon2id
Pas d'intégration SSH
Aucune dépendance cloud
```
