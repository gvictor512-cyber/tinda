import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { VerificationController } from './verification.controller';
import { VerificationService } from './verification.service';
import { Verification } from './entities/verification.entity';
import { User } from '../users/entities/user.entity';
import { VeriffService } from '../../common/services/veriff.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Verification, User]),
  ],
  controllers: [VerificationController],
  providers: [VerificationService, VeriffService],
  exports: [VerificationService],
})
export class VerificationModule {}
