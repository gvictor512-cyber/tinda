import { Repository } from 'typeorm';
import { Verification } from './entities/verification.entity';
import { User } from '../users/entities/user.entity';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { VerifyPhoneDto } from './dto/verify-phone.dto';
import { VerifySelfieDto } from './dto/verify-selfie.dto';
export declare class VerificationService {
    private verificationRepository;
    private usersRepository;
    constructor(verificationRepository: Repository<Verification>, usersRepository: Repository<User>);
    getVerificationStatus(firebaseUid: string): Promise<{
        isVerified: boolean;
        verificationLevel: string;
        emailVerified: boolean;
        phoneVerified: boolean;
        selfieVerified: boolean;
        documentVerified: boolean;
    }>;
    verifyEmail(firebaseUid: string, verifyEmailDto: VerifyEmailDto): Promise<{
        success: boolean;
        message: string;
    }>;
    verifyPhone(firebaseUid: string, verifyPhoneDto: VerifyPhoneDto): Promise<{
        success: boolean;
        message: string;
    }>;
    verifySelfie(firebaseUid: string, verifySelfieDto: VerifySelfieDto): Promise<{
        success: boolean;
        message: string;
    }>;
    verifyDocument(firebaseUid: string, documentUrl: string): Promise<{
        success: boolean;
        message: string;
    }>;
    private updateOverallVerification;
}
