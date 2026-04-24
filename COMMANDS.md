# 📋 Commandes de travail quotidien - Nexus

## Backend (NestJS)

### 🚀 Démarrage & Développement

```bash
cd ~/Soutenance/nexus/backend

# Mode développement (reload auto)
npm run start:dev

# Build pour production
npm run build

# Lancer la build compilée
npm run start:prod

# Mode debug
npm run start:debug
```

### 🧪 Tests & Quality

```bash
cd ~/Soutenance/nexus/backend

# Tests unitaires
npm run test

# Tests en watch mode
npm run test:watch

# Coverage
npm run test:cov

# Tests E2E
npm run test:e2e

# Lint & format
npm run lint
npm run format
```

### 🗄️ Base de données (Prisma)

```bash
cd ~/Soutenance/nexus/backend

# Générer le client Prisma
npm run prisma:generate

# Créer une migration
npm run prisma:migrate:dev

# Déployer les migrations en prod
npm run prisma:migrate:deploy

# Ouvrir Prisma Studio (GUI)
npm run prisma:studio

# Seed la DB
npm run prisma:seed
```

---

## Frontend (À créer)

### 🚀 Démarrage (futur)

```bash
cd ~/Soutenance/nexus/frontend

# Démarrage en développement
npm start

# Build Android
npm run android
# ou
expo start --android

# Build iOS
npm run ios
# ou
expo start --ios

# Build Web
npm run web
# ou
expo start --web

# Lint
npm run lint
```

---

## Commandes Racine (Shortcuts)

```bash
cd ~/Soutenance/nexus

# Backend
npm run backend:install      # npm install dans backend/
npm run backend:start        # npm run start:dev dans backend/
npm run backend:build        # npm run build dans backend/
npm run backend:test         # npm run test dans backend/
npm run backend:lint         # npm run lint dans backend/
npm run backend:prisma       # npm run prisma:generate dans backend/
```

---

## Git Workflow

```bash
cd ~/Soutenance/nexus

# Voir l'état
git status

# Ajouter tous les changements
git add .

# Commit
git commit -m "feat: description du changement"

# Pousser
git push

# Voir l'historique
git log --oneline -10
```

---

## 📂 Fichiers importants à connaître

| Fichier             | Localisation       | Rôle                                |
| ------------------- | ------------------ | ----------------------------------- |
| `package.json`      | `/backend/`        | Config npm + scripts backend        |
| `tsconfig.json`     | `/backend/`        | Config TypeScript                   |
| `schema.prisma`     | `/backend/prisma/` | Schéma de base de données           |
| `.env`              | `/backend/`        | Variables d'environnement (secrets) |
| `.env.example`      | `/backend/`        | Template d'env vars                 |
| `nest-cli.json`     | `/backend/`        | Config NestJS                       |
| `eslint.config.mjs` | `/backend/`        | Config ESLint                       |

---

## ⚙️ Setup Initial (Si besoin)

```bash
# Installer les dépendances du backend
cd ~/Soutenance/nexus/backend
npm install

# Générer le client Prisma
npm run prisma:generate

# Créer les migrations de base de données
npm run prisma:migrate:dev

# Démarrer le serveur
npm run start:dev

# Vérifier que c'est ok
curl http://localhost:3000
```

---

## 🚨 Troubleshooting

### Les imports ne resolve pas ?

```bash
# Régénérer TypeScript types
cd backend
npm run prisma:generate
```

### Erreur "port already in use" ?

```bash
# Trouver le process sur le port 3000
lsof -i :3000

# Tuer le process (remplace PID)
kill -9 <PID>
```

### Cache npm corrompu ?

```bash
cd backend
rm -rf node_modules package-lock.json
npm install
```

### Database hors sync ?

```bash
cd backend
npm run prisma:migrate:reset  # ⚠️ Supprime les données!
```

---

## 📱 Structure Frontend (À respecter quand tu la crées)

```
frontend/
├── app/              # Expo Router (navigation)
│   ├── (auth)/
│   ├── (main)/
│   └── _layout.tsx
├── src/
│   ├── components/   # Composants React Native
│   ├── screens/      # Les écrans (optionnel)
│   ├── services/     # Appels API
│   ├── store/        # State management (Zustand)
│   ├── types/        # Types TypeScript
│   └── utils/        # Utilitaires
├── assets/           # Images, fonts
└── package.json
```
