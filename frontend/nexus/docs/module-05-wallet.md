# Module 5 — Wallet & Transactions

## Ce que fait ce module

Le module Wallet gère les dépôts, les retraits et l'historique transactionnel.
L'écran `WalletScreen` est l'onglet 4 du shell. Deux sous-écrans (`DepositScreen`, `WithdrawScreen`) sont accessibles via les routes `/wallet/deposit` et `/wallet/withdraw`.

---

## Structure des fichiers

```
lib/features/wallet/
├── data/
│   ├── models/
│   │   └── transaction_models.dart        ← DTOs et modèle Transaction
│   └── repositories/
│       └── transaction_repository.dart    ← appels HTTP
└── presentation/
    ├── providers/
    │   └── transaction_provider.dart      ← state + notifier
    └── screens/
        ├── wallet_screen.dart             ← écran principal
        ├── deposit_screen.dart            ← formulaire dépôt
        └── withdraw_screen.dart           ← formulaire retrait
```

---

## Modèles (`transaction_models.dart`)

### DepositRequest / WithdrawalRequest
Classes simples avec `toJson()` pour sérialiser vers l'API.

```dart
DepositRequest { amount, momoProvider, momoPhone }
WithdrawalRequest { amount, momoProvider, momoNumber }
```

### Transaction
Modèle complet avec `fromJson()` robuste :
- `_parseNum(dynamic)` gère les Decimal Prisma envoyés en String
- `isDebit` getter : retourne `true` pour retraits, remboursements, commissions

---

## Repository (`transaction_repository.dart`)

3 méthodes :
- `getMyTransactions(page, limit, type?)` → GET `/transactions/my`
- `deposit(DepositRequest)` → POST `/transactions/deposit`
- `withdraw(WithdrawalRequest)` → POST `/transactions/withdraw`

Les erreurs 409 sont mappées en "Solde insuffisant". Pattern identique à `LoanRepository`.

---

## State & Notifier (`transaction_provider.dart`)

### TransactionState
```dart
{
  transactions: List<Transaction>,
  isLoading: bool,      // chargement liste
  isSubmitting: bool,   // dépôt/retrait en cours
  error: String?,
  page: int,
  hasMore: bool,
}
```

### Getter `balance`
Le solde est **calculé côté client** à partir des transactions `CONFIRMED` ou `RECONCILED` :
```dart
get balance → sum(credits) - sum(débits)
```
Crédits = `INVESTOR_DEPOSIT`, `LOAN_DISBURSEMENT`
Débits = `INVESTOR_WITHDRAWAL`, `LOAN_REPAYMENT`, `PLATFORM_COMMISSION`, autres

### Méthodes du Notifier
| Méthode | Rôle |
|---|---|
| `loadTransactions()` | Charge page 1, reset liste |
| `loadMore()` | Pagination infinie |
| `deposit(amount, provider, phone)` | Crée transaction, prepend à la liste, retourne bool |
| `withdraw(amount, provider, number)` | Idem pour retrait |

---

## Écrans

### WalletScreen
- `_BalanceCard` : affiche `state.balance` formaté FCFA
- `_ActionRow` : 2 boutons (Déposer → `/wallet/deposit`, Retirer → `/wallet/withdraw`)
- `_TransactionTile` : icône type + montant coloré (vert=crédit, rouge=débit) + `_StatusBadge`
- `_SkeletonList` : placeholders statiques pendant le chargement initial
- Infinite scroll via `ScrollController` + listener sur `loadMore()`

### DepositScreen & WithdrawScreen
- Sélecteur `MomoProvider` : 2 boutons (MTN Mobile Money / Moov Flooz)
- Validation : montant minimum 1 000 FCFA, numéro ≥ 8 caractères
- Sur succès : `context.pop()` + snackbar vert

---

## Intégration HomeScreen

`_BalanceCard` dans `home_screen.dart` utilise maintenant :
```dart
ref.watch(transactionProvider.select((s) => s.balance))
```
Elle affiche le vrai solde calculé au lieu du placeholder `—`.

Le `RefreshIndicator` de `HomeScreen` appelle `loadTransactions()` pour rafraîchir.

---

## Router (`app_router.dart`)

Routes ajoutées sous la branche `/wallet` :
```
/wallet           → WalletScreen
/wallet/deposit   → DepositScreen
/wallet/withdraw  → WithdrawScreen
```

---

## Points importants

1. **Pas d'endpoint `/balance`** : le backend ne renvoie pas de solde, il est calculé localement.
2. **PENDING ≠ solde disponible** : seuls les statuts `CONFIRMED` et `RECONCILED` comptent.
3. **Webhook asynchrone** : après dépôt, la transaction est en `PENDING`. Le solde ne change que quand le webhook MoMo confirme (côté backend). L'UI l'affiche en orange jusqu'à confirmation.
