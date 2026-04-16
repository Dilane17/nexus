import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './shared/prisma/prisma.module';
import { SharedModule } from './shared/shared.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { LoansModule } from './modules/loans/loans.module';
import { InvestmentsModule } from './modules/investments/investments.module';
import { TontineModule } from './modules/tontine/tontine.module';
import { TransactionsModule } from './modules/transactions/transactions.module';
import { AdminModule } from './modules/admin/admin.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    SharedModule,
    AuthModule,
    UsersModule,
    LoansModule,
    InvestmentsModule,
    TontineModule,
    TransactionsModule,
    AdminModule,
  ],
})
export class AppModule {}
