import { z } from 'zod/v4';
import { ApiPropertyOptional } from '@nestjs/swagger';

export const forgotPasswordSchema = z
  .object({
    phone: z
      .string()
      .regex(/^\+229\d{8,10}$/, 'Format invalide — ex: +22991000000')
      .optional(),
    email: z.string().email('Email invalide').optional(),
  })
  .refine(
    (data) => data.phone !== undefined || data.email !== undefined,
    { message: 'phone ou email est requis' },
  )
  .refine(
    (data) => !(data.phone !== undefined && data.email !== undefined),
    { message: 'Fournir phone OU email, pas les deux' },
  );

export type ForgotPasswordDto = z.infer<typeof forgotPasswordSchema>;

export class ForgotPasswordDtoDoc {
  @ApiPropertyOptional({ example: '+22991000000', description: 'Pour reset via SMS OTP' })
  phone?: string;

  @ApiPropertyOptional({ example: 'user@example.com', description: 'Pour reset via email OTP (comptes Google)' })
  email?: string;
}
