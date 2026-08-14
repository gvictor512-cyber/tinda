import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DailyLimitsService } from './daily-limits.service';
import { DailyLimits } from './entities/daily-limits.entity';
import { User } from '../users/entities/user.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([DailyLimits, User]),
  ],
  providers: [DailyLimitsService],
  exports: [DailyLimitsService],
})
export class DailyLimitsModule {}
