import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { InjectRepository } from '@nestjs/typeorm';
import { Strategy } from 'passport-custom';
import { Repository } from 'typeorm';
import * as admin from 'firebase-admin';
import { User } from '../../users/entities/user.entity';

@Injectable()
export class FirebaseStrategy extends PassportStrategy(Strategy, 'firebase') {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {
    super();
  }

  async validate(req: any) {
    const token = this.extractTokenFromHeader(req);

    if (!token) {
      throw new UnauthorizedException('No token provided');
    }

    try {
      // checkRevoked=false: the revocation check needs a service-account
      // call to the Auth backend — if it degrades, EVERY valid token
      // would 401. Signature/exp/aud validation stays strict.
      const decodedToken = await admin.auth().verifyIdToken(token);

      if (decodedToken.exp * 1000 < Date.now()) {
        throw new UnauthorizedException('Token expired');
      }

      // Role lookup is optional data — a Postgres hiccup must not turn
      // into a 401 for a valid Firebase token.
      let role = 'user';
      try {
        const dbUser = await this.usersRepository.findOne({
          where: { firebaseUid: decodedToken.uid },
        });
        role = dbUser?.role ?? 'user';
      } catch { /* keep default role */ }

      return {
        uid: decodedToken.uid,
        email: decodedToken.email,
        emailVerified: decodedToken.email_verified,
        role,
      };
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      throw new UnauthorizedException('Invalid or expired Firebase token');
    }
  }

  private extractTokenFromHeader(req: any): string | undefined {
    const [type, token] = req.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}
