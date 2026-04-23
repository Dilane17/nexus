# Nexus Backend — Documentation Technique Complète

> Plateforme P2P Lending — Bénin / Zone UEMOA  
> Modèle IMF-Powered avec intégration Mobile Money et Tontine Bridge  
> **Version :** 1.0 | **Dernière mise à jour :** 19 avril 2026

---

## Table des matières

1. [Stack et dépendances](#1-stack-et-dépendances)
2. [Architecture complète](#2-architecture-complète)
3. [Modules — détail complet](#3-modules--détail-complet)
   - [Auth](#31-module-auth)
   - [Users & KYC](#32-module-users--kyc)
   - [Files](#33-module-files)
   - [Loans](#34-module-loans)
   - [Investments](#35-module-investments)
   - [Tontine](#36-module-tontine)
   - [Transactions](#37-module-transactions)
   - [Admin](#38-module-admin)
4. [Authentification et sécurité](#4-authentification-et-sécurité)
5. [Base de données](#5-base-de-données)
6. [Variables d'environnement](#6-variables-denvironnement)
7. [Services partagés](#7-services-partagés)
8. [Format des réponses API](#8-format-des-réponses-api)
9. [Fonctionnalités non implémentées](#9-fonctionnalités-non-implémentées)
10. [Points d'amélioration pour la production](#10-points-damélioration-pour-la-production)

---

## 1. Stack et dépendances

### Technologies clés

| Technologie | Version | Rôle |
|---|---|---|
| Node.js | ≥ 20 | Runtime JavaScript |
| NestJS | 11.x | Framework backend (modules, DI, guards, pipes) |
| TypeScript | 5.7 | Typage strict (`strict: true`) |
| Prisma | 7.7 | ORM + client généré dans `src/generated/prisma/` |
| PostgreSQL | 15+ | Base de données principale (`nexus_db`) |
| Zod | 4.x | Validation des DTOs (pas de `class-validator`) |
| JWT | via `@nestjs/jwt` | Access token (7j) + Refresh token (30j) |
| Passport | 0.7 | Stratégies JWT + Refresh + Google OAuth |
| Bcrypt | 6.x | Hashage des mots de passe et tokens de refresh |
| Nodemailer | 8.x | Envoi d'OTP par email (SMTP Gmail) |
| Multer | via `@nestjs/platform-express` | Upload de fichiers image (memoryStorage) |
| Helmet | latest | Sécurisation des headers HTTP |
| `@nestjs/throttler` | latest | Rate limiting global + par route |
| Swagger | `@nestjs/swagger` 11.x | Documentation API interactive sur `/api/docs` |

### Dépendances de production

```json
"@nestjs/common"           → Décorateurs, exceptions, guards, pipes, filtres
"@nestjs/config"           → Gestion des variables d'environnement (.env)
"@nestjs/core"             → Noyau NestJS (DI container, APP_GUARD)
"@nestjs/jwt"              → Signature et vérification des JWT
"@nestjs/passport"         → Intégration Passport dans NestJS
"@nestjs/platform-express" → Adaptateur Express (multer, static assets)
"@nestjs/swagger"          → Génération OpenAPI + Swagger UI
"@nestjs/throttler"        → Rate limiting
"@prisma/adapter-pg"       → Adaptateur Prisma pour pg (Pool PostgreSQL)
"@prisma/client"           → Client Prisma généré
"bcrypt"                   → Hashage bcrypt (mots de passe, refresh tokens, OTP)
"class-transformer"        → Transformation des objets (requis par ValidationPipe)
"class-validator"          → Installé mais NON utilisé pour la logique métier (Zod uniquement)
"helmet"                   → En-têtes de sécurité HTTP (XSS, clickjacking, MIME)
"multer"                   → Upload fichiers (via @nestjs/platform-express)
"nodemailer"               → Envoi d'emails SMTP
"passport"                 → Middleware d'authentification
"passport-google-oauth20"  → Stratégie OAuth Google
"passport-jwt"             → Stratégie JWT
"pg"                       → Driver PostgreSQL natif (Pool)
"reflect-metadata"         → Métadonnées TypeScript (requis par NestJS)
"rxjs"                     → Observables (requis par NestJS)
"tsconfig-paths"           → Résolution des alias de chemins (@shared, @modules)
"zod"                      → Validation des DTOs avec schémas typés
```

---

## 2. Architecture complète

### Préfixe global

Toutes les routes sont préfixées par `/api/v1`.  
Swagger disponible sur `/api/docs`.  
Fichiers statiques (uploads) servis sur `/uploads/:filename`.

### Structure des dossiers

```
src/
├── app.module.ts              # Module racine — importe tous les modules, configure ThrottlerModule
├── main.ts                    # Bootstrap — Helmet, filtres globaux, Swagger, CORS, static assets
│
├── generated/
│   └── prisma/                # Client Prisma auto-généré (NE PAS MODIFIER)
│
├── modules/
│   ├── auth/                  # Authentification complète
│   │   ├── auth.controller.ts # 13 endpoints (register → logout → OAuth)
│   │   ├── auth.service.ts    # Logique métier auth (OTP, JWT, bcrypt)
│   │   ├── auth.module.ts     # Importe JwtModule, PassportModule
│   │   ├── auth.types.ts      # Interfaces : JwtPayload, AuthUser, AuthTokens, GoogleProfile
│   │   ├── dto/               # 8 DTOs avec schémas Zod
│   │   ├── guards/            # JwtAuthGuard, RefreshAuthGuard, GoogleAuthGuard
│   │   └── strategies/        # JwtStrategy, RefreshStrategy, GoogleStrategy
│   │
│   ├── users/                 # Gestion utilisateurs + KYC 3 sessions
│   │   ├── users.controller.ts
│   │   ├── users.service.ts
│   │   ├── users.module.ts
│   │   └── dto/               # kyc-session1/2/validate + user-response
│   │
│   ├── files/                 # Upload d'images
│   │   ├── files.controller.ts
│   │   ├── files.service.ts   # Sauvegarde sur disque local (uploads/)
│   │   └── files.module.ts
│   │
│   ├── loans/                 # Prêts + scoring hybride + sandbox IMF
│   │   ├── loans.controller.ts
│   │   ├── loans.service.ts   # CRUD prêts + calcul mensualité + scoring
│   │   ├── imf-sandbox.service.ts  # Simulation scoring IMF externe
│   │   ├── loans.module.ts
│   │   └── dto/               # create/validate/repay + loan-response
│   │
│   ├── investments/           # Portefeuille investisseurs + Auto-Invest
│   │   ├── investments.controller.ts
│   │   ├── investments.service.ts   # Investissement + fonds de garantie + auto-invest
│   │   ├── investments.module.ts
│   │   └── dto/               # create-investment + auto-invest-rule + investment-response
│   │
│   ├── tontine/               # Tontine Bridge + Score Tontine
│   │   ├── tontine.controller.ts
│   │   ├── tontine.service.ts # Groupes + cycles + calcul tontine_score
│   │   ├── tontine.module.ts
│   │   └── dto/               # create-group + create-cycle + complete-cycle + responses
│   │
│   ├── transactions/          # MoMo + webhooks + réconciliation H+24
│   │   ├── transactions.controller.ts
│   │   ├── transactions.service.ts  # Dépôt/retrait + webhooks + phantom detection
│   │   ├── transactions.module.ts
│   │   └── dto/               # deposit + withdrawal + webhook-callback + transaction-response
│   │
│   └── admin/                 # Dashboard NPL + rapports BCEAO + gestion users
│       ├── admin.controller.ts
│       ├── admin.service.ts   # Dashboard + rapport BCEAO + fonds garantie + users
│       ├── admin.module.ts
│       └── dto/               # update-user-status + admin-response
│
└── shared/
    ├── shared.module.ts        # Module global (@Global) — exporte MailService, SmsService
    ├── decorators/
    │   ├── current-user.decorator.ts  # @CurrentUser() → JwtPayload depuis request.user
    │   └── roles.decorator.ts         # @Roles(...) → SetMetadata('roles', [...])
    ├── filters/
    │   └── prisma-exception.filter.ts # @Catch(PrismaClientKnownRequestError) — P2002→409 etc.
    ├── guards/
    │   └── roles.guard.ts             # Vérifie le rôle en DB (imfStaff, admin, investor, etc.)
    ├── mail/
    │   └── mail.service.ts            # Nodemailer SMTP Gmail — OTP par email HTML
    ├── pipes/
    │   └── zod-validation.pipe.ts     # PipeTransform qui appelle schema.safeParse()
    ├── prisma/
    │   ├── prisma.module.ts           # Module @Global() qui fournit PrismaService
    │   └── prisma.service.ts          # Étend PrismaClient avec Pool pg + lifecycle hooks
    ├── repositories/
    │   └── base.repository.ts         # Repository générique (non utilisé activement)
    └── sms/
        └── sms.service.ts             # Simulation SMS — log console (Africa's Talking en prod)
```

### Pattern par module

Chaque module suit le pattern NestJS standard :

```
module.ts        → Configure les providers, imports, exports
controller.ts    → Définit les routes, applique les guards et pipes, délègue au service
service.ts       → Contient toute la logique métier, accède à Prisma
dto/             → Types + schémas Zod + classes Swagger (DtoDoc)
```

---

## 3. Modules — détail complet

### 3.1 Module Auth

**Préfixe :** `/api/v1/auth`

#### Routes

| Méthode | Path | Guard | Throttle | Description |
|---|---|---|---|---|
| `POST` | `/register` | Public | 10/min | Inscription + envoi OTP SMS |
| `POST` | `/verify-phone` | Public | Global | Vérification OTP téléphone → JWT |
| `POST` | `/verify-email` | Public | Global | Vérification OTP email → JWT |
| `POST` | `/resend-otp` | Public | 5/min | Renvoyer un OTP (phone ou email) |
| `POST` | `/forgot-password` | Public | 5/min | Demander reset mot de passe |
| `POST` | `/reset-password` | Public | Global | Réinitialiser avec OTP |
| `POST` | `/login` | Public | 10/min | Connexion → access + refresh tokens |
| `POST` | `/refresh` | RefreshAuthGuard | Global | Renouveler les tokens |
| `POST` | `/logout` | JwtAuthGuard | Global | Révoquer le refresh token |
| `GET` | `/me` | JwtAuthGuard | Global | Profil de l'utilisateur connecté |
| `PATCH` | `/me` | JwtAuthGuard | Global | Mettre à jour le profil |
| `GET` | `/google` | GoogleAuthGuard | Global | Redirection OAuth Google |
| `GET` | `/google/callback` | GoogleAuthGuard | Global | Callback OAuth Google |

#### DTOs

| Fichier | Champs Zod | Validation clé |
|---|---|---|
| `register.dto.ts` | `firstName`, `lastName`, `phone`, `password`, `city`, `district` | phone: regex international, password: min 6 |
| `login.dto.ts` | `phone`, `password` | phone requis |
| `verify-otp.dto.ts` | `VerifyPhoneDto {phone, code}` / `VerifyEmailDto {email, code}` | code: 5 chiffres |
| `resend-otp.dto.ts` | `phone?` ou `email?` | at least one required |
| `forgot-password.dto.ts` | `phone?` ou `email?` | — |
| `reset-password.dto.ts` | `phone?`/`email?`, `code`, `newPassword` | newPassword: min 6 |
| `refresh.dto.ts` | `refreshToken` | string requis |
| `update-profile.dto.ts` | `firstName?`, `lastName?`, `city?`, `district?` | tous optionnels |

#### Logique service (AuthService)

- **register** : vérifie unicité du phone, hash bcrypt du mot de passe, création user `PENDING`, génère OTP 5 chiffres, hash OTP en DB, envoie SMS
- **verifyPhone** : trouve user par phone, vérifie OTP haché, marque `isPhoneVerified=true`, status `ACTIVE`, retourne JWT pair
- **login** : trouve par phone, vérifie bcrypt, vérifie status non bloqué, vérifie `isPhoneVerified`, retourne JWT pair
- **refresh** : vérifie le refresh token haché en DB, génère nouveaux tokens, rotation du refresh token
- **logout** : met `refresh_token=null` en DB (révocation)
- **googleLogin** : trouve ou crée user par googleId/email, si non vérifié → envoie OTP email, si vérifié → JWT direct
- **forgotPassword** : message générique (anti-enumeration), envoie OTP via SMS ou email
- **OTP** : code 5 chiffres, hashé bcrypt, expiration 5 minutes, consommé à la première validation

---

### 3.2 Module Users & KYC

**Préfixe :** `/api/v1/users`

#### Routes

| Méthode | Path | Guard | Rôle requis | Description |
|---|---|---|---|---|
| `POST` | `/kyc/session-1` | JwtAuthGuard | Tout | Document identité (type + URL photo + selfie) |
| `POST` | `/kyc/session-2` | JwtAuthGuard | Tout | Informations financières (revenus + source + MoMo) |
| `POST` | `/kyc/session-3` | JwtAuthGuard | Tout | Soumission finale pour validation IMF |
| `GET` | `/kyc/status` | JwtAuthGuard | Tout | Statut KYC et données saisies |
| `GET` | `/kyc/pending` | JwtAuthGuard + RolesGuard | imf_staff, admin | Dossiers SESSION2_DONE soumis |
| `PATCH` | `/kyc/validate/:userId` | JwtAuthGuard + RolesGuard | imf_staff, admin | Approuver ou rejeter |
| `GET` | `/profile` | JwtAuthGuard | Tout | Profil complet + rôle + données métier |

#### Flux KYC

```
NOT_STARTED
    │ POST /kyc/session-1 (documentType, documentUrl, selfieUrl)
    ▼
SESSION1_DONE
    │ POST /kyc/session-2 (monthlyIncome, incomeSource, momoStatementUrl?)
    ▼
SESSION2_DONE
    │ POST /kyc/session-3 (déclenche kycSubmittedAt)
    ▼
SESSION2_DONE + kycSubmittedAt ── PATCH /kyc/validate/:userId (IMF Staff)
    ├── APPROVED ──► VALIDATED (compte activé, status=ACTIVE)
    └── REJECTED ──► REJECTED  (avec kycRejectionReason)
```

#### DTOs

| Fichier | Champs |
|---|---|
| `kyc-session1.dto.ts` | `documentType` (CNI/CIP/PASSEPORT/PERMIS), `documentUrl` (URL), `selfieUrl` (URL) |
| `kyc-session2.dto.ts` | `monthlyIncome` (number, max 10M), `incomeSource` (enum 6 valeurs), `momoStatementUrl?` |
| `kyc-validate.dto.ts` | `decision` (APPROVED/REJECTED), `reason?` (obligatoire si REJECTED) |

---

### 3.3 Module Files

**Préfixe :** `/api/v1/files`

| Méthode | Path | Guard | Description |
|---|---|---|---|
| `POST` | `/upload` | JwtAuthGuard | Upload image → retourne URL publique |

- **Stockage :** disque local dans `uploads/` (nom : `{timestamp}-{originalname}`)
- **Validation :** `mimetype.startsWith('image/')`, taille max 5 MB
- **Multer :** `memoryStorage()` — le buffer est disponible avant écriture sur disque
- **URL retournée :** `${BASE_URL}/uploads/{filename}`
- **Note production :** remplacer le stockage local par S3/Cloudinary/Supabase Storage

---

### 3.4 Module Loans

**Préfixe :** `/api/v1/loans`

#### Routes

| Méthode | Path | Guard | Rôle | Description |
|---|---|---|---|---|
| `GET` | `/loans/my` | JwtAuthGuard | Borrower | Mes prêts (paginé) |
| `GET` | `/loans/pending-imf` | JwtAuthGuard + RolesGuard | imf_staff, admin | Dossiers PENDING_IMF |
| `GET` | `/loans/:id` | JwtAuthGuard | Propriétaire ou IMF/Admin | Détail d'un prêt |
| `POST` | `/loans` | JwtAuthGuard | Borrower | Créer une demande |
| `PATCH` | `/loans/:id/validate` | JwtAuthGuard + RolesGuard | imf_staff, admin | Approuver/Rejeter |
| `POST` | `/loans/:id/repay` | JwtAuthGuard | Borrower propriétaire | Rembourser |
| `POST` | `/loans/:id/sandbox-score` | JwtAuthGuard + RolesGuard | imf_staff, admin | Scoring IMF simulé |

#### Règles BCEAO strictes

```
Montant         : 25 000 ≤ amount ≤ 500 000 FCFA
Durée           : 3, 6, 9 ou 12 mois (valeurs strictes)
Taux maximum    : 18% annuel (0.18)
Taux par défaut : 15% annuel (0.15) — appliqué à la création
```

#### DTOs

| Fichier | Champs clés |
|---|---|
| `create-loan.dto.ts` | `amount` (int, 25k–500k), `duration_months` (literal 3/6/9/12), `purpose` (10–500 chars) |
| `validate-loan.dto.ts` | `decision` (APPROVED/REJECTED), `interest_rate?` (0.01–0.18), `reason?` (requis si REJECTED) |
| `repay-loan.dto.ts` | `amount` (positif), `momo_reference` (unique), `momo_provider` (MTN_MOMO/MOOV_FLOOZ) |

#### Logique service (LoansService)

**`createLoan`**
1. Vérifie existence du `Borrower` → 403 sinon
2. Vérifie `kyc_status === 'VALIDATED'` → 403 sinon
3. Vérifie absence de prêt ACTIVE/OVERDUE/FUNDING → 400 sinon
4. Calcule `hybrid_score` via `computeHybridScore()` (persisté dans `BorrowerScore`)
5. Calcule la mensualité (formule amortissable) au taux par défaut 15%
6. Crée le prêt en `PENDING_IMF`

**`validateLoan`** (IMF Staff)
- APPROVED → statut `FUNDING`, taux final fixé, mensualité recalculée, `validated_by_imf=true`
- REJECTED → statut `CANCELLED`, `rejection_reason` sauvegardé

**`repayLoan`**
1. Vérifie ownership et statut ACTIVE/OVERDUE
2. Idempotence : `momo_reference` unique (rejet si déjà utilisée)
3. Réduit `outstanding_balance`
4. Si balance ≤ 0 → statut `REPAID`
5. Avance `next_due_date` selon le nombre de mensualités couverts
6. Bonus `credit_score` +2 pts si remboursement à temps
7. Crée une `Transaction` de type `LOAN_REPAYMENT` (atomique)

**`computeHybridScore`** (privé)
```
momo_score    = min(100, Borrower.credit_score)             × poids 40%
tontine_score = min(100, Borrower.tontine_score)            × poids 35%
imf_score     = max(0, 100 - Borrower.default_count × 25)  × poids 25%
hybrid_score  = momo_score × 0.40 + tontine_score × 0.35 + imf_score × 0.25
```
Les poids sont lus depuis `ScoringEngine` en DB (fallback 0.40/0.35/0.25).

**`calculateMonthlyInstallment`** (privé)
```
r = annualRate / 12
M = amount × r × (1+r)^n / ((1+r)^n - 1)
Si r = 0 : M = amount / months
```

#### ImfSandboxService

Simule le retour d'un scoring IMF externe sans appel HTTP réel.

| Score hybride | Recommandation | Taux suggéré | Niveau risque |
|---|---|---|---|
| ≥ 70 | `APPROVE` | 12% | LOW |
| 50–69 | `APPROVE_WITH_CONDITIONS` | 15% | MEDIUM |
| 30–49 | `HIGH_RISK` | 18% | HIGH |
| < 30 | `REJECT` | — | VERY_HIGH |

Facteurs de risque analysés : défauts de remboursement, absence d'historique tontine, montant ≥ 400k FCFA, durée maximale 12 mois.

---

### 3.5 Module Investments

**Préfixe :** `/api/v1/investments`

#### Routes

| Méthode | Path | Guard | Description |
|---|---|---|---|
| `GET` | `/investments/my` | JwtAuthGuard | Portefeuille paginé (filtre par statut) |
| `GET` | `/investments/my/summary` | JwtAuthGuard | Résumé : totaux, NPL ratio, statuts |
| `GET` | `/investments/auto-invest` | JwtAuthGuard | Règle Auto-Invest active |
| `PUT` | `/investments/auto-invest` | JwtAuthGuard | Créer / mettre à jour la règle |
| `POST` | `/investments/auto-invest/run` | JwtAuthGuard | Lancer le matching manuellement |
| `GET` | `/investments/:id` | JwtAuthGuard | Détail d'un investissement |
| `POST` | `/investments` | JwtAuthGuard | Investir sur un prêt FUNDING |

#### DTOs

| Fichier | Champs |
|---|---|
| `create-investment.dto.ts` | `loan_id` (UUID), `amount` (int, min 5000) |
| `auto-invest-rule.dto.ts` | `is_active` (bool), `max_amount` (max 500k), `max_duration` (3/6/9/12), `min_hybrid_score?` (0–100) |

#### Logique service (InvestmentsService)

**`createInvestment`** — transaction Prisma atomique :
1. Vérifie `Investor` et solde `wallet_balance`
2. Vérifie prêt en `FUNDING` et montant restant disponible
3. Vérifie que `GuaranteeFund.suspension_active = false`
4. Calcule `expected_return` = proportion × intérêts totaux du prêt
5. Crée l'investissement
6. Débite `wallet_balance`, incrémente `total_invested`
7. Crée `GuaranteeFundInvestment` (couverture 100%) + recalcule `coverage_ratio`
8. Si prêt 100% financé → transition `FUNDING → ACTIVE` + `disbursed_at` + `next_due_date`

**`runAutoInvest`** — matching automatique :
1. Lit la règle `AutoInvestRule` de l'investisseur
2. Récupère tous les prêts `FUNDING` avec `duration_months ≤ max_duration`
3. Pour chaque prêt : filtre par `hybrid_score ≥ min_hybrid_score`
4. Investit `min(max_amount, remaining, wallet_balance)` via `createInvestment`
5. Retourne un rapport : `loansScanned`, `investmentsCreated`, `totalInvested`, `skipped[]`

---

### 3.6 Module Tontine

**Préfixe :** `/api/v1/tontine`

#### Routes

| Méthode | Path | Guard | Rôle | Description |
|---|---|---|---|---|
| `GET` | `/tontine/my-score` | JwtAuthGuard | Borrower | Score tontine + métriques |
| `GET` | `/tontine/groups` | JwtAuthGuard | Tous | Liste des groupes (filtre statut) |
| `POST` | `/tontine/groups` | JwtAuthGuard | Borrower | Créer un groupe |
| `GET` | `/tontine/groups/:id` | JwtAuthGuard | Tous | Détail + membres + cycles |
| `POST` | `/tontine/groups/:id/join` | JwtAuthGuard | Borrower | Rejoindre un groupe |
| `POST` | `/tontine/groups/:id/cycles` | JwtAuthGuard | Leader | Démarrer un cycle |
| `PATCH` | `/tontine/cycles/:id/complete` | JwtAuthGuard | Leader | Clôturer un cycle |

#### DTOs

| Fichier | Champs |
|---|---|
| `create-tontine-group.dto.ts` | `name` (3–150 chars), `monthly_contribution` (int, min 1000) |
| `create-cycle.dto.ts` | `cycle_number` (≥1), `start_date` (YYYY-MM-DD), `end_date` (> start), `beneficiary_id` (UUID membre) |
| `complete-cycle.dto.ts` | `members_paid` (≥0), `members_defaulted` (≥0), `total_collected` (positif) |

#### Calcul du `tontine_score`

Déclenché à chaque clôture de cycle (via `recalculateTontineScore`) :

```
Pour tous les groupes dont le borrower est membre :
  Pour chaque cycle complété :
    payment_rate = members_paid / (members_paid + members_defaulted) × 100

tontine_score = moyenne(payment_rates)   # sur 0–100
has_tontine_history = true si ≥ 1 cycle complété
```

Ce score impacte directement le `hybrid_score` du module Loans (poids 35%).

#### Règles métier

- Un borrower ne peut être leader que d'un seul groupe PENDING/ACTIVE simultanément
- Le leader est automatiquement ajouté comme premier membre à la création
- La création du premier cycle active le groupe (`PENDING → ACTIVE` automatique)
- Le bénéficiaire d'un cycle doit être membre du groupe
- Le numéro de cycle est unique par groupe (`@@unique([group_id, cycle_number])`)

---

### 3.7 Module Transactions

**Préfixe :** `/api/v1/transactions`

#### Routes

| Méthode | Path | Guard | Rôle | Description |
|---|---|---|---|---|
| `GET` | `/transactions/my` | JwtAuthGuard | Tous | Historique paginé (filtre type) |
| `GET` | `/transactions/unreconciled` | JwtAuthGuard + RolesGuard | admin | Non réconciliées + détection PHANTOM |
| `POST` | `/transactions/deposit` | JwtAuthGuard | Investor | Initier un dépôt MoMo |
| `POST` | `/transactions/withdraw` | JwtAuthGuard | Investor | Initier un retrait MoMo |
| `POST` | `/transactions/webhook/fedapay` | **Public** | — | Callback FedaPay |
| `POST` | `/transactions/webhook/kkiapay` | **Public** | — | Callback KKiaPay |
| `PATCH` | `/transactions/:id/reconcile` | JwtAuthGuard + RolesGuard | admin | Marquer réconciliée |

> ⚠️ Les endpoints webhook sont **publics** (pas de JWT) — ils sont appelés directement par FedaPay/KKiaPay.

#### Flux dépôt

```
1. POST /deposit   → Transaction PENDING créée, référence NEXUS-{ts}-{rand} générée
2. Frontend redirige l'utilisateur vers paymentUrl (FedaPay/KKiaPay)
3. Utilisateur paie via MoMo
4. Provider appelle POST /webhook/{provider} avec momo_reference + status
5. Si CONFIRMED → Transaction CONFIRMED + credit wallet_balance investisseur
6. Si FAILED    → Transaction FAILED
```

#### Flux retrait

```
1. POST /withdraw  → Vérif solde, débit wallet immédiat, Transaction PENDING
2. Provider envoie le montant sur le numéro MoMo
3. POST /webhook/{provider}
4. Si CONFIRMED → Transaction CONFIRMED (wallet déjà débité)
5. Si FAILED    → Transaction FAILED + reversal (wallet_balance re-crédité)
```

#### Détection PHANTOM

Déclenchée automatiquement à chaque appel de `GET /unreconciled` :
- Cherche toutes les transactions `PENDING` créées il y a plus de 24 heures
- Les marque `PHANTOM_DETECTED`
- Log un warning avec le count

#### Idempotence webhook

Si la transaction est déjà `CONFIRMED` ou `FAILED`, le webhook retourne `{ processed: true }` sans retraitement.

Si la `momo_reference` est inconnue et que le statut est `CONFIRMED` → détection PHANTOM (référence inconnue confirmée par le provider).

---

### 3.8 Module Admin

**Préfixe :** `/api/v1/admin`  
**Toutes les routes requièrent :** JwtAuthGuard + RolesGuard + `@Roles('admin')`

#### Routes

| Méthode | Path | Description |
|---|---|---|
| `GET` | `/admin/dashboard` | Statistiques globales en temps réel |
| `GET` | `/admin/reports/bceao?from=&to=` | Rapport BCEAO sur période |
| `GET` | `/admin/guarantee-fund` | État du fonds de garantie |
| `GET` | `/admin/users` | Tous les utilisateurs (pagination + filtres) |
| `GET` | `/admin/users/:id` | Fiche complète d'un utilisateur |
| `PATCH` | `/admin/users/:id/status` | Bloquer / suspendre / réactiver |

#### Dashboard — données agrégées

```typescript
{
  users: { total, kycValidated, kycPending, activeToday }
  loans: { totalCount, activeCount, overdueCount, repaidCount,
           pendingImfCount, totalPortfolioValue, nplRatio }
  transactions: { todayCount, todayVolume, pendingCount, phantomCount }
  guaranteeFund: { totalCapital, activePortfolioValue, coverageRatio, suspensionActive }
}
```

#### Rapport BCEAO

Paramètres : `?from=YYYY-MM-DD&to=YYYY-MM-DD`

Contenu :
- Encours total (outstanding_balance) + total décaissé (amount)
- Taux NPL = prêts OVERDUE / total prêts sur la période
- Répartition par durée (3/6/9/12 mois)
- Répartition par tranche (25k–100k, 100k–250k, 250k–500k FCFA)
- Transactions : réconciliées vs non-réconciliées vs PHANTOM
- Fonds de garantie : ratio, seuils, suspension

---

## 4. Authentification et sécurité

### Flow JWT complet

```
Inscription
  → SMS OTP (5 min) → Vérification → ACCESS_TOKEN (7j) + REFRESH_TOKEN (30j)

Connexion
  → bcrypt.compare(password, hash) → vérif isPhoneVerified → tokens

Access Token (JWT)
  Payload : { sub: userId, phone: string }
  Secret  : JWT_SECRET
  Durée   : JWT_EXPIRES_IN (défaut 7j)

Refresh Token (JWT)
  Payload : { sub: userId, phone: string }
  Secret  : JWT_REFRESH_SECRET
  Durée   : JWT_REFRESH_EXPIRES_IN (défaut 30j)
  Stockage: hash bcrypt en DB (champ refresh_token) — rotation à chaque refresh

Token révoqué si :
  - Logout (refresh_token = null)
  - Reset mot de passe (refresh_token = null)
  - Compte bloqué (ForbiddenException sur refresh)
  - Token DB ne correspond plus (rejet + effacement → sécurité anti-replay)
```

### Guards disponibles

| Guard | Fichier | Mécanisme |
|---|---|---|
| `JwtAuthGuard` | `auth/guards/jwt-auth.guard.ts` | `AuthGuard('jwt')` — vérifie le Bearer token |
| `RefreshAuthGuard` | `auth/guards/refresh-auth.guard.ts` | `AuthGuard('refresh')` — vérifie le refresh token |
| `GoogleAuthGuard` | `auth/guards/google-auth.guard.ts` | `AuthGuard('google')` — redirect OAuth |
| `RolesGuard` | `shared/guards/roles.guard.ts` | Lit les rôles via `Reflector`, vérifie en DB |
| `ThrottlerGuard` | via `APP_GUARD` | Rate limiting global (100 req/min par IP) |

### RolesGuard — fonctionnement

```typescript
// Appliqué via @Roles('imf_staff', 'admin')
// Pour chaque rôle requis, RolesGuard fait une requête Prisma :
imf_staff → prisma.imfStaff.findUnique({ where: { id: userId } })
admin     → prisma.admin.findUnique({ where: { id: userId } })
investor  → prisma.investor.findUnique({ where: { id: userId } })
borrower  → prisma.borrower.findUnique({ where: { id: userId } })
agent     → prisma.agent.findUnique({ where: { id: userId } })
```

> Le rôle est déterminé par l'existence d'un enregistrement dans la table correspondante, pas par un champ `role` sur l'utilisateur.

### Décorateurs custom

```typescript
// @CurrentUser() — injecte le JwtPayload depuis request.user
@CurrentUser() user: JwtPayload
// → { sub: string (userId), phone: string }

// @Roles() — définit les rôles requis pour RolesGuard
@Roles('imf_staff', 'admin')
```

### Google OAuth flow

```
GET /auth/google → Redirect Google consent screen
Google callback  → GoogleStrategy valide le profil
                 → Si email vérifié + ACTIVE : tokens directs
                 → Si nouveau : création compte + OTP email
GET /auth/google/callback → { needsVerification: bool, tokens?: AuthTokens }
```

### Rate limiting

| Route | Limite |
|---|---|
| Toutes les routes | 100 req/min par IP (global) |
| `POST /auth/register` | 10 req/min |
| `POST /auth/login` | 10 req/min |
| `POST /auth/resend-otp` | 5 req/min |
| `POST /auth/forgot-password` | 5 req/min |

### Helmet — headers HTTP sécurisés

Activé globalement via `app.use(helmet())` dans `main.ts`. Protège contre :
- Cross-Site Scripting (XSS)
- Clickjacking (`X-Frame-Options`)
- MIME type sniffing
- Référent information leak

### Filtre Prisma — mapping d'erreurs

| Code Prisma | HTTP | Message |
|---|---|---|
| P2002 | 409 Conflict | Contrainte unique violée (champ affiché) |
| P2025 | 404 Not Found | Enregistrement introuvable |
| P2003 | 400 Bad Request | Clé étrangère invalide |
| P2014 | 400 Bad Request | Relation requise non satisfaite |
| P2011 | 400 Bad Request | Champ obligatoire manquant |
| Autres | 500 | Erreur base de données |

---

## 5. Base de données

### Modèles Prisma

#### User
```
id               UUID (PK, gen_random_uuid)
firstName        VARCHAR(150)
lastName         VARCHAR(150)
phone            VARCHAR(20) UNIQUE
email            VARCHAR(200) UNIQUE nullable
city             nullable
district         nullable
googleId         UNIQUE nullable
avatar           nullable
status           ENUM(PENDING, ACTIVE, SUSPENDED, BLOCKED) default PENDING
otpCode          nullable — hash bcrypt du code 5 chiffres
otpExpiry        DateTime nullable
otpType          nullable — 'PHONE_VERIFICATION' | 'EMAIL_VERIFICATION' | 'PASSWORD_RESET'
isPhoneVerified  Boolean default false
isEmailVerified  Boolean default false
kyc_status       ENUM(NOT_STARTED, SESSION1_DONE, SESSION2_DONE, VALIDATED, REJECTED)
kyc_document_url nullable (ancien champ, non utilisé activement)
kycSelfieUrl     nullable @map("kyc_selfie_url")
kycDocumentType  nullable — CNI | CIP | PASSEPORT | PERMIS
kycDocumentUrl   nullable
kycMonthlyIncome Decimal nullable
kycIncomeSource  nullable
kycMomoStatement nullable
kycRejectionReason nullable
kycSubmittedAt   DateTime nullable
kycValidatedAt   DateTime nullable
kycValidatedBy   UUID nullable — référence IMF Staff
password         nullable — hash bcrypt
refresh_token    nullable — hash bcrypt du refresh token
created_at       DateTime default now()
last_login       DateTime nullable
```

#### Investor
```
id               UUID (FK → User, Cascade)
wallet_balance   Decimal(15,2) default 0
total_invested   Decimal(15,2) default 0
total_returns    Decimal(15,2) default 0
risk_profile     ENUM(CONSERVATIVE, BALANCED, DYNAMIC) default BALANCED
investor_type    ENUM(RETAIL, INSTITUTIONAL) default RETAIL
```
Relations : `User(1-1)`, `Investment(1-N)`, `RetailInvestor(1-1)?`, `InstitutionalInvestor(1-1)?`, `AutoInvestRule(1-1)?`

#### AutoInvestRule
```
id               UUID (PK)
investor_id      UUID UNIQUE (FK → Investor, Cascade)
is_active        Boolean default true
max_amount       Decimal(15,2)
max_duration     Int — en mois (3/6/9/12)
min_hybrid_score Decimal(5,2) default 0
created_at       DateTime default now()
```

#### Borrower
```
id                  UUID (FK → User, Cascade)
credit_score        Decimal(5,2) default 0  — score MoMo 0–100
tontine_score       Decimal(5,2) default 0  — score tontine 0–100
mobile_money_number VARCHAR(20) UNIQUE
momo_provider       ENUM(MTN_MOMO, MOOV_FLOOZ)
has_tontine_history Boolean default false
default_count       Int default 0 — nombre de défauts de remboursement
```
Relations : `User(1-1)`, `Loan(1-N)`, `BorrowerScore(1-N)`, `TontineGroup(1-N)`, `TontineMember(1-N)`, `TontineCycle(1-N)`

#### Loan
```
id                  UUID (PK)
borrower_id         UUID (FK → Borrower)
amount              Decimal(15,2)
interest_rate       Decimal(5,4) — ex: 0.1500 = 15%
duration_months     Int — 3, 6, 9 ou 12
status              ENUM(PENDING_IMF, FUNDING, ACTIVE, OVERDUE, GUARANTEE_ACTIVATED,
                         REPURCHASED, REPAID, CANCELLED, RESTRUCTURED)
monthly_installment Decimal(15,2)
outstanding_balance Decimal(15,2)
days_overdue        Int default 0
validated_by_imf    Boolean default false
disbursed_at        DateTime nullable
next_due_date       Date nullable
imf_validated_by    UUID nullable (FK → ImfStaff)
purpose             VARCHAR(500) nullable
rejection_reason    VARCHAR(500) nullable
created_at          DateTime default now()
```
Relations : `Borrower(N-1)`, `ImfStaff(N-1)?`, `Investment(1-N)`

#### Investment
```
id               UUID (PK)
investor_id      UUID (FK → Investor)
loan_id          UUID (FK → Loan)
amount           Decimal(15,2)
expected_return  Decimal(15,2) — intérêts attendus proportionnels
actual_return    Decimal(15,2) default 0
status           ENUM(ACTIVE, COMPLETED, DEFAULTED, GUARANTEED) default ACTIVE
is_guaranteed    Boolean default true
guarantee_tier   Int default 1
maturity_date    Date
```
Relations : `Investor(N-1)`, `Loan(N-1)`, `GuaranteeFundInvestment(1-N)`

#### Transaction
```
id             UUID (PK)
type           ENUM(INVESTOR_DEPOSIT, INVESTOR_WITHDRAWAL, LOAN_DISBURSEMENT,
                    LOAN_REPAYMENT, PLATFORM_COMMISSION, GUARANTEE_ACTIVATION,
                    IMF_REPURCHASE, AGENT_COMMISSION)
amount         Decimal(15,2)
status         ENUM(PENDING, CONFIRMED, RECONCILED, FAILED, PHANTOM_DETECTED)
momo_reference VARCHAR(100) UNIQUE nullable — clé d'idempotence
momo_provider  ENUM(MTN_MOMO, MOOV_FLOOZ) nullable
initiated_at   DateTime default now() — piste d'audit 5 ans (BCEAO)
confirmed_at   DateTime nullable
reconciled_at  DateTime nullable
is_reconciled  Boolean default false
failure_reason VARCHAR(300) nullable
created_by     UUID (FK → User)
```

#### TontineGroup
```
id                   UUID (PK)
name                 VARCHAR(150)
leader_user_id       UUID (FK → Borrower)
leader_phone         VARCHAR(20)
member_count         Int default 1
monthly_contribution Decimal(15,2)
completed_cycles     Int default 0
status               ENUM(PENDING, ACTIVE, COMPLETED, SUSPENDED) default PENDING
```
Relations : `Borrower(N-1)`, `TontineMember(1-N)`, `TontineCycle(1-N)`

#### TontineMember
```
id          UUID (PK)
group_id    UUID (FK → TontineGroup, Cascade)
borrower_id UUID (FK → Borrower)
joined_at   DateTime default now()
@@unique([group_id, borrower_id])
```

#### TontineCycle
```
id                UUID (PK)
group_id          UUID (FK → TontineGroup, Cascade)
cycle_number      Int
start_date        Date
end_date          Date
total_collected   Decimal(15,2) default 0
is_complete       Boolean default false
beneficiary_id    UUID (FK → Borrower)
members_paid      Int default 0
members_defaulted Int default 0
@@unique([group_id, cycle_number])
```

#### GuaranteeFund
```
id                       UUID (PK)
total_capital            Decimal(15,2) default 0
active_portfolio_value   Decimal(15,2) default 0
coverage_ratio           Decimal(5,4) default 0 — total_capital / active_portfolio_value
min_threshold            Decimal(5,4) default 0.03 — 3% : seuil de suspension
target_threshold         Decimal(5,4) default 0.05 — 5% : cible BCEAO
suspension_active        Boolean default false
last_reconstitution_date Date nullable
```

#### GuaranteeFundInvestment
```
fund_id        UUID (FK → GuaranteeFund)
investment_id  UUID (FK → Investment)
covered_amount Decimal(15,2)
activated_at   DateTime nullable
is_activated   Boolean default false
@@unique([fund_id, investment_id])
```

#### BorrowerScore
```
id            UUID (PK)
borrower_id   UUID (FK → Borrower)
momo_score    Decimal(5,2)
tontine_score Decimal(5,2)
imf_score     Decimal(5,2)
hybrid_score  Decimal(5,2)
computed_at   DateTime default now()
```

#### ScoringEngine
```
id                  UUID (PK, singleton)
momo_weight         Decimal(3,2) default 0.40
tontine_weight      Decimal(3,2) default 0.35
imf_weight          Decimal(3,2) default 0.25
warning_signal_days Int default 45
```

#### Admin, ImfStaff, Agent, RetailInvestor, InstitutionalInvestor
Modèles de rôles liés à `User`/`Investor` par la même PK (FK + Cascade). Un seul enregistrement par utilisateur dans la table correspondant à son rôle.

### Migrations appliquées

| Migration | Contenu |
|---|---|
| `20260415112051_add_auth_fields` | Champs OTP, refresh_token, last_login |
| `20260415231421_update_user_auth_fields` | Ajustements champs auth |
| `20260416133756_add_kyc_fields` | kycDocumentType, kycDocumentUrl, kycMonthlyIncome, etc. |
| `20260418153418_add_kyc_selfie_url` | kyc_selfie_url sur users |
| `20260418200000_add_loan_fields` | purpose, rejection_reason, created_at sur loans |
| `20260419100000_add_auto_invest_rule` | Table auto_invest_rules |

---

## 6. Variables d'environnement

| Variable | Requis | Exemple | Description |
|---|---|---|---|
| `DATABASE_URL` | ✅ | `postgresql://nexus_user:pass@localhost:5432/nexus_db` | URL de connexion PostgreSQL |
| `JWT_SECRET` | ✅ | `openssl rand -hex 64` | Secret pour signer les access tokens |
| `JWT_EXPIRES_IN` | ✅ | `7d` | Durée de vie access token |
| `JWT_REFRESH_SECRET` | ✅ | `openssl rand -hex 64` | Secret pour signer les refresh tokens |
| `JWT_REFRESH_EXPIRES_IN` | ✅ | `30d` | Durée de vie refresh token |
| `PORT` | ✅ | `3000` | Port d'écoute du serveur |
| `NODE_ENV` | ✅ | `development` / `production` | Environnement (influence les logs et sandbox) |
| `BASE_URL` | ✅ | `http://localhost:3000` | URL publique du serveur (URLs d'upload + payment_url) |
| `PAYMENT_RETURN_URL` | ⚠️ | `http://localhost:8081/wallet?status=success` | Redirection frontend après paiement réussi |
| `PAYMENT_FAILURE_URL` | ⚠️ | `http://localhost:8081/wallet?status=failed` | Redirection frontend après paiement échoué |
| `FEDAPAY_API_BASE_URL` | ⚠️ | `https://sandbox-api.fedapay.com/v1` | Base URL FedaPay sandbox |
| `FEDAPAY_SECRET_KEY` | ⚠️ | `sk_sandbox_xxxxx` | Clé secrète FedaPay (paiement/payout sandbox) |
| `FEDAPAY_PUBLIC_KEY` | ⚠️ | `pk_sandbox_xxxxx` | Clé publique FedaPay |
| `FEDAPAY_WEBHOOK_SECRET` | ⚠️ | `whsec_sandbox_xxxxx` | Secret de signature webhook FedaPay |
| `KKIAPAY_API_BASE_URL` | ⚠️ | `https://api-sandbox.kkiapay.me` | Base URL KKiaPay sandbox |
| `KKIAPAY_WIDGET_BASE_URL` | ⚠️ | `https://cdn.kkiapay.me` | Base URL du widget KKiaPay sandbox |
| `KKIAPAY_PUBLIC_KEY` | ⚠️ | `pk_sandbox_xxxxx` | Clé publique KKiaPay |
| `KKIAPAY_SECRET_KEY` | ⚠️ | `sk_sandbox_xxxxx` | Clé secrète KKiaPay |
| `KKIAPAY_WEBHOOK_SECRET` | ⚠️ | `kkiapay_webhook_secret` | Secret du header `x-kkiapay-secret` |
| `PAYMENT_GATEWAY_MTN_MOMO` | ⚠️ | `FEDAPAY` | Mapping interne MTN -> gateway |
| `PAYMENT_GATEWAY_MOOV_FLOOZ` | ⚠️ | `KKIAPAY` | Mapping interne MOOV -> gateway |
| `AFRICASTALKING_SMS_BASE_URL` | ⚠️ | `https://api.sandbox.africastalking.com/version1/messaging` | Endpoint SMS sandbox Africa's Talking |
| `AFRICASTALKING_USERNAME` | ⚠️ | `sandbox` | Username Africa's Talking sandbox |
| `AFRICASTALKING_API_KEY` | ⚠️ | `ATSandboxApiKey` | API key Africa's Talking |
| `AFRICASTALKING_SENDER_ID` | ⚠️ | `NEXUS` | Expéditeur affiché des SMS |
| `IMF_SANDBOX_URL` | ⚠️ | `http://localhost:3001/imf-sandbox` | URL simulateur IMF externe |
| `IMF_SANDBOX_TOKEN` | ⚠️ | `sandbox_token_dev` | Token auth vers le simulateur IMF |
| `GOOGLE_CLIENT_ID` | ⚠️ | `xxxxx.apps.googleusercontent.com` | Client ID OAuth Google |
| `GOOGLE_CLIENT_SECRET` | ⚠️ | `GOCSPX-xxxxx` | Client Secret OAuth Google |
| `GOOGLE_CALLBACK_URL` | ⚠️ | `http://localhost:3000/api/v1/auth/google/callback` | URL de callback OAuth |
| `MAIL_HOST` | ✅ | `smtp.gmail.com` | Serveur SMTP |
| `MAIL_PORT` | ✅ | `587` | Port SMTP |
| `MAIL_USER` | ✅ | `votre@gmail.com` | Adresse email expéditeur |
| `MAIL_PASSWORD` | ✅ | `xxxx xxxx xxxx xxxx` | Mot de passe application Gmail |
| `MAIL_FROM` | ✅ | `Nexus <votre@gmail.com>` | Nom et adresse affichés |
| `OTP_EXPIRY_MINUTES` | — | `5` | Durée de vie OTP en minutes (hardcodé à 5 min) |

> ⚠️ = Requis en production, optionnel en développement (dégradation gracieuse ou sandbox)

---

## 7. Services partagés

### PrismaService

```typescript
// src/shared/prisma/prisma.service.ts
class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy
```

- Utilise `@prisma/adapter-pg` avec un `Pool` pg natif (meilleure performance que le mode TCP standard)
- Connexion à l'init du module (`$connect()` + log ✅)
- Déconnexion propre au destroy (`$disconnect()` + `pool.end()`)
- Le module est `@Global()` → `PrismaService` disponible dans tous les modules sans import explicite

### MailService

- Nodemailer avec transport SMTP Gmail (`starttls` sur le port 587)
- `sendOtpEmail(to, firstName, code)` : email HTML responsive avec le code OTP centré
- Emails métier automatiques :
  - dépôt/retrait initié, confirmé, échoué
  - prêt en retard
  - remboursement reçu
- Template inline (pas de fichier externe) pour simplifier le déploiement
- En cas d'erreur SMTP : throw (l'inscription échoue explicitement)

### SmsService

- Intégration **Africa's Talking sandbox** via `POST /version1/messaging`
- Fallback `log-only` si `AFRICASTALKING_USERNAME` ou `AFRICASTALKING_API_KEY` manque en local
- Retry/backoff configurable via env (`AFRICASTALKING_SMS_RETRY_*`)
- Notifications gérées :
  - OTP inscription / renvoi / reset password
  - dépôt / retrait initié, confirmé, échoué
  - prêt en retard
  - remboursement de prêt reçu

### Automatisation

- **Auto-Invest cron** : exécution toutes les 30 minutes sur toutes les règles actives
- **Maintenance fonds de garantie** : recalcul quotidien du ratio + reconstitution depuis `platform_wallet.commission_balance` si nécessaire
- **Activation garantie** : passage quotidien des `GuaranteeFundInvestment` en `is_activated=true` pour les prêts en `GUARANTEE_ACTIVATED`

### Cache applicatif

- Cache TTL pour :
  - `GET /admin/dashboard` (60s)
  - `GET /admin/guarantee-fund` (60s)
- Backend Redis-ready via `ioredis` :
  - si `REDIS_URL` est configurée et joignable, le cache devient partagé
  - sinon fallback automatique en mémoire locale
- Objectif : réduire les agrégations Prisma répétées et préparer le déploiement multi-instance

### ZodValidationPipe

```typescript
// Usage dans les controllers
@Body(new ZodValidationPipe(schema)) dto: Dto
```

- Appelle `schema.safeParse(value)`
- En cas d'erreur : `BadRequestException({ success: false, errors: [{field, message}], message: 'Données invalides' })`
- Compatible avec les schémas Zod v4 (`zod/v4`)

### PrismaExceptionFilter

```typescript
@Catch(Prisma.PrismaClientKnownRequestError)
class PrismaExceptionFilter implements ExceptionFilter
```

- Enregistré globalement dans `main.ts` via `app.useGlobalFilters()`
- Traduit les codes d'erreur Prisma en réponses HTTP cohérentes
- Log le code Prisma + le message tronqué

---

## 8. Format des réponses API

### Format standard success

```json
{
  "success": true,
  "data": { ... },
  "message": "Description de l'opération"
}
```

### Format standard erreur (exceptions NestJS)

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Données invalides",
  "errors": [
    { "field": "amount", "message": "Le montant doit être entre 25 000 et 500 000 FCFA" }
  ]
}
```

### Format erreur Prisma (PrismaExceptionFilter)

```json
{
  "success": false,
  "message": "Valeur déjà utilisée — contrainte unique sur : phone",
  "code": "P2002"
}
```

### Format erreur rate limiting (ThrottlerGuard)

```json
{
  "statusCode": 429,
  "message": "ThrottlerException: Too Many Requests"
}
```

### Exemples de réponses par module

**Auth — POST /auth/login**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "firstName": "Kofi",
      "lastName": "Mensah",
      "phone": "+22997123456",
      "kyc_status": "NOT_STARTED",
      "status": "ACTIVE"
    }
  },
  "message": "Connexion réussie"
}
```

**Loans — POST /loans**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "borrowerId": "...",
    "amount": "150000",
    "interestRate": "0.1500",
    "durationMonths": 6,
    "status": "PENDING_IMF",
    "monthlyInstallment": "26194.44",
    "outstandingBalance": "150000",
    "purpose": "Achat de stock pour mon commerce",
    "hybridScore": 25
  },
  "message": "Demande de prêt soumise — en attente de validation IMF"
}
```

**Loans — POST /loans/:id/sandbox-score**
```json
{
  "success": true,
  "data": {
    "loanId": "...",
    "hybridScore": 62,
    "momoScore": 75,
    "tontineScore": 55,
    "imfScore": 50,
    "recommendation": "APPROVE_WITH_CONDITIONS",
    "suggestedInterestRate": 0.15,
    "riskLevel": "MEDIUM",
    "riskFactors": ["Aucun historique tontine — score de confiance réduit"],
    "computedAt": "2026-04-19T10:30:00.000Z"
  },
  "message": "Scoring sandbox : APPROVE_WITH_CONDITIONS — taux suggéré : 15%"
}
```

**Transactions — POST /transactions/deposit**
```json
{
  "success": true,
  "data": {
    "transaction": {
      "id": "...",
      "type": "INVESTOR_DEPOSIT",
      "amount": "50000",
      "status": "PENDING",
      "paymentGateway": "FEDAPAY",
      "momoReference": "NEXUS-1745056200000-X7K3P2",
      "momoProvider": "MTN_MOMO",
      "providerTransactionId": "123456",
      "providerStatus": "pending",
      "initiatedAt": "2026-04-19T10:30:00.000Z"
    },
    "gateway": "FEDAPAY",
    "providerTransactionId": "123456",
    "providerStatus": "pending",
    "paymentUrl": "https://sandbox-checkout.fedapay.com/...",
    "message": "Dépôt de 50 000 FCFA initié."
  },
  "message": "Dépôt de 50 000 FCFA initié."
}
```

**Admin — GET /admin/dashboard**
```json
{
  "success": true,
  "data": {
    "users": { "total": 24, "kycValidated": 12, "kycPending": 3, "activeToday": 2 },
    "loans": {
      "totalCount": 6, "activeCount": 3, "overdueCount": 1,
      "repaidCount": 1, "pendingImfCount": 1,
      "totalPortfolioValue": "750000", "nplRatio": 0.1667
    },
    "transactions": { "todayCount": 8, "todayVolume": "320000", "pendingCount": 2, "phantomCount": 0 },
    "guaranteeFund": {
      "totalCapital": "100000", "activePortfolioValue": "750000",
      "coverageRatio": "0.1333", "suspensionActive": false
    }
  },
  "message": "Dashboard récupéré"
}
```

---

## 9. Fonctionnalités non implémentées

Ces fonctionnalités sont mentionnées dans le CDC ou le ROADMAP mais n'ont pas été codées :

| Fonctionnalité | Raison / Commentaire |
|---|---|
| **Widget frontend KKiaPay à consommer** | Le backend prépare les métadonnées/provider payloads KKiaPay, mais l'ouverture du widget côté frontend reste à brancher explicitement |
| **Notification push / email remboursement** | Pas de notifications automatiques sur les événements (prêt validé, remboursement reçu, etc.) |
| **Disbursement MoMo** | Le décaissement vers l'emprunteur après financement n'est pas implémenté (transition FUNDING → ACTIVE crée `disbursed_at` mais n'envoie pas les fonds) |
| **IMF Sandbox HTTP réel** | L'appel vers `IMF_SANDBOX_URL` n'est pas implémenté — le service retourne une réponse calculée localement |
| **Rapport BCEAO export PDF/CSV** | Le rapport est en JSON uniquement |
| **Gestion multi-devises** | Tout est en FCFA, pas de conversion |
| **Endpoint modification mot de passe** | Un utilisateur connecté ne peut pas changer son mot de passe directement (uniquement via forgot-password) |

---

## 10. Points d'amélioration pour la production

### Sécurité

| Point | Risque actuel | Solution recommandée |
|---|---|---|
| **Upload non restreint** | Un utilisateur peut uploader n'importe quelle image sans lien avec son KYC | Lier chaque upload à un userId + type de document, limiter à 3 uploads par session KYC |
| **Stockage local des fichiers** | `uploads/` est perdu à chaque redéploiement | Migrer vers S3, Cloudinary, ou Supabase Storage |
| **JWT_SECRET en dur possible** | Si `.env` est committé par erreur | S3 Secrets Manager / Vault / Railway Secrets |
| **Pas de validation UUID en entrée** | Les UUIDs sont validés via `ParseUUIDPipe` sur les routes — vérifier la couverture complète | — |

### Performance

| Point | Impact | Solution |
|---|---|---|
| **RolesGuard : N requêtes Prisma** | Chaque appel vérifié fait 1–5 requêtes DB selon les rôles | Mettre le rôle dans le JWT payload ou utiliser Redis cache |
| **Cache Redis sans invalidation métier fine** | Le cache actuel est TTL-based et simple | Ajouter invalidation ciblée après mutations admin/transactions critiques si nécessaire |
| **Pas d'index sur `created_at` des Loans** | Requêtes paginées lentes sur grand volume | Ajouter `@@index([created_at])` sur Loan |
| **Pool pg non configuré** | `Pool` créé avec les paramètres par défaut | Configurer `max`, `idleTimeoutMillis`, `connectionTimeoutMillis` selon la charge |
| **Pas de pagination cursor** | La pagination `skip/take` est lente au-delà de 10k enregistrements | Migrer vers cursor-based pagination pour les grandes tables |

### Architecture

| Point | Commentaire |
|---|---|
| **RolesGuard couplé à Prisma** | Le guard fait des requêtes DB synchrones — à remplacer par un système de claims JWT |
| **Pas de queue pour les jobs async** | Dépôt/retrait devraient être traités en arrière-plan (Bull/BullMQ + Redis) |
| **Pas d'observabilité** | Pas de tracing distribué (OpenTelemetry), pas de métriques Prometheus |
| **Pas de gestion des migrations en CI/CD** | `prisma migrate deploy` doit être dans le pipeline de déploiement |
| **Fichiers generated/ dans le repo** | Le client Prisma généré est commité — risque de désynchronisation. À générer en CI |
| **Notifications sans queue** | Emails/SMS sont encore envoyés dans le flux applicatif | Basculer vers Bull/BullMQ pour lisser les pics et isoler les providers |

### Qualité du code

| Point | Commentaire |
|---|---|
| **Couverture tests insuffisante** | Les tests unitaires et d'intégration controller existent, mais il manque encore des scénarios complets avec vraie base et vrais providers sandbox |
| **`any` implicite dans certains casts** | Quelques `as never` dans adminService — à typer précisément |
| **Pas de logging structuré** | Les `Logger.log()` sont du texte libre — utiliser un format JSON pour la production (ex: pino) |
| **`.gitignore` à vérifier** | S'assurer que `.env`, `uploads/`, `node_modules/`, `dist/` sont bien ignorés |

---

*Documentation générée le 19 avril 2026 — Nexus P2P Lending, Bénin / UEMOA*
