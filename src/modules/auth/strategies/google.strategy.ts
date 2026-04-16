import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, Profile } from 'passport-google-oauth20';
import type { GoogleProfile } from '@modules/auth/auth.types';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(configService: ConfigService) {
    super({
      clientID: configService.getOrThrow<string>('GOOGLE_CLIENT_ID'),
      clientSecret: configService.getOrThrow<string>('GOOGLE_CLIENT_SECRET'),
      callbackURL: configService.getOrThrow<string>('GOOGLE_CALLBACK_URL'),
      scope: ['email', 'profile'],
    });
  }

  validate(
    _accessToken: string,
    _refreshToken: string,
    profile: Profile,
  ): GoogleProfile {
    return {
      googleId: profile.id,
      email: profile.emails?.[0]?.value ?? null,
      firstName: profile.name?.givenName ?? profile.displayName.split(' ')[0] ?? '',
      lastName: profile.name?.familyName ?? profile.displayName.split(' ')[1] ?? '',
      avatar: profile.photos?.[0]?.value ?? null,
    };
  }
}
