import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { ROLES_KEY, type AppRole } from '@shared/decorators/roles.decorator';
import type { JwtPayload } from '@modules/auth/auth.types';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<AppRole[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles?.length) return true;

    const request = context
      .switchToHttp()
      .getRequest<Request & { user: JwtPayload }>();

    const userRole = request.user?.role;
    if (!userRole) throw new ForbiddenException('Accès refusé');

    if (!requiredRoles.some((r) => r === userRole)) {
      throw new ForbiddenException('Rôle insuffisant pour cette action');
    }

    return true;
  }
}
