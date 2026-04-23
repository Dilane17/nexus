import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const changePasswordSchema = z
  .object({
    currentPassword: z
      .string({ error: 'Le mot de passe actuel est requis' })
      .min(1, 'Le mot de passe actuel est requis'),
    newPassword: z
      .string({ error: 'Le nouveau mot de passe est requis' })
      .min(6, 'Le nouveau mot de passe doit contenir au moins 6 caractères')
      .regex(/[A-Z]/, 'Le nouveau mot de passe doit contenir au moins une majuscule')
      .regex(/[0-9]/, 'Le nouveau mot de passe doit contenir au moins un chiffre'),
    confirmPassword: z.string({ error: 'La confirmation est requise' }),
  })
  .refine((d) => d.newPassword === d.confirmPassword, {
    message: 'Les mots de passe ne correspondent pas',
    path: ['confirmPassword'],
  });

export type ChangePasswordDto = z.infer<typeof changePasswordSchema>;

export class ChangePasswordDtoDoc {
  @ApiProperty({ example: 'MonAncienMdp1', description: 'Mot de passe actuel' })
  currentPassword!: string;

  @ApiProperty({ example: 'NouveauMdp2025', description: 'Nouveau mot de passe (min 6 chars, 1 majuscule, 1 chiffre)' })
  newPassword!: string;

  @ApiProperty({ example: 'NouveauMdp2025', description: 'Confirmation du nouveau mot de passe' })
  confirmPassword!: string;
}
