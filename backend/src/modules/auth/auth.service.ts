import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as admin from 'firebase-admin';
import { User } from '../users/entities/user.entity';
import { FirebaseAuthDto } from './dto/firebase-auth.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    private jwtService: JwtService,
  ) {
    // Initialize Firebase Admin SDK
    if (!admin.apps.length) {
      const serviceAccount = {
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      };

      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
  }

  async authenticateWithFirebase(firebaseAuthDto: FirebaseAuthDto) {
    try {
      const decodedToken = await admin.auth().verifyIdToken(firebaseAuthDto.token);
      
      let user = await this.usersRepository.findOne({
        where: { firebaseUid: decodedToken.uid },
      });

      if (!user) {
        const newUser = this.usersRepository.create({
          firebaseUid: decodedToken.uid,
          email: decodedToken.email,
          isActive: true,
        });
        user = await this.usersRepository.save(newUser);
      }

      const tokens = await this.generateTokens(user);

      return {
        user: this.sanitizeUser(user),
        ...tokens,
      };
    } catch (error) {
      throw new UnauthorizedException('Invalid Firebase token');
    }
  }

  async register(registerDto: RegisterDto) {
    try {
      const existingUser = await this.usersRepository.findOne({
        where: { email: registerDto.email },
      });

      if (existingUser) {
        throw new ConflictException('User already exists');
      }

      const newUser = this.usersRepository.create({
        email: registerDto.email,
        phone: registerDto.phone,
        isActive: true,
      });

      const savedUser = await this.usersRepository.save(newUser);

      const tokens = await this.generateTokens(savedUser);

      return {
        user: this.sanitizeUser(savedUser),
        ...tokens,
      };
    } catch (error) {
      throw new ConflictException('Registration failed');
    }
  }

  async login(firebaseAuthDto: FirebaseAuthDto) {
    return this.authenticateWithFirebase(firebaseAuthDto);
  }

  async getCurrentUser(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    return this.sanitizeUser(user);
  }

  async refreshToken(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken);
      const user = await this.usersRepository.findOne({
        where: { id: payload.sub },
      });

      if (!user) {
        throw new UnauthorizedException('User not found');
      }

      return this.generateTokens(user);
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async logout(firebaseUid: string) {
    // Revoke Firebase token
    await admin.auth().revokeRefreshTokens(firebaseUid);
    return { message: 'Logged out successfully' };
  }

  private async generateTokens(user: User) {
    const payload = {
      sub: user.id,
      email: user.email,
      firebaseUid: user.firebaseUid,
    };

    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, {
      expiresIn: '30d',
    });

    return {
      accessToken,
      refreshToken,
      tokenType: 'Bearer',
    };
  }

  private sanitizeUser(user: User) {
    const { id, email, phone, isActive, isPremium, premiumExpiresAt, createdAt } = user;
    return {
      id,
      email,
      phone,
      isActive,
      isPremium,
      premiumExpiresAt,
      createdAt,
    };
  }
}
