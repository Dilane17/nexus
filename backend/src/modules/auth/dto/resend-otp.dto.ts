import { z } from 'zod/v4';
import { ApiPropertyOptional } from '@nestjs/swagger';

export const resendOtpSchema = z
  .object({
    phone: z
      .string()
      .regex(/^\+229\d{8,10}$/, 'Format invalide — ex: +22991000000')
      .optional(),
    email: z.string().email('Email invalide').optional(),
  })
  .refine((data) => data.phone !== undefined || data.email !== undefined, {
    message: 'phone ou email est requis',
  });

export type ResendOtpDto = z.infer<typeof resendOtpSchema>;

export class ResendOtpDtoDoc {
  @ApiPropertyOptional({ example: '+22991000000', description: 'Pour renvoyer un SMS OTP' })
  phone?: string;

  @ApiPropertyOptional({ example: 'user@example.com', description: 'Pour renvoyer un email OTP' })
  email?: string;
}
