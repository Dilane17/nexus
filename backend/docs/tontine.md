# Module Tontine

## Nom du Module & Responsabilité

Le module `Tontine` gère les groupes tontine, l’adhésion, les cycles et le score tontine.

Base route : `/api/v1/tontine`

Toutes les routes nécessitent JWT.

## Dictionnaire des Données

### CreateTontineGroupRequest

| Champ | Type Dart | Nullable | Contraintes |
|---|---:|---:|---|
| name | String | Non | 3 à 150 caractères |
| monthly_contribution | int | Non | entier FCFA, positif, min 1 000 |

### TontineGroup model

| Champ | Type Dart | Nullable |
|---|---:|---:|
| id | String | Non |
| name | String | Non |
| leader_user_id | String | Non |
| leader_phone | String | Non |
| member_count | int | Non |
| monthly_contribution | num | Non |
| completed_cycles | int | Non |
| status | TontineStatus | Non |

### TontineCycle model

| Champ | Type Dart | Nullable |
|---|---:|---:|
| id | String | Non |
| group_id | String | Non |
| cycle_number | int | Non |
| start_date | DateTime | Non |
| end_date | DateTime | Non |
| total_collected | num | Non |
| is_complete | bool | Non |
| beneficiary_id | String | Non |
| members_paid | int | Non |
| members_defaulted | int | Non |

## Endpoints & Payloads

| Méthode | Route | Auth JWT | Request Body | Success Response |
|---|---|---:|---|---|
| GET | `/tontine/my-score` | Oui | aucun | score + historique |
| GET | `/tontine/groups?page=&limit=&status=` | Oui | aucun | groupes paginés |
| POST | `/tontine/groups` | Oui | `CreateTontineGroupRequest` | groupe créé |
| GET | `/tontine/groups/:id` | Oui | aucun | détail groupe |
| POST | `/tontine/groups/:id/join` | Oui | aucun | adhésion réussie |
| POST | `/tontine/groups/:id/cycles` | Oui, leader | `CreateCycleRequest` | cycle démarré |
| PATCH | `/tontine/cycles/:id/complete` | Oui, leader | `CompleteCycleRequest` | cycle clôturé |

## Business & Logic Flow

1. Écran Tontine Home.
2. Charger `/tontine/my-score`.
3. Lister groupes via `/tontine/groups`.
4. Ouvrir détail groupe.
5. Rejoindre via `/groups/:id/join`.
6. Si leader, créer/clôturer les cycles.
7. À clôture, le score tontine est recalculé.

## Réactions UI

- `PENDING` : groupe créé mais pas pleinement actif.
- `ACTIVE` : adhésion et cycles visibles.
- `COMPLETED` : lecture seule.
- `SUSPENDED` : masquer actions.
- Score élevé : valoriser dans parcours prêt.

## Error Handling

| Code | Logique frontend |
|---:|---|
| 400 | payload invalide |
| 401 | refresh token ou login |
| 403 | borrower/leader requis |
| 404 | groupe/cycle introuvable |
| 409 | déjà membre ou groupe actif existant |

## Cross-Module Sync

Requiert Auth et profil Borrower. Le score tontine peut influencer Loans/scoring.
