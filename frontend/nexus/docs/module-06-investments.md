# Module 6 — Investments (Investissements)

## Ce que fait ce module

Le module Investments permet aux investisseurs de :
1. Voir leur portefeuille et son résumé de performance
2. Explorer les prêts disponibles en financement (marketplace)
3. Investir manuellement dans un prêt
4. Configurer une règle Auto-Invest pour investir automatiquement

---

## Structure des fichiers

```
lib/features/investments/
├── data/
│   ├── models/
│   │   └── investment_models.dart         ← modèles + DTOs
│   └── repositories/
│       └── investment_repository.dart     ← appels HTTP
└── presentation/
    ├── providers/
    │   └── investment_provider.dart       ← state + notifier
    └── screens/
        ├── investments_screen.dart        ← écran principal (tabs)
        ├── investment_detail_screen.dart  ← détail investissement
        ├── invest_in_loan_screen.dart     ← formulaire investissement
        └── auto_invest_screen.dart        ← configuration Auto-Invest
```

---

## Modèles (`investment_models.dart`)

| Modèle | Champs clés | Utilisation |
|---|---|---|
| `Investment` | id, loanId, amount, expectedReturn, actualReturn, status, isGuaranteed | Portefeuille |
| `InvestmentSummary` | totalInvested, totalExpectedReturn, totalActualReturn, activeCount, completedCount, defaultedCount | Carte résumé |
| `AutoInvestRule` | isActive, maxAmount, maxDuration, minHybridScore | Configuration auto |
| `CreateInvestmentRequest` | loanId, amount | POST /investments |
| `AutoInvestRuleRequest` | isActive, maxAmount, maxDuration, minHybridScore | PUT /investments/auto-invest |

`_parseNum(dynamic)` gère les Decimal Prisma comme dans le module Wallet.

---

## Repository (`investment_repository.dart`)

| Méthode | Endpoint |
|---|---|
| `getMyInvestments(page, limit, status?)` | GET `/investments/my` |
| `getInvestmentSummary()` | GET `/investments/my/summary` |
| `getInvestmentById(id)` | GET `/investments/:id` |
| `createInvestment(request)` | POST `/investments` |
| `getAutoInvestRule()` | GET `/investments/auto-invest` |
| `putAutoInvestRule(request)` | PUT `/investments/auto-invest` |
| `runAutoInvest()` | POST `/investments/auto-invest/run` |

Gestion spéciale : 403 → "Profil investisseur requis", 409 → "Fonds insuffisants".

---

## State & Notifier (`investment_provider.dart`)

### InvestmentState
```dart
{
  investments: List<Investment>,    // liste portefeuille
  summary: InvestmentSummary?,      // totaux
  selectedInvestment: Investment?,  // détail
  autoInvestRule: AutoInvestRule?,  // règle ou null
  marketplaceLoans: List<Loan>,     // prêts FUNDING
  isLoading, isDetailLoading, isSummaryLoading, isSubmitting, isMarketplaceLoading,
  error, page, hasMore
}
```

### Marketplace
La marketplace **réutilise `LoanRepository`** — il n'y a pas d'endpoint séparé. Les prêts sont filtrés par `status == LoanStatus.funding` côté client :
```dart
await _loanRepo.getMyLoans(page: 1, limit: 50)
  .where((l) => l.status == LoanStatus.funding)
```

---

## Écrans

### InvestmentsScreen (onglet 2 du shell)
Deux onglets via `TabController` :
- **Portefeuille** : `_SummaryCard` + liste `_InvestmentCard` avec infinite scroll
- **Marketplace** : liste `_MarketplaceLoanCard` avec CTA "Investir →"

Bouton AppBar → `/investments/auto-invest`.

### InvestmentDetailScreen
- Route : `/investments/:id`
- Affiche : montant, retour attendu/réel, devise, date maturité
- Badge garantie si `isGuaranteed = true`

### InvestInLoanScreen
- Route : `/investments/invest/:loanId`
- Charge le détail du prêt via `LoanRepository` pour afficher le résumé
- Validation : montant minimum 5 000 FCFA, ne dépasse pas le montant du prêt

### AutoInvestScreen
- Route : `/investments/auto-invest`
- Toggle actif/inactif
- Champs : montant max, sélecteur durée max (wrap de chips), score minimum (0–1)
- 2 boutons : "Sauvegarder la règle" + "Exécuter maintenant"
- Au `initState` : charge la règle existante et pré-remplit le formulaire

---

## Router (`app_router.dart`)

Routes sous `/investments` :
```
/investments                        → InvestmentsScreen
/investments/auto-invest            → AutoInvestScreen
/investments/invest/:loanId         → InvestInLoanScreen
/investments/:id                    → InvestmentDetailScreen
```

**Attention** : `auto-invest` et `invest/:loanId` sont définis **avant** `:id` pour éviter que le paramètre dynamique `:id` ne capture ces routes statiques. GoRouter est résolu dans l'ordre de déclaration.

---

## Points importants

1. **Solde nécessaire** : pour investir, le wallet doit avoir un solde suffisant (alimenté en Module 5).
2. **Prêts FUNDING** : seuls les prêts en statut `FUNDING` apparaissent dans la marketplace. Un prêt que vous avez vous-même demandé n'y apparaîtra pas (il est en `PENDING_IMF`).
3. **Auto-Invest ≠ investissement immédiat** : la règle est sauvegardée mais l'exécution se fait soit manuellement ("Exécuter maintenant"), soit via le cron backend.
