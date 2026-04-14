# Architecture Clean + Prisma v7

## 📐 Structure du projet

```
src/
├── features/                    # Modules métier (Feature-based)
│   ├── users/
│   │   ├── domain/             # Entités, cas d'usage, interfaces
│   │   ├── application/        # Use cases, DTOs
│   │   ├── infrastructure/     # Repositories, Query Handlers
│   │   │   └── repositories/
│   │   │       └── user.repository.ts
│   │   └── users.module.ts
│   ├── investments/
│   └── ...
├── shared/                     # Code partagé
│   ├── prisma/
│   │   ├── prisma.service.ts  # PrismaClient étendu
│   │   └── prisma.module.ts
│   ├── repositories/
│   │   └── base.repository.ts # Classe abstraite réutilisable
│   └── config/
└── app.module.ts
```

## 🔧 Intégration Prisma v7

### 1. **PrismaService avec datasources explicites**

```typescript
constructor() {
  super({
    datasources: {
      db: {
        url: process.env.DATABASE_URL,
      },
    },
    log: [{ emit: 'event', level: 'query' }, ...],
  });
}
```

✅ Résout l'erreur P1012 (ValidationError) de Prisma v7

### 2. **prisma.config.ts**

- Centralise la configuration datasource
- Type-safe avec `defineConfig` de `@prisma/config`
- Charge les variables `.env` via dotenv

### 3. **Pattern Repository**

- `BaseRepository<T>` abstraite pour réutilisabilité
- Chaque entité a son repository (UserRepository, InvestorRepository...)
- Gestion centralisée des erreurs Prisma

## 💾 Bonnes pratiques

### Créer un nouveau repository

```typescript
@Injectable()
export class InvestorRepository extends BaseRepository<Investor> {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  protected getSelectFields(): Prisma.InvestorSelect {
    return {
      id: true,
      wallet_balance: true,
      total_invested: true,
      // Exclure les champs sensibles
    };
  }

  async findById(id: string) {
    return this.prisma.investor.findUnique({
      where: { id },
      select: this.getSelectFields(),
    });
  }
}
```

### Éviter les pièges v7

❌ **Ne pas faire** :

```typescript
new PrismaClient(); // P1012 !
```

✅ **À faire** :

```typescript
super({
  datasources: {
    db: { url: process.env.DATABASE_URL },
  },
});
```

## 🔄 Cycle de développement

```bash
# Modifier schema.prisma
npm run prisma:generate     # Génère les types
npm run prisma:migrate dev  # Crée une migration

# Tests
npm run test

# Production
npm run build
```

## 📚 Références

- [Prisma v7 Migration Guide](https://www.prisma.io/docs/orm/upgrade-guides/upgrading-to-prisma-7)
- [Clean Architecture in NestJS](https://docs.nestjs.com/techniques/database)
- [Prisma Config](https://www.prisma.io/docs/orm/reference/prisma-schema-reference#datasource)
