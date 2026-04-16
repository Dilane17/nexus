import { config } from 'dotenv';
import { defineConfig } from 'prisma/config';

config(); // charge .env dans process.env avant que Prisma lise la config

export default defineConfig({
  earlyAccess: true,
  schema: 'prisma/schema.prisma',
  datasource: {
    url: process.env['DATABASE_URL'],
  },
});
