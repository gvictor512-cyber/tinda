import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DailyLimits } from './entities/daily-limits.entity';
import { User } from '../users/entities/user.entity';

@Injectable()
export class DailyLimitsService {
  constructor(
    @InjectRepository(DailyLimits)
    private dailyLimitsRepository: Repository<DailyLimits>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async getDailyLimits(userId: string) {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
    });

    if (!user) {
      throw new Error('User not found');
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let dailyLimits = await this.dailyLimitsRepository.findOne({
      where: { userId, date: today },
    });

    if (!dailyLimits) {
      dailyLimits = this.dailyLimitsRepository.create({
        userId,
        date: today,
        likesUsed: 0,
        superLikesUsed: 0,
        boostsUsed: 0,
      });
      await this.dailyLimitsRepository.save(dailyLimits);
    }

    const isPremium = user.isPremium && (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());

    return {
      isPremium,
      likesUsed: dailyLimits.likesUsed,
      likesRemaining: isPremium ? -1 : 10 - dailyLimits.likesUsed,
      superLikesUsed: dailyLimits.superLikesUsed,
      superLikesRemaining: isPremium ? -1 : 1 - dailyLimits.superLikesUsed,
      boostsUsed: dailyLimits.boostsUsed,
      boostsRemaining: isPremium ? -1 : 0,
    };
  }

  async incrementLikes(userId: string) {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
    });

    const isPremium = user.isPremium && (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());

    if (isPremium) {
      return { success: true, remaining: -1 };
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let dailyLimits = await this.dailyLimitsRepository.findOne({
      where: { userId, date: today },
    });

    if (!dailyLimits) {
      dailyLimits = this.dailyLimitsRepository.create({
        userId,
        date: today,
        likesUsed: 0,
        superLikesUsed: 0,
        boostsUsed: 0,
      });
    }

    if (dailyLimits.likesUsed >= 10) {
      return { success: false, remaining: 0 };
    }

    dailyLimits.likesUsed++;
    await this.dailyLimitsRepository.save(dailyLimits);

    return { success: true, remaining: 10 - dailyLimits.likesUsed };
  }

  async incrementSuperLikes(userId: string) {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
    });

    const isPremium = user.isPremium && (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());

    if (isPremium) {
      return { success: true, remaining: -1 };
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let dailyLimits = await this.dailyLimitsRepository.findOne({
      where: { userId, date: today },
    });

    if (!dailyLimits) {
      dailyLimits = this.dailyLimitsRepository.create({
        userId,
        date: today,
        likesUsed: 0,
        superLikesUsed: 0,
        boostsUsed: 0,
      });
    }

    if (dailyLimits.superLikesUsed >= 1) {
      return { success: false, remaining: 0 };
    }

    dailyLimits.superLikesUsed++;
    await this.dailyLimitsRepository.save(dailyLimits);

    return { success: true, remaining: 1 - dailyLimits.superLikesUsed };
  }

  async resetDailyLimits() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // This would be called by a scheduled job daily
    const expiredLimits = await this.dailyLimitsRepository
      .createQueryBuilder('limits')
      .where('limits.date < :today', { today })
      .getMany();

    // Archive or delete old limits
    for (const limit of expiredLimits) {
      await this.dailyLimitsRepository.remove(limit);
    }

    return { success: true };
  }
}
