import { z } from 'zod/v4';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export const webhookCallbackSchema = z.object({
  momo_reference: z
    .string({ error: 'La référence MoMo est requise' })
    .min(1),
  status: z.enum(['CONFIRMED', 'FAILED'], {
    error: 'Statut invalide — CONFIRMED ou FAILED',
  }),
  failure_reason: z.string().optional(),
});

export type WebhookCallbackDto = z.infer<typeof webhookCallbackSchema>;

export class WebhookCallbackDtoDoc {
  @ApiProperty({ example: 'MTN-20260419-XYZ789' })
  momo_reference!: string;

  @ApiProperty({ enum: ['CONFIRMED', 'FAILED'], example: 'CONFIRMED' })
  status!: 'CONFIRMED' | 'FAILED';

  @ApiPropertyOptional({ example: 'Solde MoMo insuffisant' })
  failure_reason?: string;
}
