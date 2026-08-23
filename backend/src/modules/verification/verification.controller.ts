import { Controller, Get, Post, Body, UseGuards, Request, HttpCode, HttpStatus } from '@nestjs/common';
import { VerificationService } from './verification.service';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { VerifyPhoneDto } from './dto/verify-phone.dto';
import { VerifySelfieDto } from './dto/verify-selfie.dto';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';

@Controller('verification')
@UseGuards(FirebaseAuthGuard)
export class VerificationController {
  constructor(private readonly verificationService: VerificationService) {}

  @Get('status')
  async getVerificationStatus(@Request() req) {
    return this.verificationService.getVerificationStatus(req.user.uid);
  }

  @Post('email')
  @HttpCode(HttpStatus.OK)
  async verifyEmail(@Request() req, @Body() verifyEmailDto: VerifyEmailDto) {
    return this.verificationService.verifyEmail(req.user.uid, verifyEmailDto);
  }

  @Post('phone')
  @HttpCode(HttpStatus.OK)
  async verifyPhone(@Request() req, @Body() verifyPhoneDto: VerifyPhoneDto) {
    return this.verificationService.verifyPhone(req.user.uid, verifyPhoneDto);
  }

  @Post('selfie')
  @HttpCode(HttpStatus.OK)
  async verifySelfie(@Request() req, @Body() verifySelfieDto: VerifySelfieDto) {
    return this.verificationService.verifySelfie(req.user.uid, verifySelfieDto);
  }

  @Post('document')
  @HttpCode(HttpStatus.OK)
  async verifyDocument(@Request() req, @Body('documentUrl') documentUrl: string) {
    return this.verificationService.verifyDocument(req.user.uid, documentUrl);
  }

  @Post('approve')
  @HttpCode(HttpStatus.OK)
  async approveVerification(@Body('firebaseUid') firebaseUid: string) {
    return this.verificationService.approveVerification(firebaseUid);
  }
}
