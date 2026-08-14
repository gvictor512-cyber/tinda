import { VerificationService } from './verification.service';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { VerifyPhoneDto } from './dto/verify-phone.dto';
import { VerifySelfieDto } from './dto/verify-selfie.dto';
export declare class VerificationController {
    private readonly verificationService;
    constructor(verificationService: VerificationService);
    getVerificationStatus(req: any): Promise<{
        isVerified: boolean;
        verificationLevel: string;
        emailVerified: boolean;
        phoneVerified: boolean;
        selfieVerified: boolean;
        documentVerified: boolean;
    }>;
    verifyEmail(req: any, verifyEmailDto: VerifyEmailDto): Promise<{
        success: boolean;
        message: string;
    }>;
    verifyPhone(req: any, verifyPhoneDto: VerifyPhoneDto): Promise<{
        success: boolean;
        message: string;
    }>;
    verifySelfie(req: any, verifySelfieDto: VerifySelfieDto): Promise<{
        success: boolean;
        message: string;
    }>;
    verifyDocument(req: any, documentUrl: string): Promise<{
        success: boolean;
        message: string;
    }>;
}
