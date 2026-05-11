# Rapport de stabilite des contrats API

Date: 2026-05-08

## Convention appliquee

La convention publique est maintenant `camelCase` pour les payloads frontend/backend et pour les reponses consommees par Flutter. Les noms de colonnes Prisma restent internes au backend.

## Corrections realisees

- Ajout de `ApiPage<T>` cote Flutter pour parser les reponses paginees `{ items, total, page, limit, totalPages }`.
- Migration des models Flutter vers les DTO backend camelCase:
  - `AuthUser`
  - `Loan`
  - `Investment`
  - `InvestmentSummary`
  - `AutoInvestRule`
  - `Transaction`
  - `KycStatusResponse`
  - `TontineScore`
  - `TontineGroup`
  - `TontineCycle`
- Migration des payloads Flutter vers camelCase:
  - creation de pret: `durationMonths`
  - remboursement: `amount`, `momoReference`, `momoProvider`
  - investissement: `loanId`
  - auto-invest: `isActive`, `maxAmount`, `maxDuration`, `minHybridScore`
  - depot/retrait: `momoProvider`, `momoPhone`, `momoNumber`
  - tontine: `monthlyContribution`
- Correction du parsing du depot wallet: lecture de `data.transaction`.
- Suppression de l'appel frontend a `GET /tontine/groups/:id/cycles`; les cycles viennent de `GET /tontine/groups/:id`.
- Correction du statut KYC soumis: si `kycSubmittedAt` existe, le frontend affiche l'etape pending.
- Migration des DTO d'entree backend encore en snake_case vers camelCase.
- Correction des reponses auth/users pour exposer `kycStatus`.
- Correction des specs backend pour les nouveaux payloads camelCase.
- Nettoyage des warnings Flutter bloquants pour obtenir une analyse propre.

## Routes sensibles

- `GET /investments/auto-invest` est declare avant `GET /investments/:id`, ce qui evite la collision de routing.
- `PUT /investments/auto-invest` et `POST /investments/auto-invest/run` ne collisionnent pas avec `GET /:id` car les methodes HTTP different.

## Validation par flow

- Auth: `register`, `verifyEmail`, `login`, `refresh`, `me`, `profile update` alignes sur `kycStatus`.
- KYC: sessions 1/2/3 en camelCase; status parse sur `kycStatus`; pending detecte via `kycSubmittedAt`.
- Loans: liste paginee via `ApiPage`; detail camelCase; creation et remboursement alignes.
- Investments: portefeuille pagine via `ApiPage`; detail camelCase; creation et auto-invest alignes.
- Wallet: historique pagine via `ApiPage`; depot parse `transaction`; retrait camelCase.
- Tontine: score, groupes, detail et cycles imbriques alignes; creation groupe en camelCase.
- Profile: `/auth/me`, `/auth/change-password`, `/auth/logout` restent alignes.

## Verifications executees

- Backend build: `npm run build` OK.
- Backend tests: `npm test -- --runInBand` OK, 5 suites / 26 tests.
- Frontend analyse: `flutter analyze` OK, aucun issue.
- Balayage grep: plus de serializers Flutter ni d'acces `dto.*` backend publics en snake_case obsoletes.

## Points restants non bloquants

- `InvestmentSummary.totalExpectedReturn` n'existe pas explicitement dans la reponse backend actuelle; le frontend le laisse a `0` tant qu'un champ backend dedie n'est pas expose.
- `TontineScore.defaultedCycles` et `totalContributed` n'existent pas dans la reponse backend actuelle; le model conserve des getters de compatibilite a `0` pour ne pas casser l'UI existante.
