import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'Le refresh token est requis'),
});

export type RefreshDto = z.infer<typeof refreshSchema>;

export class RefreshDtoDoc {
  @ApiProperty({ description: 'Refresh token obtenu lors du login' })
  refreshToken!: string;
}
