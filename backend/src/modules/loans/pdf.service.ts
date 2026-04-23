import { Injectable } from '@nestjs/common';
import PDFDocument from 'pdfkit';
import { CurrencyService } from '@shared/currency/currency.service';

@Injectable()
export class PdfService {
  constructor(private readonly currencyService: CurrencyService) {}

  async generateBceaoReport(data: BceaoReportData): Promise<Buffer> {
    return new Promise((resolve) => {
      const doc = new PDFDocument({ margin: 50 });
      const chunks: Buffer[] = [];

      doc.on('data', (chunk: Buffer) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));

      // Header
      doc
        .fontSize(20)
        .text("RAPPORT D'ACTIVITÉ FINANCIÈRE - NEXUS", { align: 'center' });
      doc.fontSize(10).text(`Généré le : ${new Date().toLocaleDateString()}`, {
        align: 'center',
      });
      doc.moveDown();

      // Section Statistiques
      doc
        .fontSize(14)
        .fillColor('#1A3A5C')
        .text('Résumé du Portefeuille', { underline: true });
      doc.moveDown(0.5);
      doc.fontSize(11).fillColor('black');

      this.addTableRow(
        doc,
        'Nombre total de prêts',
        data.loans.totalCount.toString(),
      );
      this.addTableRow(
        doc,
        'Encours total (XOF)',
        this.currencyService.formatAmount(
          data.loans.totalPortfolioValue,
          'XOF',
        ),
      );
      this.addTableRow(
        doc,
        'Ratio NPL (Prêts non performants)',
        `${(data.loans.nplRatio * 100).toFixed(2)}%`,
      );

      doc.moveDown();

      // Section Transactions
      doc
        .fontSize(14)
        .fillColor('#1A3A5C')
        .text('Transactions de la période', { underline: true });
      doc.moveDown(0.5);
      doc.fontSize(11).fillColor('black');

      this.addTableRow(
        doc,
        'Volume total déposé',
        this.currencyService.formatAmount(data.transactions.todayVolume, 'XOF'),
      );
      this.addTableRow(
        doc,
        'Alertes PHANTOM détectées',
        data.transactions.phantomCount.toString(),
      );

      // Footer
      const bottom = doc.page.height - 50;
      doc
        .fontSize(8)
        .text(
          'Nexus P2P Lending - Conforme aux normes de la BCEAO / Zone UEMOA',
          50,
          bottom,
          { align: 'center' },
        );

      doc.end();
    });
  }

  private addTableRow(doc: PDFKit.PDFDocument, label: string, value: string) {
    const currentY = doc.y;
    doc.text(label, 50, currentY);
    doc.text(value, 350, currentY, { align: 'right' });
    doc.moveDown(0.5);
  }
}

interface BceaoReportData {
  loans: {
    totalCount: number;
    totalPortfolioValue: number;
    nplRatio: number;
  };
  transactions: {
    todayVolume: number;
    phantomCount: number;
  };
}
