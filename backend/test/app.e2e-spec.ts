import { Test, TestingModule } from '@nestjs/testing';
import { TransactionsController } from '../src/modules/transactions/transactions.controller';
import { TransactionsService } from '../src/modules/transactions/transactions.service';

describe('TransactionsController integration (e2e)', () => {
  let controller: TransactionsController;

  const transactionsServiceMock = {
    handleWebhook: jest.fn().mockResolvedValue({ processed: true }),
  };

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [TransactionsController],
      providers: [
        { provide: TransactionsService, useValue: transactionsServiceMock },
      ],
    }).compile();

    controller = moduleFixture.get<TransactionsController>(TransactionsController);
    jest.clearAllMocks();
  });

  it('transmet le webhook FedaPay avec rawBody et headers au service', async () => {
    const req = {
      rawBody: Buffer.from(JSON.stringify({ type: 'transaction.approved' })),
      headers: { 'x-fedapay-signature': 'sig' },
    };

    const response = await controller.webhookFedapay(req as never, {
      type: 'transaction.approved',
    });

    expect(response.success).toBe(true);
    expect(transactionsServiceMock.handleWebhook).toHaveBeenCalledWith(
      'FEDAPAY',
      { type: 'transaction.approved' },
      expect.any(Buffer),
      { 'x-fedapay-signature': 'sig' },
    );
  });

  it('transmet le webhook KKiaPay avec rawBody et headers au service', async () => {
    const req = {
      rawBody: Buffer.from(JSON.stringify({ event: 'transaction.success' })),
      headers: { 'x-kkiapay-secret': 'secret' },
    };

    const response = await controller.webhookKkiapay(req as never, {
      event: 'transaction.success',
    });

    expect(response.success).toBe(true);
    expect(transactionsServiceMock.handleWebhook).toHaveBeenCalledWith(
      'KKIAPAY',
      { event: 'transaction.success' },
      expect.any(Buffer),
      { 'x-kkiapay-secret': 'secret' },
    );
  });
});
