import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { PrismaService } from '@shared/prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { MailService } from '@shared/mail/mail.service';
import { SmsService } from '@shared/sms/sms.service';
import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';

const prismaMock = {
  user: { findUnique: jest.fn(), update: jest.fn() },
  admin: { findUnique: jest.fn() },
  imfStaff: { findUnique: jest.fn() },
  agent: { findUnique: jest.fn() },
  investor: { findUnique: jest.fn() },
  borrower: { findUnique: jest.fn() },
};

describe('AuthService — changePassword', () => {
  let service: AuthService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: JwtService, useValue: { signAsync: jest.fn() } },
        { provide: ConfigService, useValue: { get: jest.fn(), getOrThrow: jest.fn() } },
        { provide: MailService, useValue: { sendOtpEmail: jest.fn() } },
        { provide: SmsService, useValue: { sendOtpSms: jest.fn() } },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    jest.clearAllMocks();
  });

  it('lève BadRequestException si le compte n\'a pas de mot de passe (Google)', async () => {
    prismaMock.user.findUnique.mockResolvedValue({ id: 'user-id', password: null });

    await expect(
      service.changePassword('user-id', {
        currentPassword: 'old',
        newPassword: 'NewPass1',
        confirmPassword: 'NewPass1',
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('lève UnauthorizedException si le mot de passe actuel est incorrect', async () => {
    const hashed = await bcrypt.hash('CorrectPass1', 10);
    prismaMock.user.findUnique.mockResolvedValue({ id: 'user-id', password: hashed });

    await expect(
      service.changePassword('user-id', {
        currentPassword: 'WrongPass1',
        newPassword: 'NewPass1',
        confirmPassword: 'NewPass1',
      }),
    ).rejects.toThrow(UnauthorizedException);
  });

  it('lève BadRequestException si le nouveau mot de passe est identique à l\'actuel', async () => {
    const hashed = await bcrypt.hash('SamePass1', 10);
    prismaMock.user.findUnique.mockResolvedValue({ id: 'user-id', password: hashed });

    await expect(
      service.changePassword('user-id', {
        currentPassword: 'SamePass1',
        newPassword: 'SamePass1',
        confirmPassword: 'SamePass1',
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('met à jour le mot de passe et révoque le refresh token', async () => {
    const hashed = await bcrypt.hash('OldPass1', 10);
    prismaMock.user.findUnique.mockResolvedValue({ id: 'user-id', password: hashed });
    prismaMock.user.update.mockResolvedValue({});

    await expect(
      service.changePassword('user-id', {
        currentPassword: 'OldPass1',
        newPassword: 'NewPass2',
        confirmPassword: 'NewPass2',
      }),
    ).resolves.toBeUndefined();

    expect(prismaMock.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-id' },
        data: expect.objectContaining({ refresh_token: null }),
      }),
    );
  });
});
