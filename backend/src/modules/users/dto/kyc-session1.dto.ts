import { z } from 'zod/v4';
import { ApiProperty } from '@nestjs/swagger';

export const KYC_DOCUMENT_TYPES = [
  'CNI',
  'CIP',
  'PASSEPORT',
  'PERMIS',
] as const;
export type KycDocumentType = (typeof KYC_DOCUMENT_TYPES)[number];

export const kycSession1Schema = z.object({
  documentType: z.enum(KYC_DOCUMENT_TYPES, {
    error:
      'Type de document invalide. Valeurs acceptées : CNI, CIP, PASSEPORT, PERMIS',
  }),
  documentUrl: z
    .string()
    .url('URL de document invalide')
    .min(1, "L'URL du document est requise"),
  selfieUrl: z
    .string()
    .url('URL du selfie invalide')
    .min(1, "L'URL du selfie est requise"),
});

export type KycSession1Dto = z.infer<typeof kycSession1Schema>;

export class KycSession1DtoDoc {
  @ApiProperty({ enum: KYC_DOCUMENT_TYPES, example: 'CNI' })
  documentType!: KycDocumentType;

  @ApiProperty({
    example: 'https://storage.nexus.bj/docs/cni-user-123.jpg',
    description: 'URL de la photo du document',
  })
  documentUrl!: string;

  @ApiProperty({
    example: 'https://storage.nexus.bj/docs/selfie-user-123.jpg',
    description: "URL du selfie de l'utilisateur pour vérification conformité",
  })
  selfieUrl!: string;
}
