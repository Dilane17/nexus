import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const loginSchema = z.object({
  email: z.string().email('Email invalide'),
  password: z.string().min(6, 'Le mot de passe doit contenir au moins 6 caractères'),
});

export type LoginDto = z.infer<typeof loginSchema>;

export class LoginDtoDoc {
  @ApiProperty({ example: 'kofi.mensah@email.com', description: 'Adresse email' })
  email!: string;

  @ApiProperty({ example: 'Password1', minLength: 6 })
  password!: string;
}
