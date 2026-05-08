# Module Auth

## Nom du Module & Responsabilité

Le module `Auth` gère l’inscription, la vérification OTP, la connexion JWT, le refresh token, la déconnexion, le profil courant, la modification de profil et la récupération/changement de mot de passe.

Base route : `/api/v1/auth`

## Dictionnaire des Données

### RegisterRequest

| Champ | Type Dart | Nullable | Contraintes frontend |
|---|---:|---:|---|
| firstName | String | Non | min 2 caractères |
| lastName | String | Non | min 2 caractères |
| phone | String | Non | regex `^\\+229\\d{8,10}$`, ex: `+22991000000` | 
| password | String | Non | min 8 caractères, 1 majuscule, 1 chiffre |
| city | String | Oui | optionnel |
| district | String | Oui | optionnel |

### LoginRequest

| Champ | Type Dart | Nullable | Contraintes frontend |
|---|---:|---:|---|
| phone | String | Non | format `+229XXXXXXXX` |
| password | String | Non | min 6 caractères |

### VerifyPhoneRequest

| Champ | Type Dart | Nullable | Contraintes |
|---|---:|---:|---|
| phone | String | Non | format `+229XXXXXXXX` |
| code | String | Non | exactement 5 chiffres numériques |

### ResetPasswordRequest

| Champ | Type Dart | Nullable | Contraintes |
|---|---:|---:|---|
| phone | String | Oui | fournir phone OU email |
| email | String | Oui | fournir phone OU email |
| code | String | Non | 5 chiffres |
| newPassword | String | Non | min 8, 1 majuscule, 1 chiffre |
| confirmPassword | String | Non | identique à `newPassword` |

### AuthUser

| Champ | Type Dart | Nullable |
|---|---:|---:|
| id | String | Non |
| firstName | String | Non |
| lastName | String | Non |
| phone | String | Non |
| email | String | Oui |
| city | String | Oui |
| district | String | Oui |
| avatar | String | Oui |
| status | UserStatus | Non |
| kyc_status | KycStatus | Non |
| isPhoneVerified | bool | Non |
| isEmailVerified | bool | Non |

## Endpoints & Payloads

| Méthode | Route | Auth JWT | Request Body | Success Response |
|---|---|---:|---|---|
| POST | `/auth/register` | Non | `RegisterRequest` | `{ success, data: { message }, message }` |
| POST | `/auth/verify-phone` | Non | `{ phone, code }` | `{ success, data: AuthTokens, message }` |
| POST | `/auth/verify-email` | Non | `{ email, code }` | `{ success, data: AuthTokens, message }` |
| POST | `/auth/resend-otp` | Non | DTO resend OTP | `{ success, data: { message }, message }` |
| POST | `/auth/forgot-password` | Non | `{ phone? ou email? }` | réponse générique |
| POST | `/auth/reset-password` | Non | `ResetPasswordRequest` | `{ success, data: { message }, message }` |
| POST | `/auth/login` | Non | `LoginRequest` | `{ success, data: AuthTokens, message }` |
| POST | `/auth/refresh` | Oui, refresh token | `{ refreshToken }` | nouveaux tokens |
| POST | `/auth/logout` | Oui | aucun | `{ success, data: null, message }` |
| GET | `/auth/me` | Oui | aucun | `AuthUser` |
| PATCH | `/auth/me` | Oui | `{ firstName?, lastName?, city?, district? }` | `AuthUser` |
| PATCH | `/auth/change-password` | Oui | change password DTO | `{ success, data: null, message }` |
| GET | `/auth/google` | Non | aucun | redirection Google |
| GET | `/auth/google/callback` | Non | callback OAuth | tokens ou vérification requise |

## Business & Logic Flow

### Inscription

1. Écran inscription.
2. Saisie identité, téléphone, mot de passe.
3. Appel `POST /auth/register`.
4. Si succès, redirection écran OTP.
5. Saisie code 5 chiffres.
6. Appel `POST /auth/verify-phone`.
7. Stocker tokens puis charger `/auth/me`.
8. Rediriger vers onboarding KYC ou home selon `kyc_status`.

### Connexion

1. Écran login.
2. Appel `POST /auth/login`.
3. Si succès, stocker tokens.
4. Rediriger selon statut utilisateur.

## Réactions UI

- `201 register` : ouvrir écran OTP.
- `200 verify-phone` : connecter automatiquement.
- `401` : afficher erreur OTP/login ou tenter refresh.
- `403` : compte bloqué/suspendu.
- `409` : numéro déjà utilisé, proposer connexion.
- `429` : désactiver bouton temporairement.

## Error Handling

| Code | Logique frontend |
|---:|---|
| 400 | afficher erreurs de formulaire |
| 401 | OTP/token/login invalide |
| 403 | accès refusé ou compte bloqué |
| 409 | numéro déjà utilisé |
| 429 | cooldown avant nouvelle tentative |

## Cross-Module Sync

Auth fournit le JWT à tous les autres modules. `/auth/me` alimente le store utilisateur global Flutter. Le statut KYC contrôle l’accès à Loans.
