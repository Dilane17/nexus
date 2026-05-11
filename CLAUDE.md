# Nexus — Monorepo P2P Lending Bénin

## Contexte
Plateforme de prêt entre particuliers adaptée au marché béninois (zone UEMOA).
Modèle IMF-Powered avec Mobile Money et Tontine Bridge.

## Structure du monorepo

```
nexus/
├── backend/          # NestJS API (voir backend/CLAUDE.md pour le détail)
├── frontend/nexus/   # Flutter mobile (architecture clean par features)
├── database/         # Ressources PostgreSQL
└── docs/             # Documentation projet
```

## Stack

| Couche | Technologie |
|--------|-------------|
| Backend API | NestJS + TypeScript strict |
| ORM | Prisma v7 |
| Base de données | PostgreSQL (nexus_db, user: nexus_user) |
| Validation | Zod (JAMAIS class-validator) |
| Auth | JWT + refresh token (Passport) |
| Mobile | Flutter / Dart (architecture clean) |
| Docs API | Swagger sur /api/docs |

## Commandes racine

```bash
npm run backend:start     # Démarre le backend en dev
npm run backend:build     # Build de production
npm run backend:test      # Tests backend
npm run backend:prisma    # Génère le client Prisma
```

## Commandes backend (depuis backend/)

```bash
npm run start:dev         # Dev avec hot-reload
npm run build             # Compilation TypeScript
npm run test              # Tests unitaires
npm run test:e2e          # Tests end-to-end
npm run prisma:generate   # Génère le client Prisma
npm run prisma:migrate    # Applique les migrations
npm run prisma:studio     # Interface visuelle DB
```

## Commandes Flutter (depuis frontend/nexus/)

```bash
flutter run               # Lance l'app
flutter test              # Tests
flutter analyze           # Analyse statique
flutter build apk         # Build Android
```

## Modules backend

- `auth` — JWT, refresh token, Google OAuth, Passport strategies
- `users` — Profils, KYC
- `loans` — Demandes de prêts, remboursements
- `investments` — Investissements P2P
- `tontine` — Tontine Bridge (épargne collective)
- `transactions` — Historique des transactions
- `files` — Upload et gestion de fichiers
- `admin` — Administration
- `shared/` — Services partagés (PrismaModule @Global)

## Features Flutter

`auth` | `home` | `investments` | `kyc` | `loans` | `profile` | `shell` | `tontine` | `wallet` | `files`

Architecture : `lib/features/<feature>/data/` + `domain/` + `presentation/`

## Règles absolues

- JAMAIS de `any` en TypeScript
- JAMAIS de `dynamic` en Dart sans justification
- TOUJOURS Zod pour la validation métier côté backend
- TOUJOURS async/await (jamais .then())
- TOUJOURS typer les retours de fonctions
- PrismaModule est @Global() — ne pas l'importer dans chaque module
- Format de réponse API uniforme : `{ success, data, message, meta? }`
- Préfixe global API : /api/v1

## Contexte rapide avec Repomix

Pour donner tout le contexte à Claude en une fois :

```bash
npx repomix
```

Puis joins `repomix-output.xml` à ta conversation.
