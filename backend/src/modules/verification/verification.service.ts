import { Injectable, NotFoundException, BadRequestException, NotImplementedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as admin from 'firebase-admin';
import { Verification } from './entities/verification.entity';
import { User } from '../users/entities/user.entity';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { VerifyPhoneDto } from './dto/verify-phone.dto';
import { VerifySelfieDto } from './dto/verify-selfie.dto';

@Injectable()
export class VerificationService {
  constructor(
    @InjectRepository(Verification)
    private verificationRepository: Repository<Verification>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async getVerificationStatus(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    let verification = await this.verificationRepository.findOne({
      where: { userId: user.id },
    });

    if (!verification) {
      verification = this.verificationRepository.create({
        userId: user.id,
        emailVerified: false,
        phoneVerified: false,
        selfieVerified: false,
        documentVerified: false,
        isVerified: false,
        verificationLevel: 'basic',
      });
      await this.verificationRepository.save(verification);
    }

    return {
      isVerified: verification.isVerified,
      verificationLevel: verification.verificationLevel,
      emailVerified: verification.emailVerified,
      phoneVerified: verification.phoneVerified,
      selfieVerified: verification.selfieVerified,
      documentVerified: verification.documentVerified,
    };
  }

  async verifyEmail(firebaseUid: string, verifyEmailDto: VerifyEmailDto) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const firebaseUser = await admin.auth().getUser(firebaseUid);
    if (!firebaseUser.emailVerified) {
      throw new BadRequestException('Email not verified in Firebase');
    }
    
    let verification = await this.verificationRepository.findOne({
      where: { userId: user.id },
    });

    if (!verification) {
      verification = this.verificationRepository.create({
        userId: user.id,
      });
    }

    verification.emailVerified = true;
    verification.emailVerifiedAt = new Date();
    verification.verificationLevel = 'standard';
    
    await this.verificationRepository.save(verification);

    // Update overall verification status
    await this.updateOverallVerification(verification);

    return { success: true, message: 'Email verified successfully' };
  }

  async verifyPhone(firebaseUid: string, verifyPhoneDto: VerifyPhoneDto) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    throw new NotImplementedException(
      'SMS verification is not configured. Configure a provider (Twilio, Vonage, etc.) before enabling this endpoint.',
    );
  }

  async verifySelfie(firebaseUid: string, verifySelfieDto: VerifySelfieDto) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    let verification = await this.verificationRepository.findOne({
      where: { userId: user.id },
    });

    if (!verification) {
      verification = this.verificationRepository.create({
        userId: user.id,
      });
    }

    verification.selfieUrl = verifySelfieDto.selfieUrl;
    verification.selfieSubmittedAt = new Date();
    verification.selfieVerified = false;
    verification.verificationLevel = 'pending_review';
    
    await this.verificationRepository.save(verification);

    // Update overall verification status
    await this.updateOverallVerification(verification);

    return { success: true, message: 'Selfie submitted for manual review' };
  }

  async verifyDocument(firebaseUid: string, documentUrl: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    let verification = await this.verificationRepository.findOne({
      where: { userId: user.id },
    });

    if (!verification) {
      verification = this.verificationRepository.create({
        userId: user.id,
      });
    }

    verification.documentVerified = false;
    verification.documentUrl = documentUrl;
    verification.verificationLevel = 'pending_review';
    
    await this.verificationRepository.save(verification);

    // Update overall verification status
    await this.updateOverallVerification(verification);

    return { success: true, message: 'Document submitted for manual review' };
  }

  async approveVerification(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    let verification = await this.verificationRepository.findOne({
      where: { userId: user.id },
    });

    if (!verification) {
      throw new NotFoundException('Verification not found');
    }

    verification.selfieVerified = true;
    verification.selfieVerifiedAt = new Date();
    verification.documentVerified = true;
    verification.documentVerifiedAt = new Date();

    await this.verificationRepository.save(verification);

    // Update overall verification status
    await this.updateOverallVerification(verification);

    return { success: true, message: 'Verification approved manually' };
  }

  private async updateOverallVerification(verification: Verification) {
    // Determine overall verification status based on completed verifications
    const verificationsCompleted = [
      verification.emailVerified,
      verification.phoneVerified,
      verification.selfieVerified,
      verification.documentVerified,
    ].filter(Boolean).length;

    if (verificationsCompleted >= 3) {
      verification.isVerified = true;
      verification.verificationLevel = 'advanced';
    } else if (verificationsCompleted >= 2) {
      verification.isVerified = true;
      verification.verificationLevel = 'standard';
    } else if (verificationsCompleted >= 1) {
      verification.isVerified = false;
      verification.verificationLevel = 'basic';
    } else {
      verification.isVerified = false;
      verification.verificationLevel = 'basic';
    }

    await this.verificationRepository.save(verification);
  }
}
