import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { LoggerService } from '../logger/logger.service';

@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  constructor(private readonly logger: LoggerService) {}

  use(req: Request, res: Response, next: NextFunction) {
    const { method, originalUrl, ip } = req;
    const userAgent = req.get('User-Agent') || '';
    const start = Date.now();

    // Générer un requestId unique
    const requestId = this.generateRequestId();
    (req as any).requestId = requestId;

    // Logger la requête entrante
    this.logger.httpRequest(method, originalUrl, 0, 0, undefined, ip);

    // Intercepter la réponse
    const originalSend = res.send;
    res.send = (body: any) => {
      const duration = Date.now() - start;
      const statusCode = res.statusCode;

      // Logger la réponse
      this.logger.httpRequest(
        method,
        originalUrl,
        statusCode,
        duration,
        (req as any).user?.id,
        ip,
      );

      // Restaurer la méthode originale
      res.send = originalSend;
      return res.send(body);
    };

    next();
  }

  private generateRequestId(): string {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}
