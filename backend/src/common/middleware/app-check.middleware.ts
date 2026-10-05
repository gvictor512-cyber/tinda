import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { admin } from '../config/firebase.config';

/**
 * Verifies the X-Firebase-AppCheck token when APP_CHECK_ENABLED=true.
 * In development or when the env var is unset the check is skipped so
 * the API keeps working for web clients without App Check.
 */
@Injectable()
export class AppCheckMiddleware implements NestMiddleware {
  async use(req: Request, _res: Response, next: NextFunction) {
    if (process.env.APP_CHECK_ENABLED !== 'true') {
      return next();
    }

    const token = req.headers['x-firebase-appcheck'] as string | undefined;
    if (!token) {
      throw new UnauthorizedException('Missing App Check token');
    }

    try {
      await admin.appCheck().verifyToken(token);
      next();
    } catch {
      throw new UnauthorizedException('Invalid App Check token');
    }
  }
}
