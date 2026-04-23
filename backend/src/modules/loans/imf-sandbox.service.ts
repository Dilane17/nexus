/* eslint-disable @typescript-eslint/no-unsafe-return */
import { Injectable, Logger, HttpException, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { AxiosResponse } from 'axios';
import { firstValueFrom } from 'rxjs';
import { PrismaService } from '@shared/prisma/prisma.service';

@Injectable()
export class ImfSandboxService {
  private readonly logger = new Logger(ImfSandboxService.name);
  private readonly baseUrl?: string;
  private readonly token?: string;

  constructor(
    private readonly config: ConfigService,
    private readonly httpService: HttpService,
    private readonly prisma: PrismaService,
  ) {
    this.baseUrl = this.config.get<string>('IMF_SANDBOX_URL');
    this.token = this.config.get<string>('IMF_SANDBOX_TOKEN');
  }

  async scoreLoan(imfStaffId: string, loanId: string) {
    const loan = await this.prisma.loan.findUnique({
      where: { id: loanId },
      select: { amount: true, duration_months: true, borrower_id: true },
    });
    if (!loan)
      throw new HttpException('Prêt introuvable', HttpStatus.NOT_FOUND);

    const res = await this.getExternalImfScore(loan.borrower_id, {
      amount: Number(loan.amount),
      duration: loan.duration_months,
    });

    return {
      ...res,
      loanId,
      suggestedInterestRate: res.riskLevel === 'LOW' ? 0.12 : 0.15,
      riskFactors: res.score < 60 ? ['Historique externe limité'] : [],
      computedAt: new Date(),
    };
  }

  async getExternalImfScore(
    borrowerId: string,
    loanData: { amount: number; duration: number },
  ): Promise<{
    score: number;
    recommendation: string;
    riskLevel: string;
  }> {
    // Si pas d'URL configurée, on reste en fallback local pour le dev
    if (!this.baseUrl) {
      this.logger.warn(
        'IMF_SANDBOX_URL non définie, utilisation du fallback local',
      );
      return this.simulateLocalScore(loanData.amount);
    }

    try {
      const response: AxiosResponse = await firstValueFrom(
        this.httpService.post(
          `${this.baseUrl}/v1/scoring/analyze`,
          { borrower_id: borrowerId, ...loanData },
          { headers: { Authorization: `Bearer ${this.token}` } },
        ),
      );
      return response.data;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Erreur IMF Sandbox HTTP: ${message}`);
      // Stratégie de résilience : on retourne un score moyen au lieu de bloquer le prêt
      return {
        score: 50,
        recommendation: 'MANUAL_REVIEW_REQUIRED',
        riskLevel: 'MEDIUM',
      };
    }
  }

  private simulateLocalScore(amount: number) {
    const score = amount > 400000 ? 45 : 75;
    return {
      score,
      recommendation: score > 50 ? 'APPROVE' : 'HIGH_RISK_REVIEW',
      riskLevel: score > 50 ? 'LOW' : 'HIGH',
    };
  }
}
