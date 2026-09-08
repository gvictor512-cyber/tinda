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
      const decodedToken = await admin.auth().verifyIdToken(token, true);
      const dbUser = await this.usersRepository.findOne({
        where: { firebaseUid: decodedToken.uid },
      });

      if (decodedToken.exp * 1000 < Date.now()) {
        throw new UnauthorizedException('Token expired');
      }

      return {
        uid: decodedToken.uid,
        email: decodedToken.email,
        emailVerified: decodedToken.email_verified,
        role: dbUser?.role ?? 'user',
      };
    } catch (error) {
      throw new UnauthorizedException('Invalid or expired Firebase token');
    }
  }

  private extractTokenFromHeader(req: any): string | undefined {
    const [type, token] = req.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}
