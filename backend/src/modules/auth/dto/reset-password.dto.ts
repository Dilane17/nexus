import { z } from 'zod/v4';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export const resetPasswordSchema = z
  .object({
    phone: z
      .string()
      .regex(/^\+229\d{8,10}$/, 'Format invalide — ex: +22991000000')
      .optional(),
    email: z.string().email('Email invalide').optional(),
    code: z
      .string()
      .length(5, 'Le code OTP contient exactement 5 chiffres')
      .regex(/^\d{5}$/, 'Le code doit être numérique'),
    newPassword: z
      .string()
      .min(8, 'Au moins 8 caractères')
      .regex(/[A-Z]/, 'Au moins une majuscule')
      .regex(/[0-9]/, 'Au moins un chiffre'),
    confirmPassword: z.string(),
  })
  .refine(
    (data) => data.phone !== undefined || data.email !== undefined,
    { message: 'phone ou email est requis', path: ['phone'] },
  )
  .refine(
    (data) => !(data.phone !== undefined && data.email !== undefined),
    { message: 'Fournir phone OU email, pas les deux', path: ['phone'] },
  )
  .refine(
    (data) => data.newPassword === data.confirmPassword,
    { message: 'Les mots de passe ne correspondent pas', path: ['confirmPassword'] },
  );

export type ResetPasswordDto = z.infer<typeof resetPasswordSchema>;

export class ResetPasswordDtoDoc {
  @ApiPropertyOptional({ example: '+22991000000' })
  phone?: string;

  @ApiPropertyOptional({ example: 'user@example.com' })
  email?: string;

  @ApiProperty({ example: '47291', description: 'Code OTP reçu par SMS ou email' })
  code!: string;

  @ApiProperty({ example: 'NewPass1', description: 'Min 8 chars, 1 majuscule, 1 chiffre' })
  newPassword!: string;

  @ApiProperty({ example: 'NewPass1' })
  confirmPassword!: string;
}
