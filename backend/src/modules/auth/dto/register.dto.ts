import { z } from 'zod/v4';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export const registerSchema = z.object({
  firstName: z.string().min(2, 'Le prénom doit contenir au moins 2 caractères'),
  lastName: z.string().min(2, 'Le nom doit contenir au moins 2 caractères'),
  phone: z
    .string()
    .regex(/^\+229\d{8}$/, 'Numéro de téléphone invalide')
    .optional(),
  email: z.string().email('Email invalide'),
  password: z
    .string()
    .min(8, 'Au moins 8 caractères')
    .regex(/[A-Z]/, 'Au moins une majuscule')
    .regex(/[0-9]/, 'Au moins un chiffre'),
  city: z.string().optional(),
  district: z.string().optional(),
});

export type RegisterDto = z.infer<typeof registerSchema>;

export class RegisterDtoDoc {
  @ApiProperty({ example: 'Kofi', minLength: 2 })
  firstName!: string;

  @ApiProperty({ example: 'Mensah', minLength: 2 })
  lastName!: string;

  @ApiPropertyOptional({
    example: '+22997000000',
    description: 'Numéro de téléphone béninois',
  })
  phone?: string;

  @ApiProperty({
    example: 'kofi.mensah@email.com',
    description: 'Adresse email',
  })
  email!: string;

  @ApiProperty({
    example: 'Password1',
    description: 'Min 8 chars, 1 majuscule, 1 chiffre',
  })
  password!: string;

  @ApiPropertyOptional({ example: 'Cotonou' })
  city?: string;

  @ApiPropertyOptional({ example: 'Cadjehoun' })
  district?: string;
}
