import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PremiumController } from './premium.controller';
import { PremiumService } from './premium.service';
import { Subscription } from './entities/subscription.entity';
import { User } from '../users/entities/user.entity';
import { DailyLimits } from '../daily-limits/entities/daily-limits.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Subscription, User, DailyLimits]),
  ],
  controllers: [PremiumController],
  providers: [PremiumService],
  exports: [PremiumService],
})
export class PremiumModule {}
