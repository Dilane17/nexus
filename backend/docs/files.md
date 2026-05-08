# Module Files

## Nom du Module & Responsabilité

Le module `Files` gère l’upload d’images nécessaires au KYC : document d’identité, selfie et justificatifs image.

Base route : `/api/v1/files`

Toutes les routes nécessitent JWT.

## Dictionnaire des Données

### UploadResponse

| Champ | Type Dart | Nullable |
|---|---:|---:|
| url | String | Non |

## Endpoints & Payloads

| Méthode | Route | Auth JWT | Request Body | Success Response |
|---|---|---:|---|---|
| POST | `/files/upload` | Oui | multipart/form-data, champ `file` | `{ success: true, data: { url } }` |

## Contraintes frontend

Le champ multipart doit s’appeler `file`.

Contraintes :

- Type MIME : image uniquement (`image/*`).
- Taille max : 5 MB.
- Fichier requis.

## Business & Logic Flow

1. L’utilisateur capture ou sélectionne une image.
2. Flutter compresse si nécessaire.
3. Flutter envoie le fichier à `/files/upload`.
4. Le backend retourne une URL.
5. Flutter utilise l’URL dans les payloads KYC.

## Réactions UI

- Succès : afficher preview et état upload terminé.
- `Aucun fichier fourni` : demander une image.
- `Seuls les fichiers image sont acceptés` : bloquer PDF/vidéo.
- `Fichier trop volumineux` : proposer compression ou recapture.

## Error Handling

| Code | Logique frontend |
|---:|---|
| 400 | fichier absent, mauvais type ou >5 MB |
| 401 | refresh token ou login |
| 413 | réduire taille image si infra bloque |

## Cross-Module Sync

Files est utilisé par Users/KYC. L’URL retournée devient `documentUrl`, `selfieUrl` ou justificatif.
