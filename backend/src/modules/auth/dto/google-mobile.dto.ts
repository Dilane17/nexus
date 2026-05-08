import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const googleMobileSchema = z.object({
  idToken: z.string().min(10, 'idToken Google requis'),
});

export type GoogleMobileDto = z.infer<typeof googleMobileSchema>;

export class GoogleMobileDtoDoc {
  @ApiProperty({
    description: 'Google ID token retourné par google_sign_in Flutter',
  })
  idToken!: string;
}
