import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const completeCycleSchema = z
  .object({
    members_paid: z
      .number({ error: 'Le nombre de membres ayant payé doit être un entier' })
      .int()
      .min(0),
    members_defaulted: z
      .number({ error: 'Le nombre de membres défaillants doit être un entier' })
      .int()
      .min(0),
    total_collected: z
      .number({ error: 'Le total collecté doit être un nombre positif' })
      .positive('Le total collecté doit être positif'),
  })
  .refine((d) => d.members_paid + d.members_defaulted > 0, {
    message: 'La somme membres payés + défaillants doit être supérieure à 0',
    path: ['members_paid'],
  });

export type CompleteCycleDto = z.infer<typeof completeCycleSchema>;

export class CompleteCycleDtoDoc {
  @ApiProperty({ example: 8, description: 'Nombre de membres ayant cotisé' })
  members_paid!: number;

  @ApiProperty({ example: 2, description: 'Nombre de membres défaillants' })
  members_defaulted!: number;

  @ApiProperty({ example: 80000, description: 'Total collecté en FCFA' })
  total_collected!: number;
}
