import { z } from 'zod/v4';
import { ApiPropertyOptional } from '@nestjs/swagger';

export const updateProfileSchema = z.object({
  firstName: z.string().min(2, 'Au moins 2 caractères').optional(),
  lastName: z.string().min(2, 'Au moins 2 caractères').optional(),
  city: z.string().optional(),
  district: z.string().optional(),
});

export type UpdateProfileDto = z.infer<typeof updateProfileSchema>;

export class UpdateProfileDtoDoc {
  @ApiPropertyOptional({ example: 'Kofi' })
  firstName?: string;

  @ApiPropertyOptional({ example: 'Mensah' })
  lastName?: string;

  @ApiPropertyOptional({ example: 'Cotonou' })
  city?: string;

  @ApiPropertyOptional({ example: 'Cadjehoun' })
  district?: string;
}
