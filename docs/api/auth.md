# 🔐 Module Auth — Documentation Technique
> Nexus P2P Lending — Bénin / UEMOA

---

## Vue d'ensemble

Le module Auth gère l'ensemble du cycle d'authentification de la plateforme Nexus.
Il supporte deux méthodes d'inscription : classique (téléphone + mot de passe) et
Google OAuth. Dans les deux cas, une vérification OTP est obligatoire avant
l'activation du compte.

---

## Structure des fichiers

```
src/modules/auth/
├── dto/
│   ├── login.dto.ts              → Validation Zod — connexion
│   ├── register.dto.ts           → Validation Zod — inscription
│   ├── verify-otp.dto.ts         → Validation Zod — vérification OTP
│   ├── update-profile.dto.ts     → Validation Zod — mise à jour profil
│   └── auth-response.dto.ts      → Type réponse JWT
├── strategies/
│   ├── jwt.strategy.ts           → Stratégie Passport JWT
│   ├── refresh.strategy.ts       → Stratégie Passport Refresh Token
│   └── google.strategy.ts        → Stratégie Passport Google OAuth
├── guards/
│   └── jwt-auth.guard.ts         → Guards JWT + Refresh + Google
├── auth.controller.ts            → Routes HTTP
├── auth.service.ts               → Logique métier
└── auth.module.ts                → Déclaration du module
```

---

## Routes disponibles

### Routes publiques (sans authentification)

| Méthode | Route | Description |
|---|---|---|
| POST | `/api/v1/auth/register` | Inscription classique |
| POST | `/api/v1/auth/login` | Connexion téléphone + password |
| POST | `/api/v1/auth/verify-phone` | Vérification OTP SMS |
| POST | `/api/v1/auth/verify-email` | Vérification OTP email (Google) |
| POST | `/api/v1/auth/resend-otp` | Renvoyer le code OTP |
| GET | `/api/v1/auth/google` | Redirection OAuth Google |
| GET | `/api/v1/auth/google/callback` | Callback OAuth Google |

### Routes protégées (JWT requis)

| Méthode | Route | Description |
|---|---|---|
| POST | `/api/v1/auth/refresh` | Renouveler le JWT |
| POST | `/api/v1/auth/logout` | Déconnexion |
| GET | `/api/v1/auth/me` | Profil de l'utilisateur connecté |
| PATCH | `/api/v1/auth/me` | Modifier le profil |

---

## Flows d'authentification

### Flow 1 — Inscription classique

```
Client                          Serveur                        Terminal
  │                               │                               │
  │  POST /auth/register          │                               │
  │  { firstName, lastName,       │                               │
  │    phone, password,           │                               │
  │    city, district }           │                               │
  │ ──────────────────────────── ▶│                               │
  │                               │  Vérifie phone unique         │
  │                               │  Hash password (bcrypt)       │
  │                               │  Crée user (status: PENDING)  │
  │                               │  Génère OTP 5 chiffres        │
  │                               │  Hash OTP (bcrypt)            │
  │                               │  Sauvegarde OTP + expiry      │
  │                               │  ─────────────────────────── ▶│
  │                               │                    [SMS SIM]  │
  │                               │                    Code: XXXXX│
  │  201 { message: "Code envoyé"}│                               │
  │ ◀─────────────────────────────│                               │
  │                               │                               │
  │  POST /auth/verify-phone      │                               │
  │  { phone, code: "XXXXX" }     │                               │
  │ ──────────────────────────── ▶│                               │
  │                               │  Vérifie OTP (bcrypt.compare) │
  │                               │  Vérifie expiry (< 5 min)     │
  │                               │  isPhoneVerified = true       │
  │                               │  status = ACTIVE              │
  │                               │  Génère accessToken + refresh │
  │  200 { accessToken,           │                               │
  │        refreshToken, user }   │                               │
  │ ◀─────────────────────────────│                               │
```

### Flow 2 — Google OAuth

```
Client                          Serveur                        Google
  │                               │                               │
  │  GET /auth/google             │                               │
  │ ──────────────────────────── ▶│                               │
  │                               │  Redirige vers Google ──────▶ │
  │                               │                               │
  │  (utilisateur se connecte     │                               │
  │   sur Google)                 │                               │
  │                               │ ◀─── callback + profil Google │
  │                               │  Cherche user par googleId    │
  │                               │  Si nouveau : crée user       │
  │                               │  Génère OTP 5 chiffres        │
  │                               │  Envoie OTP par email         │
  │  Redirige vers verify-email   │                               │
  │ ◀─────────────────────────────│                               │
  │                               │                               │
  │  POST /auth/verify-email      │                               │
  │  { email, code }              │                               │
  │ ──────────────────────────── ▶│                               │
  │                               │  Vérifie OTP                  │
  │                               │  isEmailVerified = true       │
  │                               │  status = ACTIVE              │
  │  200 { accessToken, ... }     │                               │
  │ ◀─────────────────────────────│                               │
```

### Flow 3 — Connexion classique

```
POST /auth/login
{ "phone": "+22991000000", "password": "Admin123!" }

Vérifications effectuées dans l'ordre :
1. User existe avec ce phone ?        → 401 si non
2. Password correct (bcrypt.compare)  → 401 si non
3. isPhoneVerified = true ?           → 401 si non (message: "Numéro non vérifié")
4. status = ACTIVE ?                  → 401 si BLOCKED ou SUSPENDED
5. Génère accessToken + refreshToken
6. Met à jour lastLogin
7. Retourne les tokens + profil
```

### Flow 4 — Mot de passe oublié

1. POST /auth/forgot-password { phone }
   → Génère OTP 5 chiffres
   → Envoie par SMS (simulation terminal)
   → Retourne { message: "Code envoyé" }

2. POST /auth/reset-password { phone, code, newPassword }
   → Vérifie OTP (même logique que verify-phone)
   → Hash le nouveau mot de passe
   → Met à jour password en base
   → Invalide le refreshToken (déconnecte toutes les sessions)
   → Retourne { message: "Mot de passe modifié" }

---

## Sécurité

### Tokens JWT

| Token | Durée | Usage |
|---|---|---|
| `accessToken` | 7 jours | Authentification des requêtes |
| `refreshToken` | 30 jours | Renouvellement du accessToken |

Le `refreshToken` est **hashé avec bcrypt** avant d'être sauvegardé en base.
Lors du refresh, il est comparé avec `bcrypt.compare()`.

### OTP

| Propriété | Valeur |
|---|---|
| Format | 5 chiffres numériques |
| Durée de validité | 5 minutes |
| Stockage | Hashé avec bcrypt en base |
| Tentatives | Invalidé après utilisation |

### Mots de passe

- Hashés avec **bcrypt** (salt rounds: 10)
- Jamais retournés dans les réponses API
- Minimum 8 caractères, 1 majuscule, 1 chiffre

---

## Format des réponses

### Succès

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiJ9...",
    "user": {
      "id": "uuid",
      "firstName": "Kofi",
      "lastName": "Mensah",
      "phone": "+22991000000",
      "email": null,
      "city": "Cotonou",
      "district": "Cadjehoun",
      "status": "ACTIVE",
      "kycStatus": "NOT_STARTED",
      "isPhoneVerified": true,
      "role": "borrower"
    }
  },
  "message": "Connexion réussie"
}
```

### Erreur

```json
{
  "success": false,
  "message": "Téléphone ou mot de passe incorrect",
  "error": "Unauthorized",
  "statusCode": 401
}
```

---

## DTOs et Validation Zod

### RegisterDto

```typescript
{
  firstName: string    // min 2 caractères
  lastName:  string    // min 2 caractères
  phone:     string    // format +229XXXXXXXX (8 chiffres après +229)
  password:  string    // min 8 chars, 1 majuscule, 1 chiffre
  city:      string?   // optionnel — ex: "Cotonou"
  district:  string?   // optionnel — ex: "Cadjehoun"
}
```

### LoginDto

```typescript
{
  phone:    string    // format +229XXXXXXXX
  password: string    // min 6 caractères
}
```

### VerifyOtpDto

```typescript
{
  phone?: string    // pour vérification SMS
  email?: string    // pour vérification email Google
  code:   string    // exactement 5 chiffres
}
```

### UpdateProfileDto (tous optionnels)

```typescript
{
  firstName?: string
  lastName?:  string
  city?:      string
  district?:  string
}
```

---

## Champs base de données (modèle User)

| Champ | Type | Description |
|---|---|---|
| `id` | UUID | Identifiant unique |
| `firstName` | String | Prénom |
| `lastName` | String | Nom de famille |
| `phone` | String UNIQUE | Numéro Mobile Money |
| `email` | String? UNIQUE | Email (optionnel) |
| `password` | String? | Mot de passe hashé bcrypt |
| `city` | String? | Ville — ex: Cotonou |
| `district` | String? | Quartier — ex: Cadjehoun |
| `googleId` | String? UNIQUE | ID Google OAuth |
| `avatar` | String? | Photo de profil Google |
| `refreshToken` | String? | Refresh token hashé |
| `otpCode` | String? | OTP hashé bcrypt |
| `otpExpiry` | DateTime? | Expiration OTP (5 min) |
| `otpType` | String? | PHONE_VERIFICATION / EMAIL_VERIFICATION |
| `isPhoneVerified` | Boolean | Numéro vérifié par OTP SMS |
| `isEmailVerified` | Boolean | Email vérifié par OTP email |
| `status` | UserStatus | PENDING / ACTIVE / SUSPENDED / BLOCKED |
| `kycStatus` | KycStatus | NOT_STARTED → VALIDATED |
| `createdAt` | DateTime | Date de création |
| `lastLogin` | DateTime? | Dernière connexion |

---

## Variables d'environnement requises

```bash
# JWT
JWT_SECRET="..."              # Clé secrète pour signer les tokens
JWT_EXPIRES_IN="7d"           # Durée du access token
JWT_REFRESH_SECRET="..."      # Clé secrète pour les refresh tokens
JWT_REFRESH_EXPIRES_IN="30d"  # Durée du refresh token

# Google OAuth
GOOGLE_CLIENT_ID="..."
GOOGLE_CLIENT_SECRET="..."
GOOGLE_CALLBACK_URL="http://localhost:3000/api/v1/auth/google/callback"

# Nodemailer SMTP Gmail
MAIL_HOST="smtp.gmail.com"
MAIL_PORT=587
MAIL_USER="ton.email@gmail.com"
MAIL_PASSWORD="xxxx xxxx xxxx xxxx"
MAIL_FROM="Nexus P2P Lending <ton.email@gmail.com>"

# OTP
OTP_EXPIRY_MINUTES=5
```

---

## Tests validés ✅

| Test | Route | Status | Résultat |
|---|---|---|---|
| Inscription | POST /register | 201 | OTP reçu dans terminal |
| Vérification OTP | POST /verify-phone | 200 | Tokens JWT retournés |
| Profil connecté | GET /me | 200 | Profil utilisateur affiché |
| Login classique | POST /login | 200 | Tokens JWT retournés |
| Route sans token | GET /me | 401 | Unauthorized ✅ |

---

## Commandes utiles

```bash
# Vérifier les users en base
psql -U nexus_user -d nexus_db -h localhost

SELECT id, "firstName", "lastName", phone, status, "isPhoneVerified"
FROM users
ORDER BY "createdAt" DESC;

# Voir un user spécifique
SELECT * FROM users WHERE phone = '+22991000000';

# Vérifier les tokens
SELECT id, phone, "refreshToken", "lastLogin"
FROM users
WHERE "refreshToken" IS NOT NULL;
```

---

*Documentation générée le 16 Avril 2025 — Module Auth v1.0*