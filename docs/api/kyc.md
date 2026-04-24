# 📄 Documentation KYC — Nexus Backend

## Objectif

Cette documentation décrit le parcours KYC de ton projet Nexus P2P Lending côté backend, avec les routes à utiliser depuis le frontend, les payloads attendus et les réponses renvoyées.

---

## Vue d'ensemble du KYC

Le KYC est organisé en 3 sessions distinctes :

1. **Session 1** — Document d'identité
2. **Session 2** — Informations financières
3. **Session 3** — Soumission finale pour validation IMF

### Statuts KYC

Le backend stocke le statut KYC dans `user.kyc_status` :

- `NOT_STARTED` : KYC non démarré
- `SESSION1_DONE` : Session 1 complétée
- `SESSION2_DONE` : Session 2 complétée
- `VALIDATED` : KYC validé par IMF
- `REJECTED` : KYC rejeté par IMF

### Ce qui change après validation KYC

- L'utilisateur reste un `User` neutre par défaut.
- Son compte peut rester `ACTIVE` si le dossier est approuvé.
- Aucun rôle métier (`Investor`, `Borrower`) n'est attribué automatiquement par la validation KYC.

---

## Routes KYC exposées

Toutes les routes sont protégées par JWT (`JwtAuthGuard`) et se trouvent sous `/users`.

**Note importante** : Avant de soumettre les sessions KYC, les images doivent être uploadées via la route `/files/upload` pour obtenir les URLs.

### Route d'upload d'images

- Méthode : `POST`
- Route : `/files/upload`
- Description : Upload une image et retourne son URL.
- Payload : FormData avec `file` (image)
- Réponse :

```json
{
  "success": true,
  "data": { "url": "http://localhost:3000/uploads/1640995200000-photo.jpg" }
}
```

### 1) Soumettre la session 1

- Méthode : `POST`
- Route : `/users/kyc/session-1`
- Description : envoie le type de document et l'URL du document d'identité.

#### Payload attendu

```json
{
  "documentType": "CNI", // CNI | CIP | PASSEPORT | PERMIS
  "documentUrl": "http://localhost:3000/uploads/1640995200000-cni.jpg",
  "selfieUrl": "http://localhost:3000/uploads/1640995200000-selfie.jpg"
}
```

#### Validation côté backend

- `documentType` doit être l'une des valeurs : `CNI`, `CIP`, `PASSEPORT`, `PERMIS`
- `documentUrl` doit être une URL valide (photo du document d'identité)
- `selfieUrl` doit être une URL valide (photo du visage de l'utilisateur pour vérification de conformité)

#### Comportement

- `kyc_status` passe à `SESSION1_DONE`
- Les données des sessions 2 et 3 précédentes sont réinitialisées si le dossier repart du début

#### Réponse attendue

```json
{
  "success": true,
  "data": {
    "userId": "...",
    "kyc_status": "SESSION1_DONE",
    "sessionsCompleted": 1,
    "kycDocumentType": "CNI",
    "kycDocumentUrl": "http://localhost:3000/uploads/...",
    "kycSelfieUrl": "http://localhost:3000/uploads/...",
    "kycMonthlyIncome": null,
    "kycIncomeSource": null,
    "kycMomoStatement": null,
    "kycRejectionReason": null,
    "kycSubmittedAt": null,
    "kycValidatedAt": null
  },
  "message": "Session 1 KYC enregistrée avec succès"
}
```

---

### 2) Soumettre la session 2

- Méthode : `POST`
- Route : `/users/kyc/session-2`
- Description : envoie les informations de revenus et le relevé MoMo facultatif.

#### Payload attendu

```json
{
  "monthlyIncome": 150000,
  "incomeSource": "SALARIE", // SALARIE | INDEPENDANT | COMMERCE | AGRICULTURE | TRANSFERT | AUTRE
  "momoStatementUrl": "https://storage.nexus.bj/docs/momo-statement-123.pdf" // facultatif
}
```

#### Validation côté backend

- `monthlyIncome` doit être un nombre positif
- `monthlyIncome` ne doit pas dépasser `10_000_000`
- `incomeSource` doit être une valeur valide
- `momoStatementUrl`, si présent, doit être une URL valide

#### Conditions

- La session 1 doit déjà être terminée (`kyc_status === 'SESSION1_DONE'`)

#### Comportement

- `kyc_status` passe à `SESSION2_DONE`

#### Réponse attendue

```json
{
  "success": true,
  "data": {
    "userId": "...",
    "kyc_status": "SESSION2_DONE",
    "sessionsCompleted": 2,
    "kycDocumentType": "CNI",
    "kycDocumentUrl": "https://...",
    "kycSelfieUrl": "https://...",
    "kycMonthlyIncome": 150000,
    "kycIncomeSource": "SALARIE",
    "kycMomoStatement": "https://...",
    "kycRejectionReason": null,
    "kycSubmittedAt": null,
    "kycValidatedAt": null
  },
  "message": "Session 2 KYC enregistrée avec succès"
}
```

---

### 3) Soumettre la session 3 (soumission finale)

- Méthode : `POST`
- Route : `/users/kyc/session-3`
- Description : soumet le dossier KYC pour validation par l'IMF.

#### Conditions

- `kyc_status` doit être `SESSION2_DONE`
- le dossier ne doit pas déjà être soumis (`kycSubmittedAt` doit être `null`)

#### Comportement

- `kycSubmittedAt` est défini avec la date actuelle
- le dossier devient disponible pour validation IMF

#### Réponse attendue

```json
{
  "success": true,
  "data": {
    "userId": "...",
    "kyc_status": "SESSION2_DONE",
    "sessionsCompleted": 2,
    "kycDocumentType": "...",
    "kycDocumentUrl": "...",
    "kycSelfieUrl": "...",
    "kycMonthlyIncome": 150000,
    "kycIncomeSource": "SALARIE",
    "kycMomoStatement": "...",
    "kycRejectionReason": null,
    "kycSubmittedAt": "2026-04-18T...",
    "kycValidatedAt": null
  },
  "message": "Dossier KYC soumis — en attente de validation IMF"
}
```

---

### 4) Consulter le statut KYC

- Méthode : `GET`
- Route : `/users/kyc/status`
- Description : récupère l'état du dossier KYC de l'utilisateur connecté.

#### Réponse attendue

```json
{
  "success": true,
  "data": {
    "userId": "...",
    "kyc_status": "SESSION2_DONE",
    "sessionsCompleted": 2,
    "kycDocumentType": "...",
    "kycDocumentUrl": "...",
    "kycSelfieUrl": "...",
    "kycMonthlyIncome": 150000,
    "kycIncomeSource": "SALARIE",
    "kycMomoStatement": "...",
    "kycRejectionReason": null,
    "kycSubmittedAt": "2026-04-18T...",
    "kycValidatedAt": null
  },
  "message": "Statut KYC récupéré"
}
```

---

## Flux logique attendu pour le frontend

### Ordre des étapes

1. Vérifier que l'utilisateur est authentifié et a un JWT valide.
2. Appeler `/users/kyc/status` pour connaître l’état actuel.
3. Si `NOT_STARTED` ou `REJECTED`, afficher la page **Session 1**.
4. Après validation de Session 1, diriger vers **Session 2**.
5. Après validation de Session 2, activer le bouton **Soumettre le dossier** vers `/users/kyc/session-3`.
6. Une fois soumis, attendre la validation IMF (`VALIDATED` ou `REJECTED`).

### Ce que le frontend doit gérer

- Afficher une progression claire :
  - 1/3 — document d'identité
  - 2/3 — revenus et relevé MoMo
  - 3/3 — soumission finale
- Empêcher d’envoyer la session 2 tant que la session 1 n’est pas terminée.
- Empêcher d’envoyer la session 3 tant que la session 2 n’est pas terminée.
- Sur `REJECTED`, afficher le motif de rejet (`kycRejectionReason`) et permettre de reprendre à la session 1.
- Après validation (`VALIDATED`), proposer l’accès aux modules métiers ou au choix de rôle.

---

## Notes importantes pour l’intégration frontend

- Toutes les routes KYC sont protégées : le header `Authorization: Bearer <token>` est requis.
- `documentUrl` et `momoStatementUrl` doivent être des URLs déjà uploadées sur un service de stockage accessible.
- Le backend ne gère pas l’upload direct de fichiers dans ces routes — le frontend doit d’abord uploader le fichier puis envoyer l’URL.
- Le KYC validé ne transforme pas automatiquement l’utilisateur en investisseur ou emprunteur : il reste un `user` neutre jusqu’à une action métier.

---

## Exemples de scénario

### 1. Nouvel utilisateur enregistrant son KYC

1. `/users/kyc/session-1` → fournit `documentType` + `documentUrl`
2. `/users/kyc/session-2` → fournit `monthlyIncome` + `incomeSource` (+ `momoStatementUrl` facultatif)
3. `/users/kyc/session-3` → soumet le dossier
4. `/users/kyc/status` → vérifie l’état en attente

### 2. Utilisateur dont le KYC est rejeté

- `kyc_status` devient `REJECTED`
- le frontend doit afficher `kycRejectionReason`
- l’utilisateur peut redémarrer la session 1

### 3. IMF Staff validant un dossier

- route interne backend : `PATCH /users/kyc/validate/:userId`
- nécessite rôle `imf_staff` ou `admin`
- après approbation, `kyc_status` passe à `VALIDATED`
- en cas d’approbation, le compte peut rester `ACTIVE`

---

## Résumé pour le frontend

- Routes utilisateur à implémenter :
  - `POST /users/kyc/session-1`
  - `POST /users/kyc/session-2`
  - `POST /users/kyc/session-3`
  - `GET /users/kyc/status`
- Authentification requise sur toutes ces routes.
- Les payloads sont validés par Zod dans le backend.
- Le frontend doit gérer le flow séquentiel et l’état `REJECTED`.

Si tu veux, je peux aussi ajouter un paragraphe de documentation frontend pour React Native / Expo avec exemples Axios et gestion de l’avancement KYC.
