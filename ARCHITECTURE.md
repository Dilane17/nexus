# 🏗️ Architecture du Monorepo Nexus

## 📁 Structure des dossiers

```
nexus/                          # Racine du monorepo
├── package.json                # Scripts helper (ne contient PAS de dépendances npm)
├── package-lock.json           # À IGNORER (utilisé par les scripts racine seulement)
│
├── backend/                     # 🔧 Application NestJS
│   ├── package.json             # Dépendances spécifiques du backend
│   ├── package-lock.json        # Lockfile du backend UNIQUEMENT
│   ├── node_modules/            # Dépendances du backend (LOCAL)
│   ├── src/                     # Code source
│   │   ├── app.module.ts
│   │   ├── main.ts
│   │   ├── modules/
│   │   │   ├── auth/
│   │   │   ├── users/
│   │   │   ├── loans/
│   │   │   ├── investments/
│   │   │   ├── tontine/
│   │   │   └── ...
│   │   └── shared/
│   ├── prisma/                  # ORM database
│   │   ├── schema.prisma
│   │   ├── migrations/
│   │   └── seed.ts
│   ├── dist/                    # Output compilé (après `npm run build`)
│   ├── .env                     # Variables d'environnement
│   └── tsconfig.json
│
├── frontend/                    # 📱 À CRÉER - Application Mobile (Expo/React Native)
│   ├── package.json             # Dépendances spécifiques du frontend
│   ├── node_modules/            # Dépendances du frontend (LOCAL)
│   ├── app/                     # Expo Router
│   └── src/
│
├── database/                    # 🗄️ Ressources DB
│   └── nexus_db_dump.sql
│
├── docs/                        # 📚 Documentation
│   ├── api/
│   ├── auth_guide.md
│   └── ...
│
└── README.md
```

---

## 🚀 Où je travaille ?

### **🔧 Backend (MAINTENANT)**

```bash
cd /home/dylankode/Soutenance/nexus/backend

# Tous les fichiers à éditer sont dans backend/src/
# Toutes les dépendances npm sont dans backend/node_modules/

npm run start:dev          # Lance le serveur en mode développement
npm run build             # Compile le TypeScript → dist/
npm run test              # Lance les tests
npm run prisma:migrate:dev  # Gère les migrations DB
```

### **📱 Frontend (À CRÉER)**

```bash
cd /home/dylankode/Soutenance/nexus/frontend

npm run start              # Lance Expo
npm run android            # Build Android
```

### **🌍 Racine (Scripts helper)**

```bash
cd /home/dylankode/Soutenance/nexus

npm run backend:start      # Raccourci pour lancer le backend
npm run backend:install    # Raccourci pour installer les deps du backend
```

---

## 📦 Structure des dépendances

| Localisation              | Contient ?                | Raison               |
| ------------------------- | ------------------------- | -------------------- |
| `/nexus/node_modules/`    | ❌ RIEN                   | Pas utilisé          |
| `/backend/node_modules/`  | ✅ **Dépendances NestJS** | Backend indépendant  |
| `/frontend/node_modules/` | ✅ **Dépendances Expo**   | Frontend indépendant |

---

## 🎯 Commandes principales

```bash
# Depuis le dossier backend
cd backend && npm run start:dev        # Mode développement
cd backend && npm run build            # Compiler pour production

# Depuis la racine (raccourcis)
npm run backend:start                  # Même that: cd backend && npm run start:dev
npm run backend:build
npm run backend:lint

# Prisma
cd backend && npm run prisma:migrate:dev
cd backend && npm run prisma:studio
```

---

## ✅ Ce qui est propre maintenant

- ✅ **1 dossier `backend/` (732 MB)** → Source + Dépendances
- ✅ **Pas de duplication** de `node_modules`
- ✅ **Package.json racine** → Scripts helper uniquement
- ✅ **Frontend prêt à créer** dans `/frontend/`
- ✅ **Git simple** → 1 seul repo, pas d'imbrication

---

## 🔄 Workflow

1. **Développement backend** :

   ```bash
   cd backend
   npm run start:dev
   ```

2. **Développement frontend** (une fois créé) :

   ```bash
   cd frontend
   npm run start
   ```

3. **Push au repo** :
   ```bash
   cd /nexus    # À la racine
   git add .
   git commit -m "..."
   git push
   ```

---

## 📌 Résumé pour toi

- 🎯 **Travaille dans `/backend/` pour le backend**
- 📱 **Crée `/frontend/` pour le mobile**
- 🌍 **Les scripts racine sont des raccourcis**
- 📦 **Chaque workspace a ses dépendances indépendantes**
- ✨ **C'est un monorepo simple et propre 🎉**
