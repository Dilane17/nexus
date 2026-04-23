import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const createTontineGroupSchema = z.object({
  name: z
    .string({ error: 'Le nom du groupe est requis' })
    .min(3, 'Le nom doit contenir au moins 3 caractères')
    .max(150, 'Le nom ne peut pas dépasser 150 caractères'),
  monthly_contribution: z
    .number({ error: 'La cotisation mensuelle doit être un nombre' })
    .positive('La cotisation mensuelle doit être positive')
    .int('La cotisation doit être un entier en FCFA')
    .min(1_000, 'Cotisation minimum : 1 000 FCFA'),
});

export type CreateTontineGroupDto = z.infer<typeof createTontineGroupSchema>;

export class CreateTontineGroupDtoDoc {
  @ApiProperty({ example: 'Tontine des femmes de Cadjehoun', description: 'Nom du groupe' })
  name!: string;

  @ApiProperty({ example: 10000, description: 'Cotisation mensuelle par membre en FCFA' })
  monthly_contribution!: number;
}
