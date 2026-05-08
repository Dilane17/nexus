# Module Admin

## Nom du Module & Responsabilité

Le module `Admin` gère le dashboard global, les rapports BCEAO, le fonds de garantie, la liste/détail utilisateurs et le blocage/suspension/réactivation des comptes.

Base route : `/api/v1/admin`

Toutes les routes nécessitent JWT et rôle `admin`.

## Dictionnaire des Données

### UpdateUserStatusRequest

| Champ | Type Dart | Nullable | Contraintes |
|---|---:|---:|---|
| status | UserStatus | Non | `ACTIVE`, `SUSPENDED`, `BLOCKED` |
| reason | String | Selon logique service | motif conseillé pour audit |

### Dashboard data

Le dashboard retourne des agrégats. Côté Flutter, prévoir un modèle flexible si la structure évolue :

```dart
class AdminDashboard {
  final Map<String, dynamic> raw;
}
```

Sections attendues :

- Utilisateurs.
- Prêts.
- NPL.
- Transactions.
- Réconciliation.
- Fonds de garantie.

## Endpoints & Payloads

| Méthode | Route | Auth JWT | Request Body | Success Response |
|---|---|---:|---|---|
| GET | `/admin/dashboard` | Oui, Admin | aucun | dashboard global |
| GET | `/admin/reports/bceao?from=YYYY-MM-DD&to=YYYY-MM-DD` | Oui, Admin | aucun | rapport BCEAO |
| GET | `/admin/guarantee-fund` | Oui, Admin | aucun | état fonds garantie |
| GET | `/admin/users?page=&limit=&status=&kyc_status=` | Oui, Admin | aucun | utilisateurs paginés |
| GET | `/admin/users/:id` | Oui, Admin | aucun | fiche complète |
| PATCH | `/admin/users/:id/status` | Oui, Admin | `UpdateUserStatusRequest` | utilisateur mis à jour |

## Business & Logic Flow

### Dashboard admin

1. Admin se connecte.
2. Vérifier le rôle dans le profil.
3. Appeler `/admin/dashboard`.
4. Afficher cartes utilisateurs, prêts, NPL, transactions et alertes.

### Rapport BCEAO

1. Écran rapport.
2. Sélectionner `from` et `to` au format `YYYY-MM-DD`.
3. Appeler `/admin/reports/bceao`.
4. Afficher résumé et prévoir export côté Flutter si nécessaire.

### Gestion utilisateurs

1. Liste filtrée par statut ou KYC.
2. Ouvrir détail utilisateur.
3. Action : réactiver, suspendre ou bloquer.
4. Recharger liste/détail après succès.

## Réactions UI

- Rôle non admin : masquer menu admin.
- `ACTIVE` : badge vert.
- `SUSPENDED` : badge orange.
- `BLOCKED` : badge rouge.
- Rapport BCEAO : prévoir loader long.

## Error Handling

| Code | Logique frontend |
|---:|---|
| 400 | dates ou status invalides |
| 401 | refresh token ou login |
| 403 | rôle non admin |
| 404 | utilisateur introuvable |
| 409 | transition de statut impossible |

## Cross-Module Sync

Admin supervise Users, Loans, Transactions et Investments. Les données fonds de garantie dépendent des investissements garantis.
