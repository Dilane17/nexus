import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const resendOtpSchema = z.object({
  email: z.string().email('Email invalide'),
});

export type ResendOtpDto = z.infer<typeof resendOtpSchema>;

export class ResendOtpDtoDoc {
  @ApiProperty({ example: 'kofi.mensah@email.com', description: 'Email auquel renvoyer le code OTP' })
  email!: string;
}
