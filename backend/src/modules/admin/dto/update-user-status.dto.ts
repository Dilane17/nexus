import { z } from 'zod/v4';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export const updateUserStatusSchema = z
  .object({
    status: z.enum(['ACTIVE', 'SUSPENDED', 'BLOCKED'], {
      error: 'Statut invalide — ACTIVE, SUSPENDED ou BLOCKED',
    }),
    reason: z
      .string()
      .min(5, 'La raison doit contenir au moins 5 caractères')
      .optional(),
  })
  .refine((d) => d.status === 'ACTIVE' || d.reason !== undefined, {
    message: 'La raison est obligatoire pour suspendre ou bloquer',
    path: ['reason'],
  });

export type UpdateUserStatusDto = z.infer<typeof updateUserStatusSchema>;

export class UpdateUserStatusDtoDoc {
  @ApiProperty({
    enum: ['ACTIVE', 'SUSPENDED', 'BLOCKED'],
    example: 'SUSPENDED',
  })
  status!: 'ACTIVE' | 'SUSPENDED' | 'BLOCKED';

  @ApiPropertyOptional({ example: 'Comportement frauduleux détecté' })
  reason?: string;
}
