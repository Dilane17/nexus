import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const VALID_DURATIONS = [3, 6, 9, 12] as const;
export type LoanDuration = (typeof VALID_DURATIONS)[number];

export const MIN_AMOUNT = 25_000;
export const MAX_AMOUNT = 500_000;

export const createLoanSchema = z.object({
  amount: z
    .number({ error: 'Le montant doit être un nombre' })
    .int('Le montant doit être un entier en FCFA')
    .min(MIN_AMOUNT, `Montant minimum : ${MIN_AMOUNT.toLocaleString()} FCFA`)
    .max(MAX_AMOUNT, `Montant maximum : ${MAX_AMOUNT.toLocaleString()} FCFA`),
  duration_months: z
    .union([z.literal(3), z.literal(6), z.literal(9), z.literal(12)], {
      error: 'Durée invalide — valeurs autorisées : 3, 6, 9 ou 12 mois',
    }),
  purpose: z
    .string({ error: "L'objet du prêt est requis" })
    .min(10, "L'objet du prêt doit contenir au moins 10 caractères")
    .max(500, "L'objet du prêt ne peut pas dépasser 500 caractères"),
});

export type CreateLoanDto = z.infer<typeof createLoanSchema>;

export class CreateLoanDtoDoc {
  @ApiProperty({
    example: 150000,
    description: `Montant en FCFA (entre ${MIN_AMOUNT.toLocaleString()} et ${MAX_AMOUNT.toLocaleString()})`,
  })
  amount!: number;

  @ApiProperty({
    enum: VALID_DURATIONS,
    example: 6,
    description: 'Durée en mois (3, 6, 9 ou 12 uniquement — règle BCEAO)',
  })
  duration_months!: LoanDuration;

  @ApiProperty({
    example: 'Achat de stock pour mon commerce de tissus',
    description: "Objet du prêt (10–500 caractères)",
  })
  purpose!: string;
}
