import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const createInvestmentSchema = z.object({
  loanId: z
    .string({ error: "L'identifiant du prêt est requis" })
    .uuid("L'identifiant du prêt doit être un UUID valide"),
  amount: z
    .number({ error: 'Le montant doit être un nombre' })
    .positive('Le montant doit être positif')
    .int('Le montant doit être un entier en FCFA')
    .min(5_000, 'Montant minimum d\'investissement : 5 000 FCFA'),
});

export type CreateInvestmentDto = z.infer<typeof createInvestmentSchema>;

export class CreateInvestmentDtoDoc {
  @ApiProperty({
    example: '550e8400-e29b-41d4-a716-446655440000',
    description: 'UUID du prêt en statut FUNDING',
  })
  loanId!: string;

  @ApiProperty({
    example: 50000,
    description: 'Montant à investir en FCFA (minimum 5 000)',
  })
  amount!: number;
}
