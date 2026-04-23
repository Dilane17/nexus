import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const loginSchema = z.object({
  phone: z
    .string()
    .regex(/^\+229\d{8,10}$/, 'Format invalide — ex: +22991000000'),
  password: z
    .string()
    .min(6, 'Le mot de passe doit contenir au moins 6 caractères'),
});

export type LoginDto = z.infer<typeof loginSchema>;

// Classe uniquement pour Swagger
export class LoginDtoDoc {
  @ApiProperty({
    example: '+22991000000',
    description: 'Numéro au format +229XXXXXXXX',
  })
  phone!: string;

  @ApiProperty({ example: 'motdepasse123', minLength: 6 })
  password!: string;
}
