import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const repayLoanSchema = z.object({
  amount: z
    .number({ error: 'Le montant doit être un nombre' })
    .positive('Le montant du remboursement doit être positif'),
  momo_reference: z
    .string({ error: 'La référence MoMo est requise' })
    .min(1, 'La référence MoMo est requise')
    .max(100, 'Référence MoMo trop longue'),
  momo_provider: z.enum(['MTN_MOMO', 'MOOV_FLOOZ'], {
    error: 'Opérateur invalide — valeurs : MTN_MOMO ou MOOV_FLOOZ',
  }),
});

export type RepayLoanDto = z.infer<typeof repayLoanSchema>;

export class RepayLoanDtoDoc {
  @ApiProperty({ example: 35000, description: 'Montant remboursé en FCFA' })
  amount!: number;

  @ApiProperty({ example: 'MTN-20260418-ABC123', description: 'Référence unique MoMo' })
  momo_reference!: string;

  @ApiProperty({ enum: ['MTN_MOMO', 'MOOV_FLOOZ'], example: 'MTN_MOMO' })
  momo_provider!: 'MTN_MOMO' | 'MOOV_FLOOZ';
}
