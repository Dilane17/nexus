import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
  Req,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiOkResponse,
  ApiCreatedResponse,
  ApiUnauthorizedResponse,
  ApiForbiddenResponse,
  ApiBadRequestResponse,
  ApiConflictResponse,
  ApiBody,
} from '@nestjs/swagger';
import type { Request } from 'express';
import { AuthService } from './auth.service';
import { loginSchema, LoginDtoDoc } from './dto/login.dto';
import { refreshSchema, RefreshDtoDoc } from './dto/refresh.dto';
import { registerSchema, RegisterDtoDoc } from './dto/register.dto';
import { updateProfileSchema, UpdateProfileDtoDoc } from './dto/update-profile.dto';
import { verifyEmailSchema, VerifyEmailDtoDoc } from './dto/verify-otp.dto';
import { resendOtpSchema, ResendOtpDtoDoc } from './dto/resend-otp.dto';
import { forgotPasswordSchema, ForgotPasswordDtoDoc } from './dto/forgot-password.dto';
import { resetPasswordSchema, ResetPasswordDtoDoc } from './dto/reset-password.dto';
import { changePasswordSchema, ChangePasswordDtoDoc } from './dto/change-password.dto';
import { googleMobileSchema, GoogleMobileDtoDoc } from './dto/google-mobile.dto';
import type { ChangePasswordDto } from './dto/change-password.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RefreshAuthGuard } from './guards/refresh-auth.guard';
import { GoogleAuthGuard } from './guards/google-auth.guard';
import { ZodValidationPipe } from '@shared/pipes/zod-validation.pipe';
import { CurrentUser } from '@shared/decorators/current-user.decorator';
import type { LoginDto } from './dto/login.dto';
import type { RegisterDto } from './dto/register.dto';
import type { UpdateProfileDto } from './dto/update-profile.dto';
import type { VerifyEmailDto } from './dto/verify-otp.dto';
import type { ResendOtpDto } from './dto/resend-otp.dto';
import type { ForgotPasswordDto } from './dto/forgot-password.dto';
import type { ResetPasswordDto } from './dto/reset-password.dto';
import type { GoogleMobileDto } from './dto/google-mobile.dto';
import type {
  JwtPayload,
  ApiResponse,
  AuthTokens,
  AuthUser,
  GoogleProfile,
  GoogleLoginResult,
} from './auth.types';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // ── POST /auth/register ────────────────────────────────────────────────────

  @Post('register')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Inscription',
    description: 'Crée un compte et envoie un code OTP par email pour vérification',
  })
  @ApiBody({ type: RegisterDtoDoc })
  @ApiCreatedResponse({ description: 'Compte créé, OTP envoyé par email' })
  @ApiConflictResponse({ description: 'Email déjà utilisé' })
  @ApiBadRequestResponse({ description: 'Données invalides' })
  async register(
    @Body(new ZodValidationPipe(registerSchema)) dto: RegisterDto,
  ): Promise<ApiResponse<{ message: string }>> {
    const data = await this.authService.register(dto);
    return { success: true, data, message: data.message };
  }

  // ── POST /auth/verify-email ────────────────────────────────────────────────

  @Post('verify-email')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Vérification OTP email',
    description: 'Valide le code reçu par email et active le compte (inscription + Google OAuth)',
  })
  @ApiBody({ type: VerifyEmailDtoDoc })
  @ApiOkResponse({ description: 'Email vérifié, tokens retournés' })
  @ApiUnauthorizedResponse({ description: 'Code invalide ou expiré' })
  async verifyEmail(
    @Body(new ZodValidationPipe(verifyEmailSchema)) dto: VerifyEmailDto,
  ): Promise<ApiResponse<AuthTokens>> {
    const data = await this.authService.verifyEmail(dto);
    return { success: true, data, message: 'Email vérifié — compte activé' };
  }

  // ── POST /auth/login ───────────────────────────────────────────────────────

  @Post('login')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Connexion',
    description: 'Retourne un access token (7j) et un refresh token (30j). Requiert isEmailVerified = true.',
  })
  @ApiBody({ type: LoginDtoDoc })
  @ApiOkResponse({ description: 'Connexion réussie' })
  @ApiUnauthorizedResponse({ description: 'Identifiants incorrects ou email non vérifié' })
  @ApiForbiddenResponse({ description: 'Compte bloqué ou suspendu' })
  async login(
    @Body(new ZodValidationPipe(loginSchema)) dto: LoginDto,
  ): Promise<ApiResponse<AuthTokens>> {
    const data = await this.authService.login(dto);
    return { success: true, data, message: 'Connexion réussie' };
  }

  // ── POST /auth/resend-otp ──────────────────────────────────────────────────

  @Post('resend-otp')
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Renvoyer OTP',
    description: 'Renvoie le code OTP par email',
  })
  @ApiBody({ type: ResendOtpDtoDoc })
  @ApiOkResponse({ description: 'Code renvoyé' })
  @ApiBadRequestResponse({ description: 'Email déjà vérifié ou invalide' })
  async resendOtp(
    @Body(new ZodValidationPipe(resendOtpSchema)) dto: ResendOtpDto,
  ): Promise<ApiResponse<{ message: string }>> {
    const data = await this.authService.resendOtp(dto);
    return { success: true, data, message: data.message };
  }

  // ── POST /auth/forgot-password ────────────────────────────────────────────

  @Post('forgot-password')
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Mot de passe oublié',
    description: 'Envoie un OTP par email. Réponse toujours générique pour la sécurité.',
  })
  @ApiBody({ type: ForgotPasswordDtoDoc })
  @ApiOkResponse({ description: 'Code envoyé (ou message générique si email inconnu)' })
  @ApiForbiddenResponse({ description: 'Compte bloqué' })
  async forgotPassword(
    @Body(new ZodValidationPipe(forgotPasswordSchema)) dto: ForgotPasswordDto,
  ): Promise<ApiResponse<{ message: string }>> {
    const data = await this.authService.forgotPassword(dto);
    return { success: true, data, message: data.message };
  }

  // ── POST /auth/reset-password ──────────────────────────────────────────────

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Réinitialiser le mot de passe',
    description: "Valide l'OTP reçu par email et définit le nouveau mot de passe.",
  })
  @ApiBody({ type: ResetPasswordDtoDoc })
  @ApiOkResponse({ description: 'Mot de passe modifié, sessions révoquées' })
  @ApiUnauthorizedResponse({ description: 'Code invalide ou expiré' })
  async resetPassword(
    @Body(new ZodValidationPipe(resetPasswordSchema)) dto: ResetPasswordDto,
  ): Promise<ApiResponse<{ message: string }>> {
    const data = await this.authService.resetPassword(dto);
    return { success: true, data, message: data.message };
  }

  // ── POST /auth/refresh ─────────────────────────────────────────────────────

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @UseGuards(RefreshAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Renouveler les tokens',
    description: 'Passer le refresh token dans Authorization: Bearer <refresh_token>',
  })
  @ApiBody({ type: RefreshDtoDoc })
  @ApiOkResponse({ description: 'Tokens renouvelés' })
  @ApiUnauthorizedResponse({ description: 'Refresh token invalide ou expiré' })
  async refresh(
    @CurrentUser() user: JwtPayload,
    @Body(new ZodValidationPipe(refreshSchema)) dto: { refreshToken: string },
  ): Promise<ApiResponse<Pick<AuthTokens, 'accessToken' | 'refreshToken'>>> {
    const data = await this.authService.refresh(user.sub, user.email, dto.refreshToken);
    return { success: true, data, message: 'Tokens renouvelés' };
  }

  // ── POST /auth/logout ──────────────────────────────────────────────────────

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Déconnexion', description: 'Révoque le refresh token côté serveur' })
  @ApiOkResponse({ description: 'Déconnexion réussie' })
  async logout(@CurrentUser() user: JwtPayload): Promise<ApiResponse<null>> {
    await this.authService.logout(user.sub);
    return { success: true, data: null, message: 'Déconnexion réussie' };
  }

  // ── GET /auth/me ───────────────────────────────────────────────────────────

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Profil courant' })
  @ApiOkResponse({ description: 'Profil retourné' })
  async getProfile(@CurrentUser() user: JwtPayload): Promise<ApiResponse<AuthUser>> {
    const data = await this.authService.getProfile(user.sub);
    return { success: true, data, message: 'Profil récupéré' };
  }

  // ── PATCH /auth/me ─────────────────────────────────────────────────────────

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Modifier le profil', description: 'Met à jour firstName, lastName, city, district' })
  @ApiBody({ type: UpdateProfileDtoDoc })
  @ApiOkResponse({ description: 'Profil mis à jour' })
  async updateProfile(
    @CurrentUser() user: JwtPayload,
    @Body(new ZodValidationPipe(updateProfileSchema)) dto: UpdateProfileDto,
  ): Promise<ApiResponse<AuthUser>> {
    const data = await this.authService.updateProfile(user.sub, dto);
    return { success: true, data, message: 'Profil mis à jour' };
  }

  // ── PATCH /auth/change-password ────────────────────────────────────────────

  @Patch('change-password')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Changer son mot de passe (utilisateur connecté)' })
  @ApiBody({ type: ChangePasswordDtoDoc })
  async changePassword(
    @CurrentUser() user: JwtPayload,
    @Body(new ZodValidationPipe(changePasswordSchema)) dto: ChangePasswordDto,
  ): Promise<ApiResponse<null>> {
    await this.authService.changePassword(user.sub, dto);
    return { success: true, data: null, message: 'Mot de passe modifié. Reconnectez-vous.' };
  }

  // ── GET /auth/google ───────────────────────────────────────────────────────

  @Get('google')
  @UseGuards(GoogleAuthGuard)
  @ApiOperation({ summary: 'Connexion Google', description: "Redirige vers la page d'authentification Google" })
  googleAuth(): void {}

  @Post('google/mobile')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Connexion Google mobile',
    description: 'Valide un Google ID token envoyé par Flutter et retourne les tokens ou demande une vérification email',
  })
  @ApiBody({ type: GoogleMobileDtoDoc })
  @ApiOkResponse({ description: 'Tokens retournés ou vérification OTP email requise' })
  async googleMobile(
    @Body(new ZodValidationPipe(googleMobileSchema)) dto: GoogleMobileDto,
  ): Promise<ApiResponse<GoogleLoginResult>> {
    const data = await this.authService.googleMobileLogin(dto.idToken);
    const message = data.needsVerification ? 'Vérification email requise' : 'Connexion Google réussie';
    return { success: true, data, message };
  }

  @Get('google/callback')
  @UseGuards(GoogleAuthGuard)
  @ApiOperation({ summary: 'Callback Google OAuth' })
  @ApiOkResponse({ description: 'Tokens retournés ou vérification OTP requise' })
  async googleCallback(
    @Req() req: Request & { user: GoogleProfile },
  ): Promise<ApiResponse<GoogleLoginResult>> {
    const data = await this.authService.googleLogin(req.user);
    const message = data.needsVerification ? 'Vérification email requise' : 'Connexion Google réussie';
    return { success: true, data, message };
  }
}
