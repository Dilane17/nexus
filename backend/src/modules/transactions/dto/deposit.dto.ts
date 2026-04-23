import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const depositSchema = z.object({
  amount: z
    .number({ error: 'Le montant doit être un nombre' })
    .positive('Le montant doit être positif')
    .int('Le montant doit être un entier en FCFA')
    .min(1_000, 'Montant minimum de dépôt : 1 000 FCFA'),
  momo_provider: z.enum(['MTN_MOMO', 'MOOV_FLOOZ'], {
    error: 'Opérateur invalide — MTN_MOMO ou MOOV_FLOOZ',
  }),
  momo_phone: z
    .string({ error: 'Le numéro MoMo est requis' })
    .min(8, 'Numéro MoMo invalide')
    .max(20, 'Numéro MoMo trop long'),
});

export type DepositDto = z.infer<typeof depositSchema>;

export class DepositDtoDoc {
  @ApiProperty({ example: 50000, description: 'Montant à déposer en FCFA (min 1 000)' })
  amount!: number;

  @ApiProperty({ enum: ['MTN_MOMO', 'MOOV_FLOOZ'], example: 'MTN_MOMO' })
  momo_provider!: 'MTN_MOMO' | 'MOOV_FLOOZ';

  @ApiProperty({ example: '+22997000000', description: 'Numéro MoMo source du dépôt' })
  momo_phone!: string;
}
