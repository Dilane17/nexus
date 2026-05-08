import { NestFactory, HttpAdapterHost } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import helmet from 'helmet';
import { PrismaExceptionFilter } from '@shared/filters/prisma-exception.filter';
import { LoggerService } from './modules/logger/logger.service';
import { LoggerMiddleware } from './modules/logger/logger.middleware';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    rawBody: true,
  });

  // ── Logger global ───────────────────────────────────
  const logger = app.get(LoggerService);
  app.useLogger(logger);

  // ── Sécurité HTTP headers ────────────────────────────
  app.use(helmet());

  // ── Filtre global exceptions Prisma ──────────────────
  const { httpAdapter } = app.get(HttpAdapterHost);
  app.useGlobalFilters(new PrismaExceptionFilter());

  // ── Servir les fichiers statiques ───────────────────
  const staticUploadsEnabled =
    (process.env.STATIC_UPLOADS_ENABLED ?? 'true').toLowerCase() !== 'false';
  const uploadDir = process.env.UPLOAD_DIR ?? 'uploads';

  if (staticUploadsEnabled) {
    app.useStaticAssets(join(__dirname, '..', uploadDir), {
      prefix: '/uploads/',
    });
  }

  // ── Middleware de logging HTTP ──────────────────────
  const loggerMiddleware = new LoggerMiddleware(logger);
  app.use(loggerMiddleware.use.bind(loggerMiddleware));

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
  const configuredOrigins = (
    process.env.FRONTEND_ALLOWED_ORIGINS ??
    process.env.FRONTEND_URL ??
    'http://localhost:8081'
  )
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  const allowedOrigins = new Set(configuredOrigins);
  if ((process.env.NODE_ENV ?? 'development') !== 'production') {
    allowedOrigins.add('http://localhost:8081');
    allowedOrigins.add('http://localhost:3000');
    allowedOrigins.add('exp://localhost:8081');
  }

  app.enableCors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.has(origin) || /^exp:\/\/192\.168\.\d+\.\d+:8081$/.test(origin)) {
        callback(null, true);
        return;
      }
      callback(new Error(`Origin non autorisee par CORS: ${origin}`));
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
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
  await app.listen(port, '0.0.0.0');

  console.log(`🚀 Nexus API démarrée sur : http://localhost:${port}/api/v1`);
  console.log(`📚 Swagger disponible sur : http://localhost:${port}/api/docs`);
}

void bootstrap();
