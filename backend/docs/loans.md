# Module Loans

## Nom du Module & Responsabilité

Le module `Loans` gère les demandes de prêt, la consultation, la validation IMF/Admin, le remboursement Mobile Money et le scoring sandbox.

Base route : `/api/v1/loans`

Toutes les routes nécessitent JWT.

## Dictionnaire des Données

### CreateLoanRequest

| Champ | Type Dart | Nullable | Contraintes |
|---|---:|---:|---|
| amount | int | Non | entier FCFA, min 25 000, max 500 000 |
| duration_months | int | Non | uniquement `3`, `6`, `9`, `12` |
| purpose | String | Non | 10 à 500 caractères |

### ValidateLoanRequest

| Champ | Type Dart | Nullable | Contraintes |
|---|---:|---:|---|
| decision | String | Non | `APPROVED`, `REJECTED` |
| interest_rate | num | Oui | min 0.01, max 0.18 |
| reason | String | Si rejet | min 10 caractères, obligatoire si `REJECTED` |

### Loan model

| Champ | Type Dart | Nullable |
|---|---:|---:|
| id | String | Non |
| borrower_id | String | Non |
| amount | num | Non |
| currency | CurrencyCode | Non |
| interest_rate | num | Non |
| duration_months | int | Non |
| status | LoanStatus | Non |
| monthly_installment | num | Non |
| outstanding_balance | num | Non |
| days_overdue | int | Non |
| validated_by_imf | bool | Non |
| disbursed_at | DateTime | Oui |
| next_due_date | DateTime | Oui |
| imf_validated_by | String | Oui |
| purpose | String | Oui |
| rejection_reason | String | Oui |
| created_at | DateTime | Non |

## Endpoints & Payloads

| Méthode | Route | Auth JWT | Request Body | Success Response |
|---|---|---:|---|---|
| GET | `/loans/my?page=&limit=` | Oui | aucun | prêts utilisateur |
| GET | `/loans/pending-imf?page=&limit=` | Oui, IMF/Admin | aucun | prêts en attente |
| GET | `/loans/:id` | Oui | aucun | détail prêt |
| POST | `/loans` | Oui | `CreateLoanRequest` | prêt créé, `PENDING_IMF` |
| PATCH | `/loans/:id/validate` | Oui, IMF/Admin | `ValidateLoanRequest` | prêt approuvé/rejeté |
| POST | `/loans/:id/repay` | Oui | `RepayLoanRequest` | remboursement enregistré |
| POST | `/loans/:id/sandbox-score` | Oui, IMF/Admin | aucun | score sandbox |

## Business & Logic Flow

### Emprunteur

1. Vérifier `kyc_status`.
2. Si non validé, rediriger vers KYC.
3. Écran création prêt.
4. Saisie montant, durée, objet.
5. Appel `POST /loans`.
6. Succès : afficher statut `PENDING_IMF`.
7. Suivre l’évolution : `FUNDING`, `ACTIVE`, `OVERDUE`, `REPAID`.

### IMF/Admin

1. Liste `/loans/pending-imf`.
2. Détail prêt.
3. Optionnel : scoring sandbox.
4. Approuver avec taux ou rejeter avec motif.

### Remboursement

1. Détail prêt `ACTIVE` ou `OVERDUE`.
2. CTA rembourser.
3. Appel `/loans/:id/repay`.
4. Si retour `REPAID`, afficher succès final.

## Réactions UI

- `PENDING_IMF` : badge orange, attente IMF.
- `FUNDING` : progression financement.
- `ACTIVE` : CTA remboursement.
- `OVERDUE` : alerte retard.
- `REPAID` : badge vert, lecture seule.

## Error Handling

| Code | Logique frontend |
|---:|---|
| 400 | formulaire invalide |
| 401 | refresh token ou login |
| 403 | KYC non validé ou rôle insuffisant |
| 404 | prêt introuvable |
| 409 | statut incompatible |

## Cross-Module Sync

Requiert Auth et KYC validé. Les prêts sont financés par Investments et remboursés via Transactions. Tontine peut influencer le scoring.
