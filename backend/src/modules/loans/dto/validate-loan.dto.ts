import { z } from 'zod/v4';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export const MAX_INTEREST_RATE = 0.18;
export const DEFAULT_INTEREST_RATE = 0.15;

export const validateLoanSchema = z
  .object({
    decision: z.enum(['APPROVED', 'REJECTED'], {
      error: 'Décision invalide — valeurs : APPROVED ou REJECTED',
    }),
    interest_rate: z
      .number()
      .min(0.01, 'Le taux doit être supérieur à 1%')
      .max(MAX_INTEREST_RATE, `Taux maximum BCEAO : ${MAX_INTEREST_RATE * 100}%`)
      .optional(),
    reason: z
      .string()
      .min(10, 'Le motif de rejet doit être détaillé (min 10 caractères)')
      .optional(),
  })
  .refine(
    (data) => data.decision !== 'REJECTED' || data.reason !== undefined,
    { message: 'Le motif de rejet est obligatoire', path: ['reason'] },
  );

export type ValidateLoanDto = z.infer<typeof validateLoanSchema>;

export class ValidateLoanDtoDoc {
  @ApiProperty({ enum: ['APPROVED', 'REJECTED'], example: 'APPROVED' })
  decision!: 'APPROVED' | 'REJECTED';

  @ApiPropertyOptional({
    example: 0.15,
    description: `Taux annuel appliqué (max ${MAX_INTEREST_RATE * 100}% BCEAO). Défaut : ${DEFAULT_INTEREST_RATE * 100}%`,
  })
  interest_rate?: number;

  @ApiPropertyOptional({
    example: 'Revenus insuffisants au regard du montant demandé.',
    description: 'Obligatoire si decision = REJECTED',
  })
  reason?: string;
}
