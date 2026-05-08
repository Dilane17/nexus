import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const verifyEmailSchema = z.object({
  email: z.string().email('Email invalide'),
  code: z
    .string()
    .length(5, 'Le code OTP contient exactement 5 chiffres')
    .regex(/^\d{5}$/, 'Le code doit être numérique'),
});

export type VerifyEmailDto = z.infer<typeof verifyEmailSchema>;

export class VerifyEmailDtoDoc {
  @ApiProperty({ example: 'kofi.mensah@email.com' })
  email!: string;

  @ApiProperty({ example: '83042', description: 'Code à 5 chiffres reçu par email' })
  code!: string;
}
