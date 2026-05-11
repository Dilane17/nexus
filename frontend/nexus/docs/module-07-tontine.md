# Module 7 — Tontine

## Ce que fait ce module

La tontine est un système d'épargne collectif rotatif. Les membres d'un groupe cotisent chaque mois, et à chaque cycle, un bénéficiaire reçoit la cagnotte totale.

Ce module permet de :
1. Voir son **score tontine** (historique de fiabilité comme cotisant)
2. Explorer et rejoindre des **groupes tontine**
3. Créer son propre groupe

---

## Structure des fichiers

```
lib/features/tontine/
├── data/
│   ├── models/
│   │   └── tontine_models.dart            ← modèles + DTOs
│   └── repositories/
│       └── tontine_repository.dart        ← appels HTTP
└── presentation/
    ├── providers/
    │   └── tontine_provider.dart          ← state + notifier
    └── screens/
        ├── tontine_screen.dart            ← écran principal
        ├── tontine_group_detail_screen.dart ← détail groupe
        └── create_group_screen.dart       ← création groupe
```

---

## Modèles (`tontine_models.dart`)

| Modèle | Champs clés |
|---|---|
| `TontineScore` | score (0–1), completedCycles, defaultedCycles, totalContributed |
| `TontineGroup` | id, name, leaderPhone, memberCount, monthlyContribution, completedCycles, status |
| `TontineCycle` | id, cycleNumber, startDate, endDate, totalCollected, isComplete, membersPaid, membersDefaulted |
| `CreateTontineGroupRequest` | name, monthlyContribution |

---

## Repository (`tontine_repository.dart`)

| Méthode | Endpoint |
|---|---|
| `getMyScore()` | GET `/tontine/my-score` |
| `getGroups(page, limit, status?)` | GET `/tontine/groups` |
| `createGroup(request)` | POST `/tontine/groups` |
| `getGroupById(id)` | GET `/tontine/groups/:id` |
| `joinGroup(id)` | POST `/tontine/groups/:id/join` |

Gestion spéciale : 403 → "Profil emprunteur requis", 409 → "Déjà membre ou groupe actif existant".

---

## State & Notifier (`tontine_provider.dart`)

### TontineState
```dart
{
  myScore: TontineScore?,       // score personnel
  groups: List<TontineGroup>,   // liste paginée
  selectedGroup: TontineGroup?, // détail groupe
  isLoading, isDetailLoading, isScoreLoading, isSubmitting,
  error, page, hasMore
}
```

### Méthodes
| Méthode | Action |
|---|---|
| `loadScore()` | Charge le score, ne marque pas `error` si absent |
| `loadGroups()` | Page 1, reset liste |
| `loadMore()` | Pagination infinie |
| `loadGroupDetail(id)` | Charge détail groupe |
| `createGroup(name, contribution)` | Crée + prepend à la liste, retourne le groupe |
| `joinGroup(id)` | Adhésion, retourne bool succès |

---

## Écrans

### TontineScreen (onglet 3 du shell)
- **`_ScoreCard`** : cercle de progression animé sur le score (0–100%), compteurs cycles/défauts, total cotisé
- Liste `_GroupCard` : nom, statut coloré, chips (membres, cotisation, cycles)
- **FAB** "Créer un groupe" → `/tontine/groups/create`
- Infinite scroll + `RefreshIndicator`

### TontineGroupDetailScreen
- Route : `/tontine/groups/:id`
- Affiche : cotisation mensuelle, nb membres, cycles complétés, numéro leader
- **CTA "Rejoindre"** visible uniquement si `status == TontineStatus.active`
- Bannière rouge si groupe suspendu

### CreateGroupScreen
- Route : `/tontine/groups/create`
- Champs : nom (3–150 caractères), cotisation mensuelle (min 1 000 FCFA)
- Sur succès : `context.go('/tontine/groups/${group.id}')` → navigue directement vers le groupe créé

---

## Router (`app_router.dart`)

```
/tontine                    → TontineScreen
/tontine/groups/create      → CreateGroupScreen
/tontine/groups/:id         → TontineGroupDetailScreen
```

**Attention** : `groups/create` est défini **avant** `groups/:id` pour que "create" ne soit pas interprété comme un `:id`.

---

## Score Tontine et Loans

Le score tontine influence la notation hybride d'un emprunteur dans le module Loans. Un score élevé augmente les chances d'approbation de prêt et peut baisser le taux d'intérêt (géré côté backend). L'UI ne fait que l'afficher, mais c'est un élément central du profil emprunteur Nexus.

---

## Points importants

1. **Profil emprunteur requis** : rejoindre ou créer un groupe nécessite `UserRole.BORROWER` côté backend.
2. **Un groupe par utilisateur** : le backend retourne 409 si l'utilisateur a déjà un groupe actif comme leader.
3. **Cycles** : le module ne gère pas la création/clôture de cycles (réservé aux leaders, géré hors-scope MVP frontend).
