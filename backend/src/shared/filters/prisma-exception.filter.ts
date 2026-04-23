import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';
import { Prisma } from '@generated/prisma';

@Catch(Prisma.PrismaClientKnownRequestError)
export class PrismaExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PrismaExceptionFilter.name);

  catch(exception: Prisma.PrismaClientKnownRequestError, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    const { status, message } = this.resolve(exception);

    this.logger.error(
      `Prisma ${exception.code} — ${exception.message.split('\n').pop()?.trim() ?? ''}`,
    );

    response.status(status).json({
      success: false,
      message,
      code: exception.code,
    });
  }

  private resolve(e: Prisma.PrismaClientKnownRequestError): {
    status: number;
    message: string;
  } {
    switch (e.code) {
      case 'P2002': {
        const fields = (e.meta?.['target'] as string[] | undefined)?.join(', ') ?? 'champ';
        return {
          status: HttpStatus.CONFLICT,
          message: `Valeur déjà utilisée — contrainte unique sur : ${fields}`,
        };
      }
      case 'P2025':
        return {
          status: HttpStatus.NOT_FOUND,
          message: "Enregistrement introuvable",
        };
      case 'P2003':
        return {
          status: HttpStatus.BAD_REQUEST,
          message: 'Référence invalide — clé étrangère non trouvée',
        };
      case 'P2014':
        return {
          status: HttpStatus.BAD_REQUEST,
          message: 'Relation requise non satisfaite',
        };
      case 'P2011':
        return {
          status: HttpStatus.BAD_REQUEST,
          message: 'Champ obligatoire manquant',
        };
      default:
        return {
          status: HttpStatus.INTERNAL_SERVER_ERROR,
          message: 'Erreur base de données',
        };
    }
  }
}
