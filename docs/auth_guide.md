# 🔐 Guide — Module Auth (NestJS + JWT + Prisma v7)
> Feuille de route complète pour implémenter l'authentification de Nexus P2P Lending

---

## 📋 Vue d'ensemble

Le module Auth gère :
- **Login** → vérifie les credentials, retourne un JWT + refresh token
- **Refresh** → génère un nouveau JWT à partir du refresh token
- **Logout** → invalide le refresh token en base
- **Me** → retourne le profil de l'utilisateur connecté
- **Guards** → protège les routes qui nécessitent une authentification

---

## 📁 Structure cible du module

```
src/modules/auth/
├── dto/
│   ├── login.dto.ts           → Validation Zod du login
│   └── auth-response.dto.ts   → Type de réponse JWT
├── strategies/
│   ├── jwt.strategy.ts        → Stratégie Passport JWT
│   └── refresh.strategy.ts    → Stratégie Passport Refresh Token
├── guards/
│   └── jwt-auth.guard.ts      → Guard pour protéger les routes
├── auth.controller.ts         → Routes HTTP
├── auth.service.ts            → Logique métier
└── auth.module.ts             → Déclaration du module
```

---

## 🗂️ Fichiers à créer dans l'ordre

### Ordre strict à respecter :
```
1. dto/login.dto.ts
2. dto/auth-response.dto.ts
3. strategies/jwt.strategy.ts
4. strategies/refresh.strategy.ts
5. guards/jwt-auth.guard.ts
6. auth.service.ts
7. auth.controller.ts
8. auth.module.ts
9. Mise à jour app.module.ts
```

---

## 📝 Détail de chaque fichier

---

### 1. `dto/login.dto.ts`
**Rôle** : Valider les données de connexion avec Zod

```typescript
import { z } from 'zod';
import { ApiProperty } from '@nestjs/swagger';

export const LoginSchema = z.object({
  phone: z
    .string()
    .min(1, 'Numéro de téléphone requis')
    .regex(/^\+229\d{8}$/, 'Format invalide — ex: +22961000001'),
  password: z
    .string()
    .min(6, 'Mot de passe minimum 6 caractères'),
});

export type LoginDto = z.infer<typeof LoginSchema>;

// Classe pour Swagger
export class LoginDtoClass {
  @ApiProperty({ example: '+22961000001', description: 'Numéro Mobile Money' })
  phone: string;

  @ApiProperty({ example: 'motdepasse123', description: 'Mot de passe' })
  password: string;
}
```

---

### 2. `dto/auth-response.dto.ts`
**Rôle** : Typer la réponse d'authentification

```typescript
import { ApiProperty } from '@nestjs/swagger';

export class AuthResponseDto {
  @ApiProperty({ description: 'JWT access token (expire en 7j)' })
  accessToken: string;

  @ApiProperty({ description: 'Refresh token (expire en 30j)' })
  refreshToken: string;

  @ApiProperty({ description: 'Données de l utilisateur connecté' })
  user: {
    id: string;
    fullName: string;
    phone: string;
    email: string | null;
    status: string;
    kycStatus: string;
    role: string; // 'investor' | 'borrower' | 'admin' | 'agent' | 'imf_staff'
  };
}
```

---

### 3. `strategies/jwt.strategy.ts`
**Rôle** : Vérifier le JWT sur chaque requête protégée

```typescript
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '@shared/prisma/prisma.service';

export interface JwtPayload {
  sub: string;      // user id
  phone: string;
  role: string;
  iat?: number;
  exp?: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    configService: ConfigService,
    private prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.getOrThrow<string>('JWT_SECRET'),
    });
  }

  async validate(payload: JwtPayload) {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });

    if (!user || user.status === 'BLOCKED' || user.status === 'SUSPENDED') {
      throw new UnauthorizedException('Accès refusé');
    }

    return { id: user.id, phone: user.phone, role: payload.role };
  }
}
```

---

### 4. `strategies/refresh.strategy.ts`
**Rôle** : Valider le refresh token pour renouveler le JWT

```typescript
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';

@Injectable()
export class RefreshStrategy extends PassportStrategy(Strategy, 'jwt-refresh') {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.getOrThrow<string>('JWT_REFRESH_SECRET'),
      passReqToCallback: true,
    });
  }

  async validate(req: Request, payload: { sub: string; phone: string; role: string }) {
    const refreshToken = req.headers.authorization?.split(' ')[1];
    if (!refreshToken) throw new UnauthorizedException('Refresh token manquant');
    return { ...payload, refreshToken };
  }
}
```

---

### 5. `guards/jwt-auth.guard.ts`
**Rôle** : Décorateur à mettre sur les routes protégées

```typescript
import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}

@Injectable()
export class RefreshAuthGuard extends AuthGuard('jwt-refresh') {}
```

---

### 6. `auth.service.ts`
**Rôle** : Toute la logique métier Auth

```typescript
// Méthodes à implémenter :

async login(dto: LoginDto): Promise<AuthResponseDto>
// 1. Trouver l'user par phone
// 2. Vérifier le mot de passe avec bcrypt.compare()
// 3. Vérifier que status = 'ACTIVE' et kycStatus = 'VALIDATED'
// 4. Déterminer le rôle (investor / borrower / admin / agent / imf_staff)
// 5. Générer accessToken + refreshToken avec JwtService
// 6. Sauvegarder le refreshToken hashé en base (champ à ajouter)
// 7. Mettre à jour lastLogin
// 8. Retourner AuthResponseDto

async refresh(userId: string, refreshToken: string): Promise<{ accessToken: string }>
// 1. Trouver l'user par id
// 2. Vérifier que le refreshToken correspond à celui en base
// 3. Générer un nouveau accessToken
// 4. Retourner { accessToken }

async logout(userId: string): Promise<void>
// 1. Supprimer le refreshToken en base
// 2. Retourner void

async getProfile(userId: string): Promise<UserProfile>
// 1. Trouver l'user avec ses relations (investor/borrower/admin...)
// 2. Retourner le profil complet

private determineRole(user): string
// Vérifier quelle table fille existe pour cet user
// investor → 'investor'
// borrower → 'borrower'
// admin → 'admin'
// etc.

private async generateTokens(userId, phone, role): Promise<Tokens>
// Générer accessToken et refreshToken avec JwtService.sign()
```

---

### 7. `auth.controller.ts`
**Rôle** : Exposer les routes HTTP

```
POST /api/v1/auth/login     → Login (public)
POST /api/v1/auth/refresh   → Refresh token (RefreshAuthGuard)
POST /api/v1/auth/logout    → Logout (JwtAuthGuard)
GET  /api/v1/auth/me        → Profil connecté (JwtAuthGuard)
```

---

### 8. `auth.module.ts`
**Rôle** : Déclarer et assembler tous les composants

```typescript
// Imports nécessaires :
// - JwtModule.registerAsync() avec JWT_SECRET depuis ConfigService
// - PassportModule
// - Providers : AuthService, JwtStrategy, RefreshStrategy
// - Exports : AuthService, JwtAuthGuard (pour les autres modules)
```

---

## ⚠️ Modification de schema.prisma requise

Avant de coder, ajoute le champ `refreshToken` et `password` sur le modèle `User` :

```prisma
model User {
  // ... champs existants ...
  password      String?   // mot de passe hashé bcrypt
  refreshToken  String?   // refresh token hashé (null si déconnecté)
}
```

Puis :
```bash
npx prisma migrate dev --name add_auth_fields
npx prisma generate
```

---

## 🧪 Test rapide après implémentation

```bash
# 1. Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone": "+22961000001", "password": "Admin123"}'

# 2. Utiliser le token retourné
curl http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer TON_JWT_TOKEN"
```

Ou utilise directement **Swagger** sur `http://localhost:3000/api/docs`
→ Clique sur **Authorize** → colle le token JWT → teste les routes protégées

---

## 📦 Dépendances déjà installées
```
✅ @nestjs/jwt
✅ @nestjs/passport
✅ passport
✅ passport-jwt
✅ bcrypt
✅ @types/bcrypt
✅ @types/passport-jwt
```

---

## 💡 Prompt Claude Code à utiliser

```
Implémente le module Auth complet pour Nexus P2P Lending.

Suis exactement la structure définie dans auth_guide.md :
- LoginDto avec validation Zod (phone format +229XXXXXXXX)
- JwtStrategy + RefreshStrategy (passport-jwt)
- JwtAuthGuard + RefreshAuthGuard
- AuthService avec login / refresh / logout / getProfile
- AuthController avec POST /login, POST /refresh, POST /logout, GET /me
- AuthModule avec JwtModule.registerAsync()

Contraintes :
- PrismaClient importé depuis @generated/prisma/client
- PrismaService injecté via le module global
- Réponses API au format { success: boolean, data: T, message: string }
- Swagger @ApiTags('Auth') + @ApiBearerAuth('JWT-auth') sur les routes protégées
- TypeScript strict — jamais de any
- bcrypt pour hasher les mots de passe
- Ajouter password et refreshToken dans schema.prisma + migration
```

---

## ✅ Checklist de validation

Avant de passer au module Users, vérifie :

- [ ] `npx prisma migrate dev` exécuté sans erreur
- [ ] `npm run start:dev` démarre sans erreur
- [ ] Login retourne un JWT valide sur Swagger
- [ ] Route `/me` retourne le profil avec le JWT
- [ ] Refresh retourne un nouveau accessToken
- [ ] Logout invalide le refresh token
- [ ] Routes non protégées accessibles sans JWT
- [ ] Routes protégées retournent 401 sans JWT

---

*Bonne implémentation demain ! 🚀*
