import { z } from 'zod/v4';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export const autoInvestRuleSchema = z.object({
  is_active: z.boolean({ error: 'is_active doit être un booléen' }),
  max_amount: z
    .number({ error: 'Le montant maximum doit être un nombre' })
    .positive()
    .int()
    .max(500_000, 'Montant maximum BCEAO : 500 000 FCFA'),
  max_duration: z
    .union([z.literal(3), z.literal(6), z.literal(9), z.literal(12)], {
      error: 'Durée invalide — valeurs : 3, 6, 9 ou 12 mois',
    }),
  min_hybrid_score: z
    .number()
    .min(0)
    .max(100, 'Le score doit être entre 0 et 100')
    .optional()
    .default(0),
});

export type AutoInvestRuleDto = z.infer<typeof autoInvestRuleSchema>;

export class AutoInvestRuleDtoDoc {
  @ApiProperty({ example: true, description: 'Activer ou désactiver l\'Auto-Invest' })
  is_active!: boolean;

  @ApiProperty({ example: 100000, description: 'Montant maximum par investissement automatique (FCFA)' })
  max_amount!: number;

  @ApiProperty({ enum: [3, 6, 9, 12], example: 6, description: 'Durée de prêt maximale acceptée (mois)' })
  max_duration!: 3 | 6 | 9 | 12;

  @ApiPropertyOptional({ example: 40, description: 'Score hybride minimum de l\'emprunteur (0–100, défaut 0)' })
  min_hybrid_score?: number;
}

export interface AutoInvestRuleResponse {
  id: string;
  investorId: string;
  isActive: boolean;
  maxAmount: import('@generated/prisma').Prisma.Decimal;
  maxDuration: number;
  minHybridScore: import('@generated/prisma').Prisma.Decimal;
  createdAt: Date;
}

export interface AutoInvestRunResult {
  loansScanned: number;
  investmentsCreated: number;
  totalInvested: number;
  skipped: { loanId: string; reason: string }[];
}
