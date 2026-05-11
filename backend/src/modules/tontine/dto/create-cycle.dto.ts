import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const createCycleSchema = z
  .object({
    cycleNumber: z
      .number({ error: 'Le numéro de cycle doit être un entier' })
      .int()
      .min(1, 'Le numéro de cycle doit être supérieur ou égal à 1'),
    startDate: z
      .string({ error: 'La date de début est requise' })
      .date('Format attendu : YYYY-MM-DD'),
    endDate: z
      .string({ error: 'La date de fin est requise' })
      .date('Format attendu : YYYY-MM-DD'),
    beneficiaryId: z
      .string({ error: "L'identifiant du bénéficiaire est requis" })
      .uuid("L'identifiant du bénéficiaire doit être un UUID valide"),
  })
  .refine((d) => d.endDate > d.startDate, {
    message: 'La date de fin doit être postérieure à la date de début',
    path: ['endDate'],
  });

export type CreateCycleDto = z.infer<typeof createCycleSchema>;

export class CreateCycleDtoDoc {
  @ApiProperty({ example: 1 })
  cycleNumber!: number;

  @ApiProperty({ example: '2026-05-01', description: 'Date de début (YYYY-MM-DD)' })
  startDate!: string;

  @ApiProperty({ example: '2026-05-31', description: 'Date de fin (YYYY-MM-DD)' })
  endDate!: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000', description: 'UUID du bénéficiaire (doit être membre du groupe)' })
  beneficiaryId!: string;
}
