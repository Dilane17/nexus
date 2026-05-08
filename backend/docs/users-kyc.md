# Module Users & KYC

## Nom du Module & Responsabilité

Le module `Users` gère le KYC progressif, le statut KYC, le profil complet et la validation KYC par IMF/Admin.

Base route : `/api/v1/users`

Toutes les routes nécessitent JWT.

## Dictionnaire des Données

### KycSession1Request

| Champ | Type Dart | Nullable | Contraintes |
|---|---:|---:|---|
| documentType | String | Non | `CNI`, `CIP`, `PASSEPORT`, `PERMIS` |
| documentUrl | String | Non | URL valide |
| selfieUrl | String | Non | URL valide |

### KycSession2Request

| Champ | Type Dart | Nullable | Contraintes |
|---|---:|---:|---|
| monthlyIncome | num | Non | > 0, max 10 000 000 |
| incomeSource | String | Non | `SALARIE`, `INDEPENDANT`, `COMMERCE`, `AGRICULTURE`, `TRANSFERT`, `AUTRE` |
| momoStatementUrl | String | Oui | URL valide si fourni |

### KycValidateRequest

| Champ | Type Dart | Nullable | Contraintes |
|---|---:|---:|---|
| decision | String | Non | `APPROVED`, `REJECTED` |
| reason | String | Si rejet | motif requis conseillé/attendu |

### User KYC fields

| Champ | Type Dart | Nullable |
|---|---:|---:|
| kyc_status | KycStatus | Non |
| kycDocumentType | String | Oui |
| kycDocumentUrl | String | Oui |
| kycSelfieUrl | String | Oui |
| kycMonthlyIncome | num | Oui |
| kycIncomeSource | String | Oui |
| kycMomoStatement | String | Oui |
| kycRejectionReason | String | Oui |
| kycSubmittedAt | DateTime | Oui |
| kycValidatedAt | DateTime | Oui |

## Endpoints & Payloads

| Méthode | Route | Auth JWT | Request Body | Success Response |
|---|---|---:|---|---|
| POST | `/users/kyc/session-1` | Oui | `KycSession1Request` | session 1 enregistrée |
| POST | `/users/kyc/session-2` | Oui | `KycSession2Request` | session 2 enregistrée |
| POST | `/users/kyc/session-3` | Oui | aucun | dossier soumis |
| GET | `/users/kyc/status` | Oui | aucun | statut KYC |
| GET | `/users/profile` | Oui | aucun | profil complet |
| GET | `/users/kyc/pending?page=&limit=` | Oui, IMF/Admin | aucun | dossiers en attente |
| PATCH | `/users/kyc/validate/:userId` | Oui, IMF/Admin | `KycValidateRequest` | validation/rejet |

## Business & Logic Flow

1. `KycIntroScreen`.
2. `KycDocumentScreen` : upload document et selfie via Files, puis session 1.
3. `KycFinancialScreen` : revenus, source, relevé MoMo optionnel, puis session 2.
4. `KycReviewScreen` : appel session 3.
5. `KycPendingScreen` : attente validation IMF.
6. Si `VALIDATED`, débloquer Loans.
7. Si `REJECTED`, afficher motif et permettre correction.

## Réactions UI

- `NOT_STARTED` : afficher onboarding KYC.
- `SESSION1_DONE` : reprendre à session 2.
- `SESSION2_DONE` : afficher soumission finale.
- `VALIDATED` : badge vert et accès prêts.
- `REJECTED` : badge rouge, motif et CTA correction.

## Error Handling

| Code | Logique frontend |
|---:|---|
| 400 | URL, revenu, enum ou payload invalide |
| 401 | refresh token ou login |
| 403 | rôle IMF/Admin requis |
| 404 | utilisateur introuvable |
| 409 | état KYC incompatible |

## Cross-Module Sync

Requiert Auth et Files. Débloque Loans lorsque `kyc_status = VALIDATED`.
