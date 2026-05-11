# Module 0 — Corrections Critiques

## Pourquoi ces corrections en premier ?

Ces trois bugs auraient cassé toute l'intégration backend silencieusement :
sans eux, l'app aurait compilé mais les données auraient été mal parsées,
les sessions auraient expiré sans être renouvelées, et les redirections KYC
auraient comparé des chaînes qui ne matchent jamais.

---

## 0.1 — `app_enums.dart` : réécriture complète

### Le problème

Le fichier original avait inventé ses propres valeurs sans consulter le backend.
Exemple : le backend envoie `"VALIDATED"`, le code Flutter attendait `"approved"`.
Résultat : un utilisateur KYC validé aurait été traité comme non-validé.

Tableau des divergences critiques :

| Enum | Valeur Flutter (avant) | Valeur backend réelle |
|---|---|---|
| `KycStatus` | `approved` | `VALIDATED` |
| `KycStatus` | `pending` | `SESSION1_DONE` / `SESSION2_DONE` |
| `MomoProvider` | `orange` | n'existe pas dans Nexus |
| `CurrencyCode` | `xaf` | n'existe pas (le Bénin utilise `XOF`) |
| `LoanStatus` | `funded` | `FUNDING` |
| `TransactionStatus` | `completed` | `CONFIRMED` / `RECONCILED` |
| Manquant | — | `TontineStatus`, `TransactionType` |

### La solution

Chaque enum expose **deux méthodes** :

```dart
// Sérialisation → API
String toJson()   // ex: KycStatus.validated.toJson() → "VALIDATED"

// Désérialisation ← API
static T fromJson(String)  // ex: KycStatus.fromJson("VALIDATED") → KycStatus.validated
```

Pour les noms simples (`ACTIVE`, `PENDING`), on utilise `.name.toUpperCase()`.
Pour les noms composés (`NOT_STARTED`, `SESSION1_DONE`), on utilise un `switch`.

Le fallback dans `fromJson` évite un crash si le backend envoie une valeur inattendue —
l'app dégrade gracieusement plutôt que de planter.

---

## 0.2 — `dio_client.dart` : auto-refresh du token JWT

### Le problème

Le token d'accès JWT expire (ex: après 15 min). Sans refresh, toute requête
après expiration retournait 401 → écran de login inattendu pour l'utilisateur.
Le code avait un `// TODO: Implémenter auto-refresh` depuis le départ.

### La solution

Voici le flux implémenté :

```
Requête normale
    └─ 401 reçu ?
        ├─ NON → passer l'erreur normalement
        └─ OUI → déjà en train de refresher ?
              ├─ OUI → passer l'erreur (éviter boucle infinie)
              └─ NON → _isRefreshing = true
                    └─ Créer un "Dio bare" (sans intercepteurs)
                        └─ POST /auth/refresh avec refreshToken
                            ├─ Succès → sauvegarder nouveaux tokens
                            │         → rejouer la requête originale
                            │         → resolver la réponse (transparent)
                            └─ Échec  → supprimer les tokens
                                      → l'utilisateur verra le login
```

### Pourquoi un "Dio bare" ?

Si on utilisait le même Dio (avec l'intercepteur) pour appeler `/auth/refresh`,
on créerait une boucle infinie :
- Intercepteur appelle refresh → refresh retourne 401 → intercepteur appelle refresh → ...

Le Dio bare est une instance temporaire sans aucun intercepteur, utilisée
uniquement pour ce seul appel de refresh.

### Flag `_isRefreshing`

Protège contre les rafales : si 3 requêtes parallèles reçoivent 401 en même temps,
seule la première tente le refresh. Les autres passent directement à l'erreur.
Une fois le refresh terminé, les requêtes suivantes trouveront le nouveau token
dans le storage et fonctionneront normalement.

---

## 0.3 — `auth_user.dart` + `app_router.dart` : types enum + redirect KYC

### Le problème

`AuthUser.kycStatus` était un `String`. Le router faisait :
```dart
if (kycStatus == 'NOT_STARTED' || kycStatus == 'PENDING') { ... }
```
Le problème : `'PENDING'` n'est pas une valeur valide de `KycStatus` dans le backend !
Le backend envoie `SESSION1_DONE`. Cette comparaison ne matchait jamais.

### La solution

`AuthUser.status` et `AuthUser.kycStatus` sont maintenant des types enum forts :
```dart
final UserStatus status;
final KycStatus kycStatus;
```

Deux getters utilitaires ont été ajoutés :
```dart
bool get canAccessLoans => kycStatus == KycStatus.validated;
bool get needsKyc       => kycStatus != KycStatus.validated;
```

Ces getters sont utilisés dans le HomeScreen et seront utilisés dans les écrans
de prêts pour désactiver les actions sans KYC validé.

Le router utilise maintenant un `switch` Dart 3 sur l'enum :
```dart
return switch (user.kycStatus) {
  KycStatus.validated => '/home',
  _ => '/kyc',  // tous les autres états → flow KYC
};
```

`REJECTED` redirige aussi vers `/kyc` : l'écran KYC affiche le motif de rejet
et permet à l'utilisateur de corriger son dossier.

### `copyWith` ajouté sur `AuthUser`

Sera utilisé dans les prochains modules quand les écrans de profil permettront
de modifier les informations (prénom, ville…) sans recréer l'objet entier.
