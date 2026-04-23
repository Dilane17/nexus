import { Injectable, LoggerService as NestLoggerService } from '@nestjs/common';
import * as winston from 'winston';
import DailyRotateFile from 'winston-daily-rotate-file';

@Injectable()
export class LoggerService implements NestLoggerService {
  private logger: winston.Logger;

  constructor() {
    this.logger = this.createLogger();
  }

  private createLogger(): winston.Logger {
    const isProduction = process.env.NODE_ENV === 'production';

    const transports: winston.transport[] = [];

    // Console transport pour développement
    if (!isProduction) {
      transports.push(
        new winston.transports.Console({
          level: 'debug',
          format: winston.format.combine(
            winston.format.timestamp(),
            winston.format.colorize(),
            winston.format.printf(({ timestamp, level, message, ...meta }) => {
              const metaStr = Object.keys(meta).length
                ? JSON.stringify(meta, null, 2)
                : '';
              return `${timestamp} [${level}]: ${message} ${metaStr}`;
            }),
          ),
        }),
      );
    }

    // Fichier de logs pour tous les niveaux
    transports.push(
      new DailyRotateFile({
        filename: 'logs/application-%DATE%.log',
        datePattern: 'YYYY-MM-DD',
        maxSize: '20m',
        maxFiles: '14d',
        level: isProduction ? 'info' : 'debug',
        format: winston.format.combine(
          winston.format.timestamp(),
          winston.format.errors({ stack: true }),
          winston.format.json(),
        ),
      }),
    );

    // Fichier séparé pour les erreurs
    transports.push(
      new DailyRotateFile({
        filename: 'logs/error-%DATE%.log',
        datePattern: 'YYYY-MM-DD',
        maxSize: '20m',
        maxFiles: '30d',
        level: 'error',
        format: winston.format.combine(
          winston.format.timestamp(),
          winston.format.errors({ stack: true }),
          winston.format.json(),
        ),
      }),
    );

    return winston.createLogger({
      level: isProduction ? 'info' : 'debug',
      transports,
      exitOnError: false,
    });
  }

  // Interface NestLoggerService
  log(message: any, context?: string) {
    this.logger.info(message, { context });
  }

  error(message: any, trace?: string, context?: string) {
    this.logger.error(message, { trace, context });
  }

  warn(message: any, context?: string) {
    this.logger.warn(message, { context });
  }

  debug(message: any, context?: string) {
    this.logger.debug(message, { context });
  }

  verbose(message: any, context?: string) {
    this.logger.verbose(message, { context });
  }

  // Méthodes personnalisées pour logs métier
  httpRequest(
    method: string,
    url: string,
    statusCode: number,
    duration: number,
    userId?: string,
    ip?: string,
  ) {
    this.logger.info('HTTP Request', {
      type: 'http_request',
      method,
      url,
      statusCode,
      duration: `${duration}ms`,
      userId,
      ip,
    });
  }

  businessAction(
    action: string,
    entity: string,
    entityId?: string,
    userId?: string,
    details?: any,
  ) {
    this.logger.info('Business Action', {
      type: 'business_action',
      action,
      entity,
      entityId,
      userId,
      details,
    });
  }

  securityEvent(event: string, userId?: string, ip?: string, details?: any) {
    this.logger.warn('Security Event', {
      type: 'security_event',
      event,
      userId,
      ip,
      details,
    });
  }

  performanceMetric(
    metric: string,
    value: number,
    unit: string,
    context?: any,
  ) {
    this.logger.info('Performance Metric', {
      type: 'performance',
      metric,
      value,
      unit,
      context,
    });
  }
}
