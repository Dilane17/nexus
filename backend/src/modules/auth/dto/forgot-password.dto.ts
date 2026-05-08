import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const forgotPasswordSchema = z.object({
  email: z.string().email('Email invalide'),
});

export type ForgotPasswordDto = z.infer<typeof forgotPasswordSchema>;

export class ForgotPasswordDtoDoc {
  @ApiProperty({ example: 'kofi.mensah@email.com', description: 'Email du compte' })
  email!: string;
}
