# Nexus — Documentation Technique Backend

> Mémoire académique — 8 mai 2026 — v0.0.1

## 1. Informations Générales

- **Nom** : Nexus — Plateforme P2P Lending Bénin/UEMOA
- **Description** : Connecte emprunteurs et investisseurs via marketplace de prêts, intègre Mobile Money (MTN MoMo, Moov Flooz) et Tontine Bridge pour scoring de crédit.
- **Version** : 0.0.1 (développement)

## 2. Stack Technique

| Catégorie       | Librairie                  | Version                   |
| --------------- | -------------------------- | ------------------------- |
| Framework       | NestJS                     | ^11.0.1                   |
| Langage         | TypeScript                 | ^5.7.3                    |
| ORM             | Prisma                     | ^7.7.0                    |
| Base de données | PostgreSQL                 | —                         |
| Auth            | JWT + Passport + bcrypt    | ^11.0.2 / ^0.7.0 / ^6.0.0 |
| OAuth           | passport-google-oauth20    | ^2.0.0                    |
| Validation      | Zod                        | ^4.3.6                    |
| Paiement        | Fedapay + KKiaPay (custom) | —                         |
| Email           | nodemailer                 | ^8.0.5                    |
| Push            | firebase-admin (FCM)       | ^13.8.0                   |
| Upload          | cloudinary                 | ^2.9.0                    |
| Cache           | ioredis (Redis)            | ^5.10.1                   |
| Logging         | winston                    | ^3.19.0                   |
| Docs API        | @nestjs/swagger            | ^11.2.7                   |
| Tâches          | @nestjs/schedule           | ^6.1.3                    |
| Sécurité        | helmet + @nestjs/throttler | ^8.1.0 / ^6.5.0           |
| PDF             | pdfkit                     | ^0.18.0                   |
| Tests           | jest + ts-jest             | ^30.0.0 / ^29.2.5         |

## 3. Architecture

Pattern modulaire NestJS. Chaque domaine = 1 module (Controller + Service + DTOs).
Préfixe API global : `/api/v1`. Swagger : `/api/docs`.

```
src/
├── main.ts                  # Bootstrap, helmet, CORS, Swagger
├── app.module.ts            # Module racine
├── generated/prisma/        # Client Prisma auto-généré
├── shared/                  # Code transverse
│   ├── prisma/prisma.service.ts
│   ├── guards/roles.guard.ts
│   ├── decorators/{current-user,roles,public}.decorator.ts
│   ├── pipes/zod-validation.pipe.ts
│   ├── filters/prisma-exception.filter.ts
│   ├── cache/app-cache.service.ts
│   ├── mail/mail.service.ts
│   └── notifications/notification.service.ts
└── modules/
    ├── auth/                # Authentification
    ├── users/               # KYC progressif
    ├── loans/               # Prêts + scoring
    ├── investments/         # Portefeuille + Auto-Invest
    ├── tontine/             # Tontine Bridge
    ├── transactions/        # MoMo + gateways
    ├── admin/               # Dashboard + rapports
    ├── imf-staff/           # Agents IMF
    ├── agents/              # Agents de proximité
    ├── wallet/              # Escrow + Platform
    ├── guarantee-fund/      # Fonds de garantie
    ├── files/               # Upload fichiers
    └── logger/              # Logging HTTP
```

Communication inter-modules : injection de dépendances NestJS.

- `LoansModule` importe `GuaranteeFundModule` → `LoansService` injecte `GuaranteeFundService`
- `TransactionsModule` importe `WalletModule` → `TransactionsService` injecte `WalletService`

## 4. Routes HTTP

### Auth (`/api/v1/auth`)

| Méthode | Chemin             | Description                   | Auth    |
| ------- | ------------------ | ----------------------------- | ------- |
| POST    | `/register`        | Inscription + OTP email       | Non     |
| POST    | `/verify-email`    | Vérification OTP + activation | Non     |
| POST    | `/login`           | Connexion email/password      | Non     |
| POST    | `/resend-otp`      | Renvoyer OTP                  | Non     |
| POST    | `/forgot-password` | OTP reset password            | Non     |
| POST    | `/reset-password`  | Reset password (OTP)          | Non     |
| POST    | `/refresh`         | Renouveler tokens             | Refresh |
| POST    | `/logout`          | Déconnexion                   | JWT     |
| GET     | `/me`              | Profil connecté               | JWT     |
| PATCH   | `/me`              | Modifier profil               | JWT     |
| PATCH   | `/change-password` | Changer mot de passe          | JWT     |
| GET     | `/google`          | OAuth Google web              | OAuth   |
| GET     | `/google/callback` | Callback Google               | OAuth   |
| POST    | `/google/mobile`   | Google ID token mobile        | Non     |

### Users (`/api/v1/users`)

| Méthode | Chemin                  | Description             | Rôle            |
| ------- | ----------------------- | ----------------------- | --------------- |
| POST    | `/kyc/session-1`        | Pièce identité + selfie | —               |
| POST    | `/kyc/session-2`        | Infos financières       | —               |
| POST    | `/kyc/session-3`        | Soumission finale KYC   | —               |
| GET     | `/kyc/status`           | Statut KYC              | —               |
| GET     | `/profile`              | Profil complet          | —               |
| GET     | `/kyc/pending`          | Dossiers en attente     | imf_staff,admin |
| PATCH   | `/kyc/validate/:userId` | Approuver/rejeter KYC   | imf_staff,admin |

### Loans (`/api/v1/loans`)

| Méthode | Chemin               | Description                   | Rôle            |
| ------- | -------------------- | ----------------------------- | --------------- |
| GET     | `/my`                | Mes prêts                     | —               |
| GET     | `/funding`           | Marketplace investisseur      | —               |
| GET     | `/pending-imf`       | En attente validation         | imf_staff,admin |
| GET     | `/:id`               | Détail prêt                   | —               |
| POST    | `/`                  | Créer demande (KYC VALIDATED) | —               |
| PATCH   | `/:id/validate`      | Approuver/rejeter (IMF)       | imf_staff,admin |
| POST    | `/:id/repay`         | Remboursement MoMo            | —               |
| POST    | `/:id/sandbox-score` | Scoring sandbox IMF           | imf_staff,admin |

### Investments (`/api/v1/investments`)

| Méthode | Chemin             | Description               |
| ------- | ------------------ | ------------------------- |
| GET     | `/my`              | Portefeuille paginé       |
| GET     | `/my/summary`      | Résumé (totaux, NPL)      |
| GET     | `/:id`             | Détail investissement     |
| POST    | `/`                | Investir sur prêt FUNDING |
| GET     | `/auto-invest`     | Règle Auto-Invest         |
| PUT     | `/auto-invest`     | Configurer Auto-Invest    |
| POST    | `/auto-invest/run` | Lancer Auto-Invest        |

### Tontine (`/api/v1/tontine`)

| Méthode | Chemin                 | Description             |
| ------- | ---------------------- | ----------------------- |
| GET     | `/my-score`            | Score tontine           |
| GET     | `/groups`              | Liste groupes           |
| POST    | `/groups`              | Créer groupe (Borrower) |
| GET     | `/groups/:id`          | Détail groupe           |
| POST    | `/groups/:id/join`     | Rejoindre groupe        |
| POST    | `/groups/:id/cycles`   | [Leader] Nouveau cycle  |
| PATCH   | `/cycles/:id/complete` | [Leader] Clôturer cycle |

### Transactions (`/api/v1/transactions`)

| Méthode | Chemin             | Description             | Rôle   |
| ------- | ------------------ | ----------------------- | ------ |
| GET     | `/my`              | Historique              | —      |
| GET     | `/unreconciled`    | Non réconciliées        | admin  |
| POST    | `/deposit`         | Dépôt MoMo (Investor)   | —      |
| POST    | `/withdraw`        | Retrait MoMo (Investor) | —      |
| POST    | `/webhook/fedapay` | Webhook FedaPay         | Public |
| POST    | `/webhook/kkiapay` | Webhook KKiaPay         | Public |
| PATCH   | `/:id/reconcile`   | Réconcilier             | admin  |

### Admin (`/api/v1/admin`) — admin

| Méthode | Chemin                     | Description          |
| ------- | -------------------------- | -------------------- |
| GET     | `/dashboard`               | Dashboard NPL, stats |
| GET     | `/reports/bceao?from=&to=` | Rapport BCEAO        |
| GET     | `/guarantee-fund`          | Fonds de garantie    |
| GET     | `/users`                   | Liste utilisateurs   |
| GET     | `/users/:id`               | Fiche utilisateur    |
| PATCH   | `/users/:id/status`        | Bloquer/suspendre    |
| GET     | `/scoring-engine`          | Config scoring       |
| PATCH   | `/scoring-engine`          | Modifier poids       |

### IMF Staff (`/api/v1/imf-staff`) — imf_staff

| Méthode | Chemin             | Description      |
| ------- | ------------------ | ---------------- |
| GET     | `/profile`         | Profil IMF       |
| GET     | `/loans/pending`   | Prêts en attente |
| GET     | `/loans/validated` | Prêts traités    |
| GET     | `/dashboard`       | Statistiques     |

### Agents (`/api/v1/agents`) — agent

| Méthode | Chemin         | Description            |
| ------- | -------------- | ---------------------- |
| GET     | `/profile`     | Profil agent           |
| GET     | `/clients`     | Clients zone           |
| GET     | `/commissions` | Historique commissions |
| GET     | `/dashboard`   | Statistiques           |

### Wallet (`/api/v1/wallet`) — admin

| Méthode | Chemin      | Description         |
| ------- | ----------- | ------------------- |
| GET     | `/escrow`   | État EscrowWallet   |
| GET     | `/platform` | État PlatformWallet |
| GET     | `/summary`  | Vue consolidée      |

### Guarantee Fund (`/api/v1/guarantee-fund`)

| Méthode | Chemin                    | Description              | Rôle  |
| ------- | ------------------------- | ------------------------ | ----- |
| GET     | `/status`                 | État du fonds            | —     |
| GET     | `/investments`            | Investissements couverts | admin |
| POST    | `/activate/:investmentId` | Activer couverture       | admin |

## 5. Modèle de Données (Prisma)

### ENUMs

| Enum                 | Valeurs                                                                                                                                               |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `user_status`        | PENDING, ACTIVE, SUSPENDED, BLOCKED                                                                                                                   |
| `kyc_status`         | NOT_STARTED, SESSION1_DONE, SESSION2_DONE, VALIDATED, REJECTED                                                                                        |
| `loan_status`        | PENDING_IMF, FUNDING, ACTIVE, OVERDUE, GUARANTEE_ACTIVATED, REPURCHASED, REPAID, CANCELLED, RESTRUCTURED                                              |
| `investment_status`  | ACTIVE, COMPLETED, DEFAULTED, GUARANTEED                                                                                                              |
| `transaction_type`   | INVESTOR_DEPOSIT, INVESTOR_WITHDRAWAL, LOAN_DISBURSEMENT, LOAN_REPAYMENT, PLATFORM_COMMISSION, GUARANTEE_ACTIVATION, IMF_REPURCHASE, AGENT_COMMISSION |
| `transaction_status` | PENDING, CONFIRMED, RECONCILED, FAILED, PHANTOM_DETECTED                                                                                              |
| `momo_provider`      | MTN_MOMO, MOOV_FLOOZ                                                                                                                                  |
| `payment_gateway`    | FEDAPAY, KKIAPAY                                                                                                                                      |
| `risk_profile`       | CONSERVATIVE, BALANCED, DYNAMIC                                                                                                                       |
| `investor_type`      | RETAIL, INSTITUTIONAL                                                                                                                                 |
| `admin_role`         | SUPER_ADMIN, OPERATIONS, COMPLIANCE, SUPPORT                                                                                                          |
| `tontine_status`     | PENDING, ACTIVE, COMPLETED, SUSPENDED                                                                                                                 |
| `currency_code`      | XOF, USD, EUR, NGN                                                                                                                                    |

### Tables principales

**users** : id(UUID PK), firstName, lastName, phone(unique?), email(unique), city, district, googleId(unique?), avatar, password?, refresh_token?, status(user_status), isEmailVerified, otpCode?, otpExpiry?, otpType?, kyc_status, kycDocumentType?, kycDocumentUrl?, kycSelfieUrl?, kycMonthlyIncome?, kycIncomeSource?, kycMomoStatement?, kycRejectionReason?, kycSubmittedAt?, kycValidatedAt?, kycValidatedBy?, preferred_currency, push_tokens[], created_at, last_login?

- Relations: admin?, agent?, borrower?, imfStaff?, investor?, transactions[]

**investors** : id(UUID PK/FK→users), wallet_balance, total_invested, total_returns, risk_profile, investor_type

- Relations: user, investments[], autoInvestRule?, retailInvestor?, institutionalInvestor?

**borrowers** : id(UUID PK/FK→users), credit_score, tontine_score, mobile_money_number(unique), momo_provider, has_tontine_history, default_count

- Relations: user, loans[], tontine_cycles[], tontine_groups[], tontine_members[], borrower_scores[]

**loans** : id(UUID PK), borrower_id(FK), amount, currency, interest_rate, duration_months, status(loan_status), monthly_installment, outstanding_balance, days_overdue, validated_by_imf, disbursed_at?, next_due_date?, imf_validated_by?(FK→imf_staff), purpose?, rejection_reason?, created_at

- Relations: borrowers, imf_staff?, investments[]

**investments** : id(UUID PK), investor_id(FK), loan_id(FK), amount, expected_return, actual_return, status(investment_status), is_guaranteed, guarantee_tier, maturity_date

- Relations: investors, loans, guarantee_fund_investments[]

**transactions** : id(UUID PK), type(transaction_type), amount, currency, status(transaction_status), payment_gateway?, momo_reference?(unique), momo_provider?, provider_transaction_id?, provider_status?, provider_payload?(JSON), initiated_at, confirmed_at?, reconciled_at?, webhook_received_at?, signature_verified, is_reconciled, failure_reason?, created_by(FK→users)

- Relations: users

**tontine_groups** : id(UUID PK), name, leader_user_id(FK→borrowers), leader_phone, member_count, monthly_contribution, completed_cycles, status(tontine_status)

- Relations: borrowers, tontine_cycles[], tontine_members[]

**tontine_members** : id(UUID PK), group_id(FK), borrower_id(FK), joined_at

- Relations: tontine_groups, borrowers
- Unique: [group_id, borrower_id]

**tontine_cycles** : id(UUID PK), group_id(FK), cycle_number, start_date, end_date, total_collected, is_complete, beneficiary_id(FK→borrowers), members_paid, members_defaulted

- Relations: tontine_groups, borrowers
- Unique: [group_id, cycle_number]

**escrow_wallet** : id(UUID PK), total_balance, investor_funds, pending_disbursements, locked_for_guarantee, platform_fees, third_party_manager, last_audit_date?

**platform_wallet** : id(UUID PK), commission_balance, operating_funds, last_withdrawal_date?

**guarantee_fund** : id(UUID PK), total_capital, active_portfolio_value, coverage_ratio, min_threshold, target_threshold, suspension_active, last_reconstitution_date?

- Relations: guarantee_fund_investments[]

**guarantee_fund_investments** : id(UUID PK), fund_id(FK), investment_id(FK), covered_amount, activated_at?, is_activated

- Relations: guarantee_fund, investments
- Unique: [fund_id, investment_id]

**scoring_engine** : id(UUID PK), momo_weight(0.40), tontine_weight(0.35), imf_weight(0.25), warning_signal_days(45)

**borrower_scores** : id(UUID PK), borrower_id(FK), momo_score, tontine_score, imf_score, hybrid_score, computed_at

- Relations: borrowers

**admins** : id(UUID PK/FK→users), role(admin_role), permissions[]

**agents** : id(UUID PK/FK→users), zone, agency_code(unique), commission_rate, clients_assisted

**imf_staff** : id(UUID PK/FK→users), imf_name, license_number(unique), bceao_agreement_ref

- Relations: loans[]

**auto_invest_rules** : id(UUID PK), investor_id(FK unique), is_active, max_amount, max_duration, min_hybrid_score, created_at

**retail_investors** : id(UUID PK/FK→investors), max_investment_cap, preferred_sectors[]

**institutional_investors** : id(UUID PK/FK→investors), organization_name, regulatory_license, max_exposure_ratio

## 6. Authentification

Email+password + Google OAuth2. OTP 5 chiffres bcrypt (5 min). JWT: access 7j, refresh 30j (hashé bcrypt). Refresh: compare token brut vs hash BD. Logout: refresh_token=null. Rôles: admins→imf_staff→agents→investors→borrowers.

## 7. Fonctionnalités Métier

- **Scoring**: hybridScore = 0.40×momo + 0.35×tontine + 0.25×imf. imfScore = 100 - defaults×25.
- **KYC**: 3 sessions (identité→finances→soumission) + validation IMF.
- **Investissement**: prêt FUNDING → investir → remboursements distribués proportionnellement.
- **Auto-Invest**: règle configurable, scan prêts FUNDING éligibles.
- **Tontine**: groupes→membres→cycles, score tontine impacte hybrid_score.
- **Transactions**: Fedapay+KKiaPay, router par momo_provider, webhooks, réconciliation, détection PHANTOM H+24.
- **Garantie**: fonds mutuel, activation auto si prêt >30j retard, suspension si ratio < seuil.

## 8. Sécurité

Helmet, Throttler (100req/60s, 5-10/min auth), JWT 2 secrets, RolesGuard, Zod validation, PrismaExceptionFilter, CORS whitelist, bcrypt 10 rounds.

## 9. Variables d'Environnement

DATABASE*URL, JWT_SECRET, JWT_REFRESH_SECRET, JWT_EXPIRES_IN(7d), JWT_REFRESH_EXPIRES_IN(30d), PORT(3000), FRONTEND_URL, CLOUDINARY*_, FEDAPAY\__, KKIAPAY*\*, REDIS_URL, IMF_SANDBOX_URL, MAIL*_, FIREBASE\__, UPLOAD_DIR, STATIC_UPLOADS_ENABLED.

## 10. État d'Implémentation

**Fonctionnel**:

- Auth complète (register, login, OTP, Google, refresh, logout)
- KYC 3 sessions + validation IMF
- CRUD prêts + scoring hybride + validation IMF
- Investissements + Auto-Invest
- Tontine (groupes, cycles, score)
- Transactions (dépôt, retrait, webhooks Fedapay/KKiaPay)
- Admin dashboard + rapports BCEAO
- Wallets Escrow/Platform
- Fonds de garantie (activation auto/manuelle)
- Profils IMF Staff, Agents
- Swagger complet, tests unitaires (26 tests, 5 suites)

**Partiellement implémenté**:

- IMF Sandbox : fallback local si IMF_SANDBOX_URL non définie
- Notifications push : service prêt mais intégration Flutter à vérifier
- RetailInvestor/InstitutionalInvestor : modèles créés mais pas de logique métier dédiée
- Rapports PDF : pdfkit installé mais pas de endpoint de génération

**Non implémenté**:

- Paiement par carte bancaire
- Blacklist JWT
- E2E tests
- CI/CD
- Internationalisation (i18n)
- Tableau de bord temps réel (WebSockets)

## 11. Données de Test

Le seed Prisma (`prisma/seed.ts`) crée :

- Admin (SUPER_ADMIN)
- IMF Staff
- Agent de proximité
- Investisseur (retail, BALANCED)
- Emprunteur avec KYC VALIDATED
- ScoringEngine (poids par défaut)
- EscrowWallet + PlatformWallet + GuaranteeFund

Scénarios de démo : inscription → KYC → demande prêt → validation IMF → investissement → remboursement.
