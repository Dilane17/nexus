# Architecture Globale Backend Nexus

## Vue d’ensemble

Le backend Nexus est une API NestJS modulaire exposée sous le préfixe global :

```txt
/api/v1
```

Swagger est disponible sous :

```txt
/api/docs
```

L’application utilise NestJS, Prisma/PostgreSQL, JWT, Zod, Swagger, un throttling global, Helmet, CORS et un filtre global d’exceptions Prisma.

## Modules détectés

| Module | Responsabilité |
|---|---|
| Auth | Inscription, OTP, login, refresh, logout, profil courant |
| Users | KYC progressif, profil complet, validation KYC IMF/Admin |
| Files | Upload d’images pour KYC/selfies |
| Loans | Demandes de prêts, validation IMF, remboursements |
| Investments | Portefeuille investisseur, investissement manuel, Auto-Invest |
| Tontine | Groupes tontine, cycles, score tontine |
| Transactions | Dépôts/retraits Mobile Money, webhooks, réconciliation |
| Admin | Dashboard, rapports BCEAO, utilisateurs, fonds de garantie |
| Logger | Journalisation HTTP/interne, pas d’API frontend directe |

## Format standard des réponses

```json
{
  "success": true,
  "data": {},
  "message": "Message lisible utilisateur"
}
```

## Authentification

Les routes protégées attendent :

```http
Authorization: Bearer <accessToken>
```

Le token est fourni par le module Auth. Les guards observés sont `JwtAuthGuard`, `RefreshAuthGuard`, `GoogleAuthGuard` et `RolesGuard`.

## Enums à générer côté Flutter

### UserStatus

```dart
enum UserStatus { PENDING, ACTIVE, SUSPENDED, BLOCKED }
```

### KycStatus

```dart
enum KycStatus { NOT_STARTED, SESSION1_DONE, SESSION2_DONE, VALIDATED, REJECTED }
```

### LoanStatus

```dart
enum LoanStatus { PENDING_IMF, FUNDING, ACTIVE, OVERDUE, GUARANTEE_ACTIVATED, REPURCHASED, REPAID, CANCELLED, RESTRUCTURED }
```

### InvestmentStatus

```dart
enum InvestmentStatus { ACTIVE, COMPLETED, DEFAULTED, GUARANTEED }
```

### TontineStatus

```dart
enum TontineStatus { PENDING, ACTIVE, COMPLETED, SUSPENDED }
```

### TransactionStatus

```dart
enum TransactionStatus { PENDING, CONFIRMED, RECONCILED, FAILED, PHANTOM_DETECTED }
```

### TransactionType

```dart
enum TransactionType { INVESTOR_DEPOSIT, INVESTOR_WITHDRAWAL, LOAN_DISBURSEMENT, LOAN_REPAYMENT, PLATFORM_COMMISSION, GUARANTEE_ACTIVATION, IMF_REPURCHASE, AGENT_COMMISSION }
```

### MomoProvider

```dart
enum MomoProvider { MTN_MOMO, MOOV_FLOOZ }
```

### CurrencyCode

```dart
enum CurrencyCode { XOF, USD, EUR, NGN }
```

## Flux inter-modules

1. Auth crée la session et fournit les tokens.
2. Files upload les images KYC et retourne des URLs.
3. Users/KYC consomme ces URLs et valide progressivement l’utilisateur.
4. Loans est débloqué lorsque `kyc_status = VALIDATED`.
5. Investments finance les prêts en statut `FUNDING`.
6. Transactions gère les mouvements Mobile Money et remboursements.
7. Admin supervise les utilisateurs, prêts, rapports BCEAO et réconciliation.

## Notes Flutter

- Centraliser `ApiResponse<T>`.
- Ajouter automatiquement le bearer token via interceptor.
- Sur `401`, tenter le refresh token avant logout.
- Parser les décimaux Prisma de manière robuste (`num` ou `String`).
- Utiliser `message` pour SnackBar/Dialog utilisateur.
