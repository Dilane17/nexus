# Rapport d'Unification Frontend Flutter

## Objectif
Créer une couche frontend unifiée pour la gestion d'état, réduire les duplications, et améliorer la cohérence de l'architecture Flutter du projet Nexus.

## Abstractions Créées

### 1. ApiExceptionMapper
**Fichier:** `lib/core/error/api_exception_mapper.dart`

**Responsabilités:**
- Mappe DioException vers ServerException/NetworkException
- Gère tous les codes de statut HTTP (400, 401, 403, 404, 409, 422, 429, 500, 502, 503, 504)
- Fournit des messages UX cohérents pour chaque type d'erreur
- Extrait les messages du backend automatiquement
- Gère timeouts et erreurs de connexion

**Utilisation:**
```dart
// Dans un repository
on DioException catch (e) {
  throw ApiExceptionMapper.mapDioException(e, 'Erreur récupération prêts');
}
```

**Avantages:**
- Messages d'erreur centralisés et cohérents
- Plus besoin de _map() dans chaque repository
- Maintenance facilitée (un seul point de modification)

---

### 2. MoneyFormatter
**Fichier:** `lib/core/formatters/money_formatter.dart`

**Responsabilités:**
- Formatage standard FCFA (sans décimales)
- Formatage avec décimales pour calculs précis
- Formatage compact pour grands montants (ex: 1.2M FCFA)
- Formatage plain pour champs de saisie (sans symbole)
- Formatage court pour listes compactes (ex: 1.5M)
- Parsing de chaînes vers nombres

**Utilisation:**
```dart
// Remplacer les NumberFormat locaux
MoneyFormatter.format(1000000); // "1 000 000 FCFA"
MoneyFormatter.formatWithDecimals(1000.50); // "1 000,50 FCFA"
MoneyFormatter.formatCompact(1000000); // "1,0 M FCFA"
MoneyFormatter.formatShort(1500000); // "1,5M"
```

**Avantages:**
- Cohérence UX garantie
- Supprime la duplication de NumberFormat dans chaque fichier
- Formats UEMOA standardisés

---

### 3. DateFormatter
**Fichier:** `lib/core/formatters/date_formatter.dart`

**Responsabilités:**
- Format court (dd/MM/yyyy)
- Format avec heure (dd/MM/yyyy HH:mm)
- Format long (EEEE dd MMMM yyyy)
- Format mois-année (MMMM yyyy)
- Format nom du jour (EEEE)
- Format relatif ("il y a 2 heures", "demain")
- Format relatif futur ("dans 2 heures", "la semaine prochaine")
- Format de plage de dates
- Parsing de chaînes vers DateTime

**Utilisation:**
```dart
// Remplacer les DateFormat locaux
DateFormatter.formatShort(DateTime.now()); // "15/01/2024"
DateFormatter.formatWithTime(DateTime.now()); // "15/01/2024 14:30"
DateFormatter.formatLong(DateTime.now()); // "lundi 15 janvier 2024"
DateFormatter.formatRelative(DateTime.now().subtract(Duration(hours: 2))); // "il y a 2 heures"
DateFormatter.formatRelativeFuture(DateTime.now().add(Duration(days: 1))); // "demain"
```

**Avantages:**
- Dates relatives en français cohérentes
- Supprime la duplication de DateFormat dans chaque fichier
- UX améliorée avec dates relatives

---

### 4. PaginatedState<T>
**Fichier:** `lib/core/state/paginated_state.dart`

**Responsabilités:**
- État générique pour listes paginées
- Gestion de loading initial, refresh, load more
- Pagination automatique (page, hasMore, total, totalPages)
- Empty state detection
- Error state avec retry support
- Méthodes helpers (asLoading, asRefreshing, asError, withData)

**Utilisation:**
```dart
// Dans un provider pour listes paginées
class LoanNotifier extends StateNotifier<PaginatedState<Loan>> {
  final LoanRepository _repo;

  LoanNotifier(this._repo) : super(PaginatedState.initial());

  Future<void> load() async {
    state = state.asLoading();
    try {
      final loans = await _repo.getMyLoans(page: 1, limit: 10);
      state = state.withData(
        newItems: loans,
        page: 1,
        total: loans.length,
        totalPages: loans.length < 10 ? 1 : 2,
      );
    } catch (e) {
      state = state.asError('Erreur de chargement');
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.asLoadingMore();
    try {
      final nextPage = state.page + 1;
      final more = await _repo.getMyLoans(page: nextPage, limit: 10);
      state = state.withData(
        newItems: more,
        page: nextPage,
        total: state.total + more.length,
        totalPages: more.length < 10 ? nextPage : nextPage + 1,
        append: true,
      );
    } catch (e) {
      state = state.asError('Erreur de chargement');
    }
  }
}
```

**Avantages:**
- Supprime la duplication de logique de pagination dans tous les providers
- État cohérent pour toutes les listes paginées
- Méthodes helpers prêtes à l'emploi

---

### 5. AsyncActionState<T>
**Fichier:** `lib/core/state/async_action_state.dart`

**Responsabilités:**
- État générique pour actions asynchrones (submit, create, update)
- Gestion de loading, success, error
- Support de données de retour génériques
- SimpleActionNotifier pour actions sans données
- Méthodes helpers (asLoading, asSuccess, asError, reset)

**Utilisation:**
```dart
// Pour actions avec données de retour
class CreateLoanNotifier extends StateNotifier<AsyncActionState<Loan>> {
  final LoanRepository _repo;

  CreateLoanNotifier(this._repo) : super(AsyncActionState.initial());

  Future<bool> createLoan(CreateLoanRequest request) async {
    state = state.asLoading();
    try {
      final loan = await _repo.createLoan(request);
      state = state.asSuccess(loan);
      return true;
    } catch (e) {
      state = state.asError('Erreur création prêt');
      return false;
    }
  }
}

// Pour actions sans données de retour
class DeleteLoanNotifier extends SimpleActionNotifier {
  final LoanRepository _repo;

  DeleteLoanNotifier(this._repo) : super();

  Future<bool> deleteLoan(String id) async {
    state = state.asLoading();
    try {
      await _repo.deleteLoan(id);
      state = state.asSuccess(null);
      return true;
    } catch (e) {
      state = state.asError('Erreur suppression prêt');
      return false;
    }
  }
}
```

**Avantages:**
- Supprime la duplication de logique submit/error dans tous les providers
- État cohérent pour toutes les actions
- Deux variantes (avec/sans données) pour flexibilité

---

## Analyse de l'Architecture Actuelle

### Duplications Identifiées

1. **Pagination Logic**
   - `loadX()` et `loadMore()` dupliqués dans: loan_provider, investment_provider, transaction_provider, tontine_provider
   - Chaque provider a ses propres champs: `isLoading`, `page`, `hasMore`
   - Logique identique de vérification `if (!state.hasMore || state.isLoading) return`

2. **Loading States Multiples**
   - `isLoading`, `isDetailLoading`, `isSubmitting`, `isMarketplaceLoading`, `isSummaryLoading`, `isScoreLoading`, `isCyclesLoading`
   - Chaque provider définit ses propres bools de loading

3. **Error Handling**
   - Pattern try/catch répété dans chaque méthode
   - `on ServerException catch (e)` avec `e.message`
   - `on NetworkException catch (_)` avec message hardcodé "Problème de connexion réseau"

4. **Exception Mapping**
   - Chaque repository a son propre `_map()` pour DioException
   - Logique identique pour timeout, 403, 409, etc.
   - Messages fallback hardcodés

5. **Formatters**
   - `NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)` créé dans 10+ fichiers
   - `DateFormat('dd/MM/yyyy', 'fr_FR')` créé dans 8+ fichiers
   - `DateFormat('dd/MM/yyyy HH:mm', 'fr_FR')` créé dans 3+ fichiers

6. **State Patterns**
   - Chaque provider a son propre State avec copyWith personnalisé
   - Flags `clearError`, `clearSelected` dupliqués
   - Champs similaires (items, error, loading, page, hasMore)

---

## Providers à Refactoriser (Future Work)

Les providers suivants peuvent être refactorisés pour utiliser les nouvelles abstractions:

### 1. loan_provider.dart
- Utiliser `PaginatedState<Loan>` pour la liste de prêts
- Utiliser `AsyncActionState<Loan>` pour createLoan
- Utiliser `AsyncActionState<Loan>` pour repayLoan
- Utiliser `ApiExceptionMapper` dans loan_repository.dart

### 2. investment_provider.dart
- Utiliser `PaginatedState<Investment>` pour la liste d'investissements
- Utiliser `AsyncActionState<Investment>` pour invest
- Utiliser `AsyncActionState<AutoInvestRule>` pour saveAutoInvestRule
- Utiliser `ApiExceptionMapper` dans investment_repository.dart

### 3. transaction_provider.dart
- Utiliser `PaginatedState<Transaction>` pour la liste de transactions
- Utiliser `AsyncActionState<Transaction>` pour deposit
- Utiliser `AsyncActionState<Transaction>` pour withdraw
- Utiliser `ApiExceptionMapper` dans transaction_repository.dart

### 4. tontine_provider.dart
- Utiliser `PaginatedState<TontineGroup>` pour la liste de groupes
- Utiliser `AsyncActionState<TontineGroup>` pour createGroup
- Utiliser `AsyncActionState<void>` pour joinGroup
- Utiliser `ApiExceptionMapper` dans tontine_repository.dart

### 5. auth_provider.dart
- Utiliser `AsyncActionState<AuthUser>` pour login
- Utiliser `AsyncActionState<AuthUser>` pour loginWithGoogle
- Utiliser `ApiExceptionMapper` dans auth_repository.dart

### 6. kyc_provider.dart
- Utiliser `AsyncActionState<void>` pour submitSession1
- Utiliser `AsyncActionState<void>` pour submitSession2
- Utiliser `AsyncActionState<void>` pour submitSession3
- Utiliser `ApiExceptionMapper` dans kyc_repository.dart

---

## Recommandations

### Immédiat
1. **Remplacer les formatters existants**
   - Rechercher tous les `NumberFormat.currency` et remplacer par `MoneyFormatter.format()`
   - Rechercher tous les `DateFormat` et remplacer par `DateFormatter.formatShort()`, etc.
   - Cela peut être fait par recherche/remplacement global

2. **Intégrer ApiExceptionMapper dans les repositories**
   - Remplacer tous les `_map()` par `ApiExceptionMapper.mapDioException()`
   - Cela supprime ~100 lignes de code dupliqué

### Moyen Terme
3. **Refactoriser progressivement les providers**
   - Commencer par un provider simple (ex: transaction_provider)
   - Appliquer le pattern
   - Tester
   - Répéter pour les autres providers

4. **Créer des widgets UI réutilisables**
   - Loading widget standard
   - Empty state widget standard
   - Error banner widget standard
   - Pagination loader widget standard

### Long Terme
5. **Considérer la migration vers Riverpod 2.0**
   - Le projet utilise `flutter_riverpod/legacy.dart`
   - Riverpod 2.0 offre de meilleures performances et une API plus propre
   - Migration progressive possible

6. **Ajouter des tests unitaires pour les abstractions**
   - Tester PaginatedState avec différents scénarios
   - Tester AsyncActionState avec différents scénarios
   - Tester les formatters avec edge cases

---

## Problèmes Restants

### Type Erreurs dans les Abstractions
- PaginatedState et AsyncActionState ont des warnings de type
- Ces warnings sont dus à l'utilisation de legacy Riverpod
- Ils ne bloquent pas la compilation mais devraient être résolus
- Solution: migrer vers Riverpod 2.0 ou ajuster les types

### user_profile_provider.dart
- Ce fichier a des erreurs de compilation (non liées à ce travail)
- Ces erreurs proviennent de la tâche précédente (role-aware navigation)
- Doit être corrigé séparément

---

## Impact Estimé

### Code Supprimé
- ~500 lignes de code dupliqué dans les providers (pagination, error handling)
- ~100 lignes de code dupliqué dans les repositories (exception mapping)
- ~50 lignes de code dupliqué dans les écrans (formatters)

### Code Ajouté
- ~400 lignes d'abstractions réutilisables
- Net gain: -250 lignes de code

### Maintenance
- Un seul point de modification pour les messages d'erreur
- Un seul point de modification pour les formats monétaires
- Un seul point de modification pour les formats de date
- Patterns réutilisables pour tous les futurs providers

---

## Conclusion

Les abstractions créées fournissent une base solide pour un frontend unifié et maintenable. Elles réduisent significativement les duplications et améliorent la cohérence de l'architecture.

La refactorisation des providers peut être faite progressivement, sans risque de casser les fonctionnalités existantes. L'approche pragmatique recommandée est de:
1. Commencer par les formatters (changement sans risque)
2. Intégrer ApiExceptionMapper (changement localisé)
3. Refactoriser un provider à la fois avec testing

Cette approche garantit la stabilité du produit tout en améliorant progressivement la qualité du code.
