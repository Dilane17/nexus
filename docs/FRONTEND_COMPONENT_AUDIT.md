# Audit des Composants Frontend

## Objectif
Identifier les duplications, composants inutilisés, patterns incohérents et logique métier mélangée à la présentation.

---

## Composants Dupliqués

### 1. Status Badges

**Problème**: `_StatusBadge` est implémenté localement dans plusieurs écrans avec des variations légères.

| Fichier | Type d'énumération | Implémentation |
|---------|-------------------|----------------|
| `investment_detail_screen.dart` | InvestmentStatus | Container avec bg/fg switch |
| `tontine_group_detail_screen.dart` | TontineStatus | Container avec bg/fg switch |
| `wallet_screen.dart` | TransactionStatus | Container avec bg/fg switch |
| `loan_widgets.dart` | LoanStatus | LoanStatusBadge (implémentation différente) |

**Composant unifié existant**: `NexusStatusChip` dans `core/theme/widgets/nexus_chip.dart`

**Recommandation**: Remplacer tous les `_StatusBadge` par `NexusStatusChip` avec un mapping standard des statuts.

---

### 2. Info Rows

**Problème**: `_InfoRow` est dupliqué avec des variations légères.

| Fichier | Paramètres | Implémentation |
|---------|-----------|----------------|
| `investment_detail_screen.dart` | label, value, valueColor? | Row avec label/bodySmall, value/labelMedium |
| `tontine_group_detail_screen.dart` | label, value | Row avec label/bodySmall, value/labelMedium (sans valueColor) |
| `loan_detail_screen.dart` | label, value, valueColor? | Row avec label/bodySmall, value/labelMedium |

**Recommandation**: Créer `NexusInfoRow` dans `shared/widgets/` avec support optionnel de valueColor.

---

### 3. Mobile Money Selectors

**Problème**: `_ProviderSelector` est dupliqué dans plusieurs écrans.

| Fichier | Utilisation | Implémentation |
|---------|------------|----------------|
| `deposit_screen.dart` | Sélection opérateur dépôt | Row de GestureDetector avec Container |
| `withdraw_screen.dart` | Sélection opérateur retrait | Row de GestureDetector avec Container (identique) |
| `loan_detail_screen.dart` | Sélection opérateur remboursement | À vérifier |

**Recommandation**: Créer `NexusMomoSelector` dans `shared/widgets/` configurable pour deposit/withdraw/repayment.

---

### 4. Skeletons

**Problème**: `_SkeletonList` est dupliqué dans plusieurs écrans.

| Fichier | Implémentation |
|---------|----------------|
| `wallet_screen.dart` | Column avec 6 _SkeletonTile |
| `investments_screen.dart` | À vérifier |
| `tontine_screen.dart` | À vérifier |

**Composants unifiés existants**: 
- `NexusSkeleton` dans `core/theme/widgets/nexus_skeleton.dart`
- `NexusCardSkeleton` dans `core/theme/widgets/nexus_skeleton.dart`

**Recommandation**: Créer `NexusListSkeleton` dans `shared/widgets/` utilisant `NexusSkeleton` et `NexusCardSkeleton`.

---

### 5. Formatters

**Problème**: NumberFormat et DateFormat sont créés localement dans chaque fichier.

| Fichier | Formatters locaux |
|---------|-----------------|
| `loans_screen.dart` | NumberFormat.currency (FCFA) |
| `loan_detail_screen.dart` | NumberFormat.currency (FCFA), DateFormat (dd/MM/yyyy) |
| `home_screen.dart` | NumberFormat.decimalPattern, NumberFormat.currency (FCFA) |
| `tontine_screen.dart` | NumberFormat.currency (FCFA) |
| `tontine_group_detail_screen.dart` | NumberFormat.currency (FCFA), DateFormat (dd/MM/yyyy) |
| `withdraw_screen.dart` | NumberFormat.currency (FCFA) |
| `invest_in_loan_screen.dart` | NumberFormat.currency (FCFA) |
| `investment_detail_screen.dart` | NumberFormat.currency (FCFA), DateFormat (dd/MM/yyyy) |
| `investments_screen.dart` | NumberFormat.currency (FCFA) |
| `wallet_screen.dart` | NumberFormat.currency (FCFA), DateFormat (dd/MM/yyyy HH:mm) |

**Composants unifiés créés** (tâche précédente):
- `MoneyFormatter` dans `core/formatters/money_formatter.dart`
- `DateFormatter` dans `core/formatters/date_formatter.dart`

**Recommandation**: Remplacer tous les NumberFormat/DateFormat locaux par MoneyFormatter et DateFormatter.

---

## Problèmes d'Architecture

### 1. Wallet Balance Calculation

**Problème**: Le solde du wallet est calculé localement à partir de l'historique paginé des transactions.

**Fichier**: `features/wallet/presentation/providers/transaction_provider.dart`
```dart
num get balance {
  num total = 0;
  for (final t in transactions) {
    if (t.status != TransactionStatus.confirmed &&
        t.status != TransactionStatus.reconciled) {
      continue;
    }
    if (t.isDebit) {
      total -= t.amount;
    } else {
      total += t.amount;
    }
  }
  return total < 0 ? 0 : total;
}
```

**Problèmes**:
- Fragile: dépend du chargement de toutes les transactions
- Paginé: ne reflète pas le vrai solde si toutes les transactions ne sont pas chargées
- Calcul frontend: devrait venir du backend

**Solution disponible**: `UserProfile.investorData.walletBalance` est disponible depuis le backend.

**Recommandation**: Utiliser `UserProfile.investorData.walletBalance` ou créer un endpoint dédié `/wallet/balance`.

---

### 2. Logique Métier dans les Widgets UI

**Problème**: Plusieurs widgets contiennent de la logique métier qui devrait être dans les providers ou services.

**Exemples**:
- Calcul du solde dans TransactionState
- Validation de formulats dans les widgets locaux
- Mapping de statuts dans les widgets UI

**Recommandation**: Déplacer la logique métier vers les providers, repositories ou services dédiés.

---

## Composants Existantants

### Design System (core/theme/widgets/)

| Composant | Statut | Utilisation |
|-----------|--------|------------|
| `NexusButton` | ✅ Existant | Utilisé dans plusieurs écrans |
| `NexusCard` | ✅ Existant | Utilisé dans plusieurs écrans |
| `NexusChip` | ✅ Existant | NexusStatusChip - sous-utilisé |
| `NexusInput` | ✅ Existant | À vérifier l'utilisation |
| `NexusSizing` | ⚠️ Vide | Fichier vide |
| `NexusSkeleton` | ✅ Existant | Sous-utilisé |
| `NexusCardSkeleton` | ✅ Existant | Sous-utilisé |

### Shared Widgets (shared/widgets/)

**Statut**: Répertoire vide

**Recommandation**: Créer des composants partagés ici:
- `NexusInfoRow`
- `NexusMomoSelector`
- `NexusListSkeleton`
- `NexusStatusBadgeMapper` (helper pour mapper les statuts vers NexusStatusChip)

---

## Écrans Existants

### Auth
- `splash_screen.dart`
- `login_screen.dart`
- `register_screen.dart`
- `verify_email_screen.dart`
- `forgot_password_screen.dart`
- `reset_password_screen.dart`

### Home
- `home_screen.dart` (déjà role-aware)

### Loans
- `loans_screen.dart`
- `loan_detail_screen.dart`
- `create_loan_screen.dart`

### Investments
- `investments_screen.dart`
- `investment_detail_screen.dart`
- `invest_in_loan_screen.dart`
- `auto_invest_screen.dart`

### Wallet
- `wallet_screen.dart`
- `deposit_screen.dart`
- `withdraw_screen.dart`

### KYC
- `kyc_intro_screen.dart`
- `kyc_document_screen.dart`
- `kyc_financial_screen.dart`
- `kyc_review_screen.dart`
- `kyc_pending_screen.dart`

### Tontine
- `tontine_screen.dart`
- `tontine_group_detail_screen.dart`
- `create_group_screen.dart`

### Profile
- `profile_screen.dart`

### Shell
- `shell_screen.dart`

---

## Écrans Manquants (Backend disponible)

### IMF
- KYC pending list
- KYC detail
- KYC validate/reject
- Loans pending
- Loan validation
- Sandbox scoring
- IMF dashboard

### Admin
- Dashboard admin
- Users management
- Transaction reconciliation
- Reports
- Scoring configuration
- Guarantee fund management

### Tontine
- Create cycle
- Complete cycle
- Cycle details

---

## Patterns Incohérents

### 1. Loading States
- Certains utilisent `CircularProgressIndicator()`
- Certains utilisent des skeletons
- Certains utilisent des widgets de loading personnalisés

**Recommandation**: Standardiser sur `NexusSkeleton` et `NexusCardSkeleton`.

### 2. Error Handling
- Certains utilisent SnackBar
- Certains utilisent des banners
- Certains utilisent des widgets d'erreur personnalisés

**Recommandation**: Créer `NexusErrorBanner` standardisé.

### 3. Empty States
- Certains affichent "Aucune donnée"
- Certains affichent des icônes
- Certains affichent des messages personnalisés

**Recommandation**: Créer `NexusEmptyState` standardisé.

### 4. Form Validation
- Certains utilisent des validators locaux
- Certains utilisent des helpers
- Incohérence dans les messages d'erreur

**Recommandation**: Créer des validators partagés dans `shared/validators/`.

---

## Problèmes KYC

### Flow KYC Actuel
- Utilise `kycStatus` pour déterminer l'état
- Pas de distinction entre `submitted` et `review`
- `kycSubmittedAt` n'est pas utilisé pour le flow

**Recommandation**: 
- Créer un état frontend distinct `submitted` 
- Utiliser `kycSubmittedAt` pour le timing
- Corriger restoreSession, redirects, navigation KYC

---

## Statistiques

### Duplications Identifiées
- **Status Badges**: 4 implémentations différentes
- **Info Rows**: 3 implémentations avec variations
- **MoMo Selectors**: 2 implémentations identiques
- **Skeletons**: 3 implémentations locales
- **Formatters**: 10+ fichiers avec NumberFormat/DateFormat locaux

### Code Supprimable Estimé
- ~200 lignes de code dupliqué pour les status badges
- ~100 lignes de code dupliqué pour les info rows
- ~100 lignes de code dupliqué pour les MoMo selectors
- ~150 lignes de code dupliqué pour les skeletons
- ~200 lignes de code dupliqué pour les formatters
- **Total**: ~750 lignes de code supprimable

### Composants à Créer
- `NexusInfoRow` (shared/widgets/)
- `NexusMomoSelector` (shared/widgets/)
- `NexusListSkeleton` (shared/widgets/)
- `NexusErrorBanner` (shared/widgets/)
- `NexusEmptyState` (shared/widgets/)
- Validators partagés (shared/validators/)

---

## Priorités

### Haute Priorité
1. Unifier les Status Badges → NexusStatusChip
2. Unifier les Info Rows → NexusInfoRow
3. Unifier les MoMo Selectors → NexusMomoSelector
4. Corriger la logique wallet → utiliser backend
5. Remplacer les formatters locaux → MoneyFormatter/DateFormatter

### Moyenne Priorité
6. Unifier les Skeletons → NexusListSkeleton
7. Créer écrans IMF manquants
8. Créer écrans Admin manquants
9. Corriger le flow KYC

### Basse Priorité
10. Nettoyer l'architecture frontend
11. Créer composants UI standardisés (ErrorBanner, EmptyState)
12. Ajouter gestion cycles tontine
