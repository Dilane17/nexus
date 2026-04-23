# Nexus — P2P Lending Bénin

## Contexte du projet
Plateforme de prêt entre particuliers (P2P Lending) adaptée au marché béninois
et à la zone UEMOA. Modèle IMF-Powered avec intégration Mobile Money et Tontine Bridge.

## Stack technique
- Framework : NestJS (dernière version)
- ORM : Prisma v7
- Base de données : PostgreSQL — nexus_db (utilisateur : nexus_user)
- Validation : Zod (pas class-validator pour la logique métier)
- Auth : JWT + refresh token (passport-jwt)
- Documentation : Swagger (@nestjs/swagger)
- Language : TypeScript strict

## Architecture
- Structure modulaire par domaine dans src/modules/
- Shared services dans src/shared/
- PrismaModule est @Global() — pas besoin de l'importer dans chaque module
- Préfixe global API : /api/v1
- Swagger disponible sur : /api/docs

## Règles de code strictes
- TOUJOURS utiliser Zod pour la validation métier
- JAMAIS de class-validator pour les règles métier complexes
- JAMAIS de any en TypeScript
- TOUJOURS typer les retours de fonctions
- TOUJOURS utiliser async/await, jamais .then()
- TOUJOURS gérer les erreurs avec try/catch
- Les réponses API suivent ce format :
  { success: boolean, data: T, message: string }

## Conventions de nommage
- Fichiers : kebab-case (create-loan.dto.ts)
- Classes : PascalCase (LoanService)
- Variables/fonctions : camelCase (createLoan)
- Constantes : UPPER_SNAKE_CASE (MAX_LOAN_AMOUNT)
- Tables Prisma : @@map("snake_case")

## Règles métier BCEAO critiques
- Taux d'intérêt maximum : 18% (0.18)
- Montant prêt : entre 25 000 et 500 000 FCFA
- Durée prêt : 3, 6, 9 ou 12 mois uniquement
- Fonds de garantie : 5% du portefeuille (suspension si < 3%)
- Piste d'audit : conservation 5 ans minimum

## Modules à implémenter (dans cet ordre)
1. shared/prisma   ✅ FAIT
2. auth            → JWT login + refresh token + logout
3. users           → CRUD + KYC 3 sessions
4. loans           → Prêts + scoring hybride + sandbox IMF
5. investments     → Portefeuille + Auto-Invest
6. tontine         → Tontine Bridge + Score Tontine
7. transactions    → Mouvements fonds + réconciliation H+24
8. admin           → Dashboard NPL + rapports BCEAO

## Données de test disponibles en DB
- 4 investisseurs (3 retail + 1 institutionnel BOAD)
- 6 emprunteurs (profils variés dont 1 OVERDUE)
- 6 prêts (REPAID, ACTIVE x3, FUNDING, OVERDUE)
- 2 groupes tontine avec 3 cycles complétés
- 10 transactions (dont 1 PHANTOM_DETECTED)

## Variables d'environnement
DATABASE_URL, JWT_SECRET, JWT_EXPIRES_IN, JWT_REFRESH_SECRET,
JWT_REFRESH_EXPIRES_IN, PORT, NODE_ENV,
FEDAPAY_SECRET_KEY, KKIAPAY_SECRET_KEY, IMF_SANDBOX_URL

## Commandes utiles
- npm run start:dev  → Démarrage développement
- npx prisma studio  → Interface visuelle BD
- npx prisma generate → Régénérer le client Prisma
