# Module Investments

## Nom du Module & Responsabilité

Le module `Investments` gère le portefeuille investisseur, l’investissement manuel, le résumé de performance et l’Auto-Invest.

Base route : `/api/v1/investments`

Toutes les routes nécessitent JWT.

## Dictionnaire des Données

### CreateInvestmentRequest

| Champ | Type Dart | Nullable | Contraintes |
|---|---:|---:|---|
| loan_id | String | Non | UUID valide, prêt en statut `FUNDING` |
| amount | int | Non | entier FCFA, positif, min 5 000 |

### Investment model

| Champ | Type Dart | Nullable |
|---|---:|---:|
| id | String | Non |
| investor_id | String | Non |
| loan_id | String | Non |
| amount | num | Non |
| currency | CurrencyCode | Non |
| expected_return | num | Non |
| actual_return | num | Non |
| status | InvestmentStatus | Non |
| is_guaranteed | bool | Non |
| guarantee_tier | int | Non |
| maturity_date | DateTime | Non |

### AutoInvestRule

| Champ | Type Dart | Nullable |
|---|---:|---:|
| id | String | Non |
| investor_id | String | Non |
| is_active | bool | Non |
| max_amount | num | Non |
| max_duration | int | Non |
| min_hybrid_score | num | Non |
| created_at | DateTime | Non |

## Endpoints & Payloads

| Méthode | Route | Auth JWT | Request Body | Success Response |
|---|---|---:|---|---|
| GET | `/investments/my?page=&limit=&status=` | Oui | aucun | portefeuille paginé |
| GET | `/investments/my/summary` | Oui | aucun | résumé portefeuille |
| GET | `/investments/:id` | Oui | aucun | détail investissement |
| POST | `/investments` | Oui | `CreateInvestmentRequest` | investissement créé |
| GET | `/investments/auto-invest` | Oui | aucun | règle ou null |
| PUT | `/investments/auto-invest` | Oui | `AutoInvestRuleRequest` | règle créée/mise à jour |
| POST | `/investments/auto-invest/run` | Oui | aucun | exécution Auto-Invest |

## Business & Logic Flow

### Investissement manuel

1. Lister les prêts éligibles `FUNDING`.
2. Ouvrir détail prêt.
3. Saisir montant.
4. Appeler `POST /investments`.
5. Rafraîchir portefeuille et résumé.

### Portefeuille

1. Appeler `/investments/my/summary`.
2. Appeler `/investments/my`.
3. Filtrer par `ACTIVE`, `COMPLETED`, `DEFAULTED`, `GUARANTEED`.

### Auto-Invest

1. Lire règle existante.
2. Configurer montant max, durée max, score minimum.
3. Activer/désactiver via `PUT`.
4. Lancer manuellement via `/auto-invest/run` si besoin.

## Réactions UI

- Aucune règle : empty state + CTA configurer.
- Succès investissement : snackbar + refresh.
- Fonds insuffisants : message backend.
- Prêt non éligible : recharger marketplace.

## Error Handling

| Code | Logique frontend |
|---:|---|
| 400 | montant ou UUID invalide |
| 401 | refresh token ou login |
| 403 | profil investisseur requis |
| 404 | prêt/investissement introuvable |
| 409 | prêt non éligible ou fonds insuffisants |

## Cross-Module Sync

Dépend de Auth, Loans et Transactions. Les dépôts Transactions alimentent le solde investisseur.
