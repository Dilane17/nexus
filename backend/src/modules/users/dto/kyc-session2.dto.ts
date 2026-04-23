import { z } from 'zod/v4';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export const INCOME_SOURCES = [
  'SALARIE',
  'INDEPENDANT',
  'COMMERCE',
  'AGRICULTURE',
  'TRANSFERT',
  'AUTRE',
] as const;
export type IncomeSource = (typeof INCOME_SOURCES)[number];

export const kycSession2Schema = z.object({
  monthlyIncome: z
    .number({ error: 'Le revenu mensuel doit être un nombre' })
    .positive('Le revenu mensuel doit être positif')
    .max(10_000_000, 'Montant supérieur au plafond autorisé'),
  incomeSource: z.enum(INCOME_SOURCES, {
    error: 'Source de revenus invalide',
  }),
  momoStatementUrl: z
    .string()
    .url('URL du relevé MoMo invalide')
    .optional(),
});

export type KycSession2Dto = z.infer<typeof kycSession2Schema>;

export class KycSession2DtoDoc {
  @ApiProperty({ example: 150000, description: 'Revenu mensuel en FCFA' })
  monthlyIncome!: number;

  @ApiProperty({ enum: INCOME_SOURCES, example: 'SALARIE' })
  incomeSource!: IncomeSource;

  @ApiPropertyOptional({ example: 'https://storage.nexus.bj/docs/momo-statement-123.pdf' })
  momoStatementUrl?: string;
}
