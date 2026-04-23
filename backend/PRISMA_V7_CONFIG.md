# Configuration Prisma v7 - NestJS Clean Architecture

## Variables d'environnement (.env)

```bash
# Base de données PostgreSQL
DATABASE_URL="postgresql://user:password@localhost:5432/nexus_db?schema=public"

# Environnement d'exécution
NODE_ENV=development  # ou: test, production

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRATION=3600

# Swagger
SWAGGER_ENABLE=true
SWAGGER_PATH=api
```

## Fichiers clés

### `prisma.config.ts`

- ✅ Type-safe avec `@prisma/config`
- ✅ Charge `.env` automatiquement
- ✅ Compatible Prisma v7

### `prisma/schema.prisma`

- ✅ `datasource db` sans URL (utilise prisma.config.ts)
- ✅ Générateur client v7
- ✅ Énums et relations typées

### `src/shared/prisma/prisma.service.ts`

- ✅ Constructeur avec datasources explicites
- ✅ Logging configurable
- ✅ Gestion du cycle de vie (OnModuleInit/OnModuleDestroy)

## Recommandations Prisma v7

### 1. Toujours utiliser le pattern Repository

```typescript
// ✅ BON - Logique centralisée
public async createUser(data) {
  return this.userRepository.create(data);
}

// ❌ MAUVAIS - Logique dispersée
public async createUser(data) {
  return this.prisma.user.create({ data });
}
```

### 2. Utiliser les types générés

```typescript
import { User, Prisma } from '@prisma/client';

// ✅ Type-safe
async findById(id: string): Promise<User | null> {
  return this.prisma.user.findUnique({ where: { id } });
}

// Utiliser Prisma.UserCreateInput pour les DTOs
export class CreateUserDto implements Prisma.UserCreateInput {
  full_name: string;
  phone: string;
}
```

### 3. Gestion des erreurs Prisma

```typescript
try {
  return await this.prisma.user.create({ data });
} catch (error) {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === 'P2002') {
      // Violation d'unicité
      throw new ConflictException('Email already exists');
    }
    if (error.code === 'P2025') {
      // Record not found
      throw new NotFoundException('User not found');
    }
  }
  throw new InternalServerErrorException();
}
```

## Migration depuis Prisma v6

### Ce qui a changé en v7

| Aspect        | v6                   | v7                        |
| ------------- | -------------------- | ------------------------- |
| URL du client | Optionnelle          | **Obligatoire** (P1012)   |
| Configuration | intraSchemaPrisma    | `@prisma/config`          |
| Moteur        | `classic` par défaut | Nouveau moteur par défaut |
| Client lazy   | Non supporté         | **Supporté**              |

### Checklist de migration

- [x] Mettre à jour `prisma.config.ts` avec `defineConfig`
- [x] Ajouter `datasources.db.url` au PrismaClient
- [x] Mettre à jour version dans `package.json` (^7.7.0)
- [x] Générrer les types: `npm run prisma:generate`
- [ ] Tester les repositories
- [ ] Vérifier les migrations

## Scripts utiles

```bash
# Générer types
npm run prisma:generate

# Créer une migration
npm run prisma:migrate:dev --name init

# Déployer en production
npm run prisma:migrate:deploy

# Visualiser l'état de la DB
npm run prisma:studio

# Tests
npm test -- user.repository
```

---

**Documentation créée pour Prisma v7.7.0 - NestJS 11.0+**
