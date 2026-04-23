import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
  ConflictException,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { JwtService, type JwtSignOptions } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '@shared/prisma/prisma.service';
import { MailService } from '@shared/mail/mail.service';
import { SmsService } from '@shared/sms/sms.service';
import type { LoginDto } from './dto/login.dto';
import type { RegisterDto } from './dto/register.dto';
import type { UpdateProfileDto } from './dto/update-profile.dto';
import type { VerifyPhoneDto, VerifyEmailDto } from './dto/verify-otp.dto';
import type { ResendOtpDto } from './dto/resend-otp.dto';
import type { ForgotPasswordDto } from './dto/forgot-password.dto';
import type { ResetPasswordDto } from './dto/reset-password.dto';
import type { ChangePasswordDto } from './dto/change-password.dto';
import type {
  AuthTokens,
  AuthUser,
  JwtPayload,
  UserRole,
  GoogleProfile,
  GoogleLoginResult,
} from './auth.types';

// Sélecteur partagé pour les champs utilisateur publics
const USER_PUBLIC_SELECT = {
  id: true,
  firstName: true,
  lastName: true,
  phone: true,
  email: true,
  city: true,
  district: true,
  avatar: true,
  status: true,
  kyc_status: true,
  isPhoneVerified: true,
  isEmailVerified: true,
} as const;

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly mailService: MailService,
    private readonly smsService: SmsService,
  ) {}

  // ── Register ───────────────────────────────────────────────────────────────

  async register(dto: RegisterDto): Promise<{ message: string }> {
    const existing = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
      select: { id: true },
    });

    if (existing) {
      throw new ConflictException('Ce numéro de téléphone est déjà utilisé');
    }

    const hashed = await bcrypt.hash(dto.password, 10);

    const user = await this.prisma.user.create({
      data: {
        firstName: dto.firstName,
        lastName: dto.lastName,
        phone: dto.phone,
        password: hashed,
        city: dto.city,
        district: dto.district,
        status: 'PENDING',
        isPhoneVerified: false,
      },
      select: { id: true, firstName: true, phone: true },
    });

    const code = this.generateOtp();
    await this.saveOtp(user.id, code, 'PHONE_VERIFICATION');
    await this.smsService.sendOtpSms(user.phone, user.firstName, code);

    return { message: `Code envoyé au ${dto.phone}` };
  }

  // ── Verify phone OTP ───────────────────────────────────────────────────────

  async verifyPhone(dto: VerifyPhoneDto): Promise<AuthTokens> {
    const user = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
      select: { id: true, phone: true, isPhoneVerified: true },
    });

    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }

    if (user.isPhoneVerified) {
      throw new BadRequestException('Ce numéro est déjà vérifié');
    }

    const valid = await this.verifyOtp(user.id, dto.code, 'PHONE_VERIFICATION');
    if (!valid) {
      throw new UnauthorizedException('Code invalide ou expiré');
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { isPhoneVerified: true, status: 'ACTIVE' },
    });

    return this.buildAuthResponse(user.id, user.phone);
  }

  // ── Verify email OTP ───────────────────────────────────────────────────────

  async verifyEmail(dto: VerifyEmailDto): Promise<AuthTokens> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
      select: { id: true, phone: true, isEmailVerified: true },
    });

    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }

    if (user.isEmailVerified) {
      throw new BadRequestException('Cet email est déjà vérifié');
    }

    const valid = await this.verifyOtp(user.id, dto.code, 'EMAIL_VERIFICATION');
    if (!valid) {
      throw new UnauthorizedException('Code invalide ou expiré');
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { isEmailVerified: true, status: 'ACTIVE' },
    });

    return this.buildAuthResponse(user.id, user.phone);
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  async login(dto: LoginDto): Promise<AuthTokens> {
    const user = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
      select: {
        id: true,
        phone: true,
        status: true,
        isPhoneVerified: true,
        password: true,
      },
    });

    if (!user || !user.password) {
      throw new UnauthorizedException('Téléphone ou mot de passe incorrect');
    }

    if (user.status === 'BLOCKED') {
      throw new ForbiddenException('Compte bloqué. Contactez le support.');
    }
    if (user.status === 'SUSPENDED') {
      throw new ForbiddenException('Compte suspendu temporairement.');
    }

    const passwordMatch = await bcrypt.compare(dto.password, user.password);
    if (!passwordMatch) {
      throw new UnauthorizedException('Téléphone ou mot de passe incorrect');
    }

    if (!user.isPhoneVerified) {
      throw new UnauthorizedException(
        "Numéro non vérifié. Vérifiez le code SMS reçu lors de l'inscription.",
      );
    }

    return this.buildAuthResponse(user.id, user.phone);
  }

  // ── Google OAuth ───────────────────────────────────────────────────────────

  async googleLogin(profile: GoogleProfile): Promise<GoogleLoginResult> {
    if (!profile.email) {
      throw new BadRequestException("L'email Google est requis");
    }

    // Chercher par googleId ou email
    let user = await this.prisma.user.findFirst({
      where: {
        OR: [{ googleId: profile.googleId }, { email: profile.email }],
      },
      select: {
        id: true,
        phone: true,
        email: true,
        firstName: true,
        isEmailVerified: true,
        status: true,
        googleId: true,
      },
    });

    if (!user) {
      // Nouveau user — créer avec status PENDING
      user = await this.prisma.user.create({
        data: {
          firstName: profile.firstName,
          lastName: profile.lastName,
          email: profile.email,
          googleId: profile.googleId,
          avatar: profile.avatar,
          phone: `+229_google_${profile.googleId}`, // placeholder temporaire
          status: 'PENDING',
          isEmailVerified: false,
          isPhoneVerified: false,
        },
        select: {
          id: true,
          phone: true,
          email: true,
          firstName: true,
          isEmailVerified: true,
          status: true,
          googleId: true,
        },
      });
    } else if (!user.googleId) {
      // User existant via email, lier le googleId
      await this.prisma.user.update({
        where: { id: user.id },
        data: { googleId: profile.googleId, avatar: profile.avatar },
      });
    }

    // Si déjà vérifié, retourner les tokens directement
    if (user.isEmailVerified && user.status === 'ACTIVE') {
      const tokens = await this.buildAuthResponse(user.id, user.phone);
      return { needsVerification: false, tokens };
    }

    // Nouveau user ou non vérifié → envoyer OTP email
    const code = this.generateOtp();
    await this.saveOtp(user.id, code, 'EMAIL_VERIFICATION');

    if (user.email) {
      await this.mailService.sendOtpEmail(user.email, user.firstName, code);
    }

    return {
      needsVerification: true,
      message: `Code de vérification envoyé à ${user.email ?? ''}`,
    };
  }

  // ── Forgot Password ────────────────────────────────────────────────────────

  async forgotPassword(dto: ForgotPasswordDto): Promise<{ message: string }> {
    const GENERIC_MESSAGE = 'Si ce contact existe, un code a été envoyé';

    if (dto.phone) {
      const user = await this.prisma.user.findUnique({
        where: { phone: dto.phone },
        select: { id: true, firstName: true, phone: true, status: true },
      });

      if (!user) {
        return { message: GENERIC_MESSAGE };
      }

      if (user.status === 'BLOCKED') {
        throw new ForbiddenException('Compte bloqué. Contactez le support.');
      }

      const code = this.generateOtp();
      await this.saveOtp(user.id, code, 'PASSWORD_RESET');
      await this.smsService.sendOtpSms(user.phone, user.firstName, code);

      return { message: GENERIC_MESSAGE };
    }

    if (dto.email) {
      const user = await this.prisma.user.findUnique({
        where: { email: dto.email },
        select: {
          id: true,
          firstName: true,
          email: true,
          status: true,
          googleId: true,
        },
      });

      if (!user) {
        return { message: GENERIC_MESSAGE };
      }

      if (user.status === 'BLOCKED') {
        throw new ForbiddenException('Compte bloqué. Contactez le support.');
      }

      if (!user.googleId) {
        throw new BadRequestException(
          "Cet email n'est pas associé à un compte Google",
        );
      }

      const code = this.generateOtp();
      await this.saveOtp(user.id, code, 'PASSWORD_RESET');

      if (user.email) {
        await this.mailService.sendOtpEmail(user.email, user.firstName, code);
      }

      return { message: GENERIC_MESSAGE };
    }

    throw new BadRequestException('phone ou email requis');
  }

  // ── Reset Password ─────────────────────────────────────────────────────────

  async resetPassword(dto: ResetPasswordDto): Promise<{ message: string }> {
    if (dto.phone) {
      const user = await this.prisma.user.findUnique({
        where: { phone: dto.phone },
        select: { id: true, phone: true },
      });

      if (!user) {
        throw new UnauthorizedException('Code invalide ou expiré');
      }

      const valid = await this.verifyOtp(user.id, dto.code, 'PASSWORD_RESET');
      if (!valid) {
        throw new UnauthorizedException('Code invalide ou expiré');
      }

      const hashed = await bcrypt.hash(dto.newPassword, 10);
      await this.prisma.user.update({
        where: { id: user.id },
        data: { password: hashed, refresh_token: null },
      });

      this.logger.log(
        `[AUTH] Mot de passe réinitialisé via téléphone pour ${dto.phone}`,
      );
      return { message: 'Mot de passe modifié. Reconnectez-vous.' };
    }

    if (dto.email) {
      const user = await this.prisma.user.findUnique({
        where: { email: dto.email },
        select: { id: true, email: true },
      });

      if (!user) {
        throw new UnauthorizedException('Code invalide ou expiré');
      }

      const valid = await this.verifyOtp(user.id, dto.code, 'PASSWORD_RESET');
      if (!valid) {
        throw new UnauthorizedException('Code invalide ou expiré');
      }

      const hashed = await bcrypt.hash(dto.newPassword, 10);
      await this.prisma.user.update({
        where: { id: user.id },
        data: { password: hashed, refresh_token: null },
      });

      this.logger.log(
        `[AUTH] Mot de passe défini via Google OAuth pour user ${user.email ?? ''}`,
      );
      return { message: 'Mot de passe modifié. Reconnectez-vous.' };
    }

    throw new BadRequestException('phone ou email requis');
  }

  // ── Resend OTP ─────────────────────────────────────────────────────────────

  async resendOtp(dto: ResendOtpDto): Promise<{ message: string }> {
    if (dto.phone) {
      const user = await this.prisma.user.findUnique({
        where: { phone: dto.phone },
        select: {
          id: true,
          firstName: true,
          phone: true,
          isPhoneVerified: true,
        },
      });

      if (!user) throw new NotFoundException('Utilisateur introuvable');
      if (user.isPhoneVerified) {
        throw new BadRequestException('Ce numéro est déjà vérifié');
      }

      const code = this.generateOtp();
      await this.saveOtp(user.id, code, 'PHONE_VERIFICATION');
      await this.smsService.sendOtpSms(user.phone, user.firstName, code);

      return { message: `Code renvoyé au ${dto.phone}` };
    }

    if (dto.email) {
      const user = await this.prisma.user.findUnique({
        where: { email: dto.email },
        select: {
          id: true,
          firstName: true,
          email: true,
          isEmailVerified: true,
        },
      });

      if (!user) throw new NotFoundException('Utilisateur introuvable');
      if (user.isEmailVerified) {
        throw new BadRequestException('Cet email est déjà vérifié');
      }

      const code = this.generateOtp();
      await this.saveOtp(user.id, code, 'EMAIL_VERIFICATION');

      if (user.email) {
        await this.mailService.sendOtpEmail(user.email, user.firstName, code);
      }

      return { message: `Code renvoyé à ${dto.email}` };
    }

    throw new BadRequestException('phone ou email requis');
  }

  // ── Refresh ────────────────────────────────────────────────────────────────

  async refresh(
    userId: string,
    phone: string,
    rawRefreshToken: string,
  ): Promise<Pick<AuthTokens, 'accessToken' | 'refreshToken'>> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, phone: true, status: true, refresh_token: true },
    });

    if (!user || !user.refresh_token) {
      throw new UnauthorizedException(
        'Session expirée, veuillez vous reconnecter',
      );
    }

    if (user.status === 'BLOCKED' || user.status === 'SUSPENDED') {
      throw new ForbiddenException('Accès refusé');
    }

    const tokenMatch = await bcrypt.compare(
      rawRefreshToken,
      user.refresh_token,
    );
    if (!tokenMatch) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { refresh_token: null },
      });
      throw new UnauthorizedException(
        'Token invalide. Session révoquée par sécurité.',
      );
    }

    const role = await this.determineUserRole(user.id);
    const tokens = await this.generateTokens(user.id, phone, role);
    await this.storeRefreshToken(user.id, tokens.refreshToken);

    return tokens;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  async logout(userId: string): Promise<void> {
    await this.prisma.user.update({
      where: { id: userId },
      data: { refresh_token: null },
    });
  }

  // ── Get Profile ────────────────────────────────────────────────────────────

  async getProfile(userId: string): Promise<AuthUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: USER_PUBLIC_SELECT,
    });

    if (!user) {
      throw new UnauthorizedException('Utilisateur introuvable');
    }

    return user;
  }

  // ── Update Profile ─────────────────────────────────────────────────────────

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<AuthUser> {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(dto.firstName !== undefined && { firstName: dto.firstName }),
        ...(dto.lastName !== undefined && { lastName: dto.lastName }),
        ...(dto.city !== undefined && { city: dto.city }),
        ...(dto.district !== undefined && { district: dto.district }),
      },
      select: USER_PUBLIC_SELECT,
    });

    return user;
  }

  // ── Change Password ────────────────────────────────────────────────────────

  async changePassword(userId: string, dto: ChangePasswordDto): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, password: true },
    });

    if (!user?.password) {
      throw new BadRequestException(
        'Compte Google sans mot de passe défini — utilisez "Mot de passe oublié" pour en créer un',
      );
    }

    const isMatch = await bcrypt.compare(dto.currentPassword, user.password);
    if (!isMatch) {
      throw new UnauthorizedException('Mot de passe actuel incorrect');
    }

    const isSamePassword = await bcrypt.compare(dto.newPassword, user.password);
    if (isSamePassword) {
      throw new BadRequestException(
        "Le nouveau mot de passe doit être différent de l'actuel",
      );
    }

    const hashed = await bcrypt.hash(dto.newPassword, 10);

    await this.prisma.user.update({
      where: { id: userId },
      data: { password: hashed, refresh_token: null },
    });

    this.logger.log(`[AUTH] Mot de passe modifié pour userId ${userId}`);
  }

  // ── Helpers privés ─────────────────────────────────────────────────────────

  private generateOtp(): string {
    return Math.floor(10000 + Math.random() * 90000).toString();
  }

  private async saveOtp(
    userId: string,
    code: string,
    type: string,
  ): Promise<void> {
    const hashed = await bcrypt.hash(code, 10);
    const expiry = new Date(Date.now() + 5 * 60 * 1000); // +5 minutes

    await this.prisma.user.update({
      where: { id: userId },
      data: { otpCode: hashed, otpExpiry: expiry, otpType: type },
    });
  }

  private async verifyOtp(
    userId: string,
    code: string,
    type: string,
  ): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { otpCode: true, otpExpiry: true, otpType: true },
    });

    if (!user?.otpCode || !user.otpExpiry || user.otpType !== type) {
      return false;
    }

    if (new Date() > user.otpExpiry) {
      this.logger.warn(`OTP expiré pour user ${userId}`);
      return false;
    }

    const matches = await bcrypt.compare(code, user.otpCode);

    if (matches) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { otpCode: null, otpExpiry: null, otpType: null },
      });
    }

    return matches;
  }

  private async determineUserRole(userId: string): Promise<UserRole> {
    const [admin, imfStaff, agent, investor, borrower] = await Promise.all([
      this.prisma.admin.findUnique({
        where: { id: userId },
        select: { id: true },
      }),
      this.prisma.imfStaff.findUnique({
        where: { id: userId },
        select: { id: true },
      }),
      this.prisma.agent.findUnique({
        where: { id: userId },
        select: { id: true },
      }),
      this.prisma.investor.findUnique({
        where: { id: userId },
        select: { id: true },
      }),
      this.prisma.borrower.findUnique({
        where: { id: userId },
        select: { id: true },
      }),
    ]);
    if (admin) return 'admin';
    if (imfStaff) return 'imf_staff';
    if (agent) return 'agent';
    if (investor) return 'investor';
    if (borrower) return 'borrower';
    return 'user';
  }

  private async generateTokens(
    userId: string,
    phone: string,
    role: UserRole,
  ): Promise<Pick<AuthTokens, 'accessToken' | 'refreshToken'>> {
    const payload: JwtPayload = { sub: userId, phone, role };

    type Expiry = JwtSignOptions['expiresIn'];
    const accessExpiry = (this.config.get('JWT_EXPIRES_IN') ?? '7d') as Expiry;
    const refreshExpiry = (this.config.get('JWT_REFRESH_EXPIRES_IN') ??
      '30d') as Expiry;

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.config.getOrThrow<string>('JWT_SECRET'),
        expiresIn: accessExpiry,
      }),
      this.jwtService.signAsync(payload, {
        secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
        expiresIn: refreshExpiry,
      }),
    ]);

    return { accessToken, refreshToken };
  }

  private async storeRefreshToken(
    userId: string,
    rawToken: string,
  ): Promise<void> {
    const hashed = await bcrypt.hash(rawToken, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { refresh_token: hashed },
    });
  }

  private async buildAuthResponse(
    userId: string,
    phone: string,
  ): Promise<AuthTokens> {
    const role = await this.determineUserRole(userId);
    const tokens = await this.generateTokens(userId, phone, role);
    await this.storeRefreshToken(userId, tokens.refreshToken);
    await this.prisma.user.update({
      where: { id: userId },
      data: { last_login: new Date() },
    });

    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: USER_PUBLIC_SELECT,
    });

    return { ...tokens, user };
  }
}
