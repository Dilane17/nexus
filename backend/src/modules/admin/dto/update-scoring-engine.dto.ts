import { z } from 'zod/v4';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export const updateScoringEngineSchema = z
  .object({
    momoWeight: z.number().min(0, 'Minimum 0').max(1, 'Maximum 1'),
    tontineWeight: z.number().min(0, 'Minimum 0').max(1, 'Maximum 1'),
    imfWeight: z.number().min(0, 'Minimum 0').max(1, 'Maximum 1'),
    warningSignalDays: z
      .number()
      .int('Doit être un entier')
      .positive('Doit être positif'),
  })
  .refine(
    (d) => Math.abs(d.momoWeight + d.tontineWeight + d.imfWeight - 1) < 0.001,
    {
      message:
        'La somme des poids (momo + tontine + imf) doit être égale à 1.00',
      path: ['momoWeight'],
    },
  );

export type UpdateScoringEngineDto = z.infer<typeof updateScoringEngineSchema>;

export class UpdateScoringEngineDtoDoc {
  @ApiProperty({ example: 0.4, minimum: 0, maximum: 1 })
  momoWeight!: number;

  @ApiProperty({ example: 0.35, minimum: 0, maximum: 1 })
  tontineWeight!: number;

  @ApiProperty({ example: 0.25, minimum: 0, maximum: 1 })
  imfWeight!: number;

  @ApiPropertyOptional({
    example: 45,
    description: "Jours avant signal d'alerte",
  })
  warningSignalDays?: number;
}
