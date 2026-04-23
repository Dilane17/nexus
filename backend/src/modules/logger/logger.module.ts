import { Module } from '@nestjs/common';
import { LoggerService } from './logger.service';
import { LoggerMiddleware } from './logger.middleware';

@Module({
  providers: [LoggerService],
  exports: [LoggerService],
})
export class LoggerModule {}
