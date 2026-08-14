import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';
import { User } from '../users/entities/user.entity';
import { Payment } from './entities/payment.entity';
import { UserCancellation } from './entities/user-cancellation.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, Payment, UserCancellation])],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
