import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const verifyPhoneSchema = z.object({
  phone: z.string().regex(/^\+229\d{8,10}$/, 'Format invalide — ex: +22991000000'),
  code: z
    .string()
    .length(5, 'Le code OTP contient exactement 5 chiffres')
    .regex(/^\d{5}$/, 'Le code doit être numérique'),
});

export const verifyEmailSchema = z.object({
  email: z.string().email('Email invalide'),
  code: z
    .string()
    .length(5, 'Le code OTP contient exactement 5 chiffres')
    .regex(/^\d{5}$/, 'Le code doit être numérique'),
});

export type VerifyPhoneDto = z.infer<typeof verifyPhoneSchema>;
export type VerifyEmailDto = z.infer<typeof verifyEmailSchema>;

export class VerifyPhoneDtoDoc {
  @ApiProperty({ example: '+22991000000' })
  phone!: string;

  @ApiProperty({ example: '47291', description: 'Code à 5 chiffres reçu par SMS' })
  code!: string;
}

export class VerifyEmailDtoDoc {
  @ApiProperty({ example: 'user@example.com' })
  email!: string;

  @ApiProperty({ example: '83042', description: 'Code à 5 chiffres reçu par email' })
  code!: string;
}
