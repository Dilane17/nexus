import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // ── Validation globale ──────────────────────────────
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // ── Préfixe global API ──────────────────────────────
  app.setGlobalPrefix('api/v1');

  // ── CORS ────────────────────────────────────────────
  app.enableCors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  // ── Swagger ─────────────────────────────────────────
  const config = new DocumentBuilder()
    .setTitle('Nexus API')
    .setDescription(
      `
      ## Plateforme P2P Lending — Bénin / UEMOA
      
      API backend du projet Nexus — application de prêt entre particuliers
      adaptée au marché béninois avec intégration Mobile Money et Tontine Bridge.
      
      ### Modules disponibles
      - **Auth** — Authentification JWT + refresh token
      - **Users** — Gestion utilisateurs + KYC progressif
      - **Loans** — Prêts + scoring hybride + validation IMF
      - **Investments** — Portefeuille investisseurs + Auto-Invest
      - **Tontine** — Tontine Bridge + Score Tontine
      - **Transactions** — Mouvements de fonds + réconciliation MoMo
      - **Admin** — Dashboard NPL + rapports BCEAO
    `,
    )
    .setVersion('1.0')
    .setContact('Équipe Nexus', '', 'admin@nexus-benin.com')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Token JWT obtenu via /api/v1/auth/login',
      },
      'JWT-auth',
    )
    .addTag('Auth', 'Authentification et gestion des tokens')
    .addTag('Users', 'Gestion des utilisateurs et KYC')
    .addTag('Loans', 'Gestion des prêts et scoring')
    .addTag('Investments', 'Portefeuille et Auto-Invest')
    .addTag('Tontine', 'Tontine Bridge et Score Tontine')
    .addTag('Transactions', 'Mouvements de fonds et réconciliation')
    .addTag('Admin', 'Dashboard et rapports BCEAO')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
      tagsSorter: 'alpha',
      operationsSorter: 'alpha',
    },
  });

  // ── Lancement ────────────────────────────────────────
  const port = process.env.PORT || 3000;
  await app.listen(port);

  console.log(`🚀 Nexus API démarrée sur : http://localhost:${port}/api/v1`);
  console.log(`📚 Swagger disponible sur : http://localhost:${port}/api/docs`);
}

void bootstrap();
