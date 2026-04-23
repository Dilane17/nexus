import { z } from 'zod/v4';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export const kycValidateSchema = z
  .object({
    decision: z.enum(['APPROVED', 'REJECTED']),
    reason: z
      .string()
      .min(10, 'La raison de rejet doit être détaillée (min 10 caractères)')
      .optional(),
  })
  .refine(
    (data) => data.decision !== 'REJECTED' || data.reason !== undefined,
    { message: 'La raison est requise en cas de rejet', path: ['reason'] },
  );

export type KycValidateDto = z.infer<typeof kycValidateSchema>;

export class KycValidateDtoDoc {
  @ApiProperty({ enum: ['APPROVED', 'REJECTED'], example: 'APPROVED' })
  decision!: 'APPROVED' | 'REJECTED';

  @ApiPropertyOptional({
    example: 'Document non lisible. Veuillez soumettre une photo plus nette.',
    description: 'Obligatoire si decision = REJECTED',
  })
  reason?: string;
}
