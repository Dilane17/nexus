# Module Transactions

## Nom du Module & Responsabilité

Le module `Transactions` gère l’historique transactionnel, les dépôts/retraits Mobile Money, les webhooks FedaPay/KKiaPay et la réconciliation admin.

Base route : `/api/v1/transactions`

Les routes utilisateur/admin nécessitent JWT. Les webhooks sont publics.

## Dictionnaire des Données

### DepositRequest

| Champ | Type Dart | Nullable | Contraintes |
|---|---:|---:|---|
| amount | int | Non | entier FCFA, positif, min 1 000 |
| momo_provider | MomoProvider | Non | `MTN_MOMO`, `MOOV_FLOOZ` |
| momo_phone | String | Non | 8 à 20 caractères |

### WithdrawalRequest

| Champ | Type Dart | Nullable | Contraintes |
|---|---:|---:|---|
| amount | int | Non | entier FCFA, positif, min 1 000 |
| momo_provider | MomoProvider | Non | `MTN_MOMO`, `MOOV_FLOOZ` |
| momo_number | String | Non | 8 à 20 caractères |

### Transaction model

| Champ | Type Dart | Nullable |
|---|---:|---:|
| id | String | Non |
| type | TransactionType | Non |
| amount | num | Non |
| currency | CurrencyCode | Non |
| status | TransactionStatus | Non |
| payment_gateway | String | Oui |
| momo_reference | String | Oui |
| momo_provider | MomoProvider | Oui |
| provider_transaction_id | String | Oui |
| provider_status | String | Oui |
| provider_payload | Map<String, dynamic> | Oui |
| initiated_at | DateTime | Non |
| confirmed_at | DateTime | Oui |
| reconciled_at | DateTime | Oui |
| webhook_received_at | DateTime | Oui |
| signature_verified | bool | Non |
| is_reconciled | bool | Non |
| failure_reason | String | Oui |
| created_by | String | Non |

## Endpoints & Payloads

| Méthode | Route | Auth JWT | Request Body | Success Response |
|---|---|---:|---|---|
| GET | `/transactions/my?page=&limit=&type=` | Oui | aucun | historique paginé |
| GET | `/transactions/unreconciled?page=&limit=` | Oui, Admin | aucun | transactions non réconciliées |
| POST | `/transactions/deposit` | Oui | `DepositRequest` | dépôt initié |
| POST | `/transactions/withdraw` | Oui | `WithdrawalRequest` | retrait initié |
| POST | `/transactions/webhook/fedapay` | Non | payload provider | webhook traité |
| POST | `/transactions/webhook/kkiapay` | Non | payload provider | webhook traité |
| PATCH | `/transactions/:id/reconcile` | Oui, Admin | aucun | transaction réconciliée |

## Business & Logic Flow

### Dépôt investisseur

1. Écran Wallet.
2. CTA Déposer.
3. Saisie montant, opérateur, numéro MoMo.
4. Appel `/transactions/deposit`.
5. Afficher état `PENDING`.
6. Attendre confirmation webhook.
7. Recharger historique et solde.

### Retrait investisseur

1. Écran Wallet.
2. CTA Retirer.
3. Saisie montant, opérateur, numéro destinataire.
4. Appel `/transactions/withdraw`.
5. Afficher “en attente confirmation MoMo”.

### Historique

1. Appel `/transactions/my`.
2. Filtres par type.
3. Badge par statut.

## Réactions UI

- `PENDING` : orange, solde non disponible.
- `CONFIRMED` : vert, rafraîchir solde.
- `RECONCILED` : bleu/gris.
- `FAILED` : rouge, afficher `failure_reason`.
- `PHANTOM_DETECTED` : alerte admin.

## Error Handling

| Code | Logique frontend |
|---:|---|
| 400 | montant, opérateur ou numéro invalide |
| 401 | refresh token ou login |
| 403 | admin requis pour réconciliation |
| 404 | transaction introuvable |
| 409 | solde insuffisant ou statut incompatible |

## Cross-Module Sync

Transactions alimente le wallet investisseur utilisé par Investments. Les remboursements Loans créent aussi des transactions. Admin supervise la réconciliation.
