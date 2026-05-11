import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const completeCycleSchema = z
  .object({
    membersPaid: z
      .number({ error: 'Le nombre de membres ayant payé doit être un entier' })
      .int()
      .min(0),
    membersDefaulted: z
      .number({ error: 'Le nombre de membres défaillants doit être un entier' })
      .int()
      .min(0),
    totalCollected: z
      .number({ error: 'Le total collecté doit être un nombre positif' })
      .positive('Le total collecté doit être positif'),
  })
  .refine((d) => d.membersPaid + d.membersDefaulted > 0, {
    message: 'La somme membres payés + défaillants doit être supérieure à 0',
    path: ['membersPaid'],
  });

export type CompleteCycleDto = z.infer<typeof completeCycleSchema>;

export class CompleteCycleDtoDoc {
  @ApiProperty({ example: 8, description: 'Nombre de membres ayant cotisé' })
  membersPaid!: number;

  @ApiProperty({ example: 2, description: 'Nombre de membres défaillants' })
  membersDefaulted!: number;

  @ApiProperty({ example: 80000, description: 'Total collecté en FCFA' })
  totalCollected!: number;
}
