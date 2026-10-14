import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as admin from 'firebase-admin';
import { Subscription } from './entities/subscription.entity';
import { User } from '../users/entities/user.entity';
import { DailyLimits } from '../daily-limits/entities/daily-limits.entity';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';

@Injectable()
export class PremiumService {
  private readonly logger = new Logger(PremiumService.name);

  constructor(
    @InjectRepository(Subscription)
    private subscriptionsRepository: Repository<Subscription>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(DailyLimits)
    private dailyLimitsRepository: Repository<DailyLimits>,
  ) {}

  async getPremiumStatus(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const subscription = await this.subscriptionsRepository.findOne({
      where: { userId: user.id, isActive: true },
    });

    return {
      isPremium: user.isPremium,
      premiumExpiresAt: user.premiumExpiresAt,
      subscription: subscription
        ? {
            planType: subscription.planType,
            startDate: subscription.startDate,
            endDate: subscription.endDate,
            autoRenew: subscription.autoRenew,
          }
        : null,
    };
  }

  async getPremiumFeatures() {
    return {
      free: {
        dailyLikes: 10,
        dailySuperLikes: 1,
        filters: ['basic'],
        seeWhoLikedYou: false,
        profileBoost: false,
        invisibleMode: false,
      },
      premium: {
        dailyLikes: -1, // unlimited
        dailySuperLikes: -1, // unlimited
        filters: ['advanced'],
        seeWhoLikedYou: true,
        profileBoost: true,
        invisibleMode: true,
      },
    };
  }

  async createSubscription(
    firebaseUid: string,
    createSubscriptionDto: CreateSubscriptionDto,
  ) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check if user already has active subscription
    const existingSubscription = await this.subscriptionsRepository.findOne({
      where: { userId: user.id, isActive: true },
    });

    if (existingSubscription) {
      throw new BadRequestException('User already has an active subscription');
    }

    // SECURITY: never grant premium from a bare API call. This endpoint only
    // mirrors into Postgres an entitlement that was already granted through
    // the verified IAP/Stripe flows, which write subscriptions/{uid} and
    // users/{uid} in Firestore. Without that proof this endpoint is a dev
    // stub — reject it in production.
    const fsSub = await admin
      .firestore()
      .collection('subscriptions')
      .doc(firebaseUid)
      .get();
    const fsSubData = fsSub.data();
    const hasVerifiedEntitlement =
      fsSub.exists &&
      fsSubData?.isActive === true &&
      typeof fsSubData?.endDate === 'number' &&
      fsSubData.endDate > Date.now();

    if (!hasVerifiedEntitlement) {
      if (process.env.NODE_ENV === 'production') {
        throw new ForbiddenException(
          'No verified purchase found. Subscribe through the app store.',
        );
      }
      this.logger.warn(
        `Dev-mode subscription grant without verified purchase for ${firebaseUid}`,
      );
    }

    // Calculate end date based on plan
    const startDate = new Date();
    const endDate = new Date();

    if (createSubscriptionDto.planType === 'premium_monthly') {
      endDate.setMonth(endDate.getMonth() + 1);
    } else if (createSubscriptionDto.planType === 'premium_yearly') {
      endDate.setFullYear(endDate.getFullYear() + 1);
    }

    // Create subscription
    const subscription = this.subscriptionsRepository.create({
      userId: user.id,
      planType: createSubscriptionDto.planType,
      startDate,
      endDate,
      isActive: true,
      autoRenew: createSubscriptionDto.autoRenew ?? false,
      paymentMethod: createSubscriptionDto.paymentMethod,
    });

    await this.subscriptionsRepository.save(subscription);

    // Update user premium status
    user.isPremium = true;
    user.premiumExpiresAt = endDate;
    await this.usersRepository.save(user);

    return {
      success: true,
      subscription,
      premiumExpiresAt: endDate,
    };
  }

  async cancelSubscription(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const subscription = await this.subscriptionsRepository.findOne({
      where: { userId: user.id, isActive: true },
    });

    if (!subscription) {
      throw new BadRequestException('No active subscription found');
    }

    subscription.isActive = false;
    subscription.autoRenew = false;
    await this.subscriptionsRepository.save(subscription);

    // Keep user premium until end date
    return { success: true, message: 'Subscription cancelled' };
  }

  async getDailyLimits(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let dailyLimits = await this.dailyLimitsRepository.findOne({
      where: { userId: user.id, date: today },
    });

    if (!dailyLimits) {
      dailyLimits = this.dailyLimitsRepository.create({
        userId: user.id,
        date: today,
        likesUsed: 0,
        superLikesUsed: 0,
        boostsUsed: 0,
      });
      await this.dailyLimitsRepository.save(dailyLimits);
    }

    const isPremium =
      user.isPremium &&
      (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());

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

  async useLike(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isPremium =
      user.isPremium &&
      (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());

    if (isPremium) {
      return { success: true, remaining: -1 };
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let dailyLimits = await this.dailyLimitsRepository.findOne({
      where: { userId: user.id, date: today },
    });

    if (!dailyLimits) {
      dailyLimits = this.dailyLimitsRepository.create({
        userId: user.id,
        date: today,
        likesUsed: 0,
        superLikesUsed: 0,
        boostsUsed: 0,
      });
    }

    if (dailyLimits.likesUsed >= 10) {
      throw new BadRequestException('Daily like limit reached');
    }

    dailyLimits.likesUsed++;
    await this.dailyLimitsRepository.save(dailyLimits);

    return { success: true, remaining: 10 - dailyLimits.likesUsed };
  }

  async useSuperLike(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isPremium =
      user.isPremium &&
      (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());

    if (isPremium) {
      return { success: true, remaining: -1 };
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let dailyLimits = await this.dailyLimitsRepository.findOne({
      where: { userId: user.id, date: today },
    });

    if (!dailyLimits) {
      dailyLimits = this.dailyLimitsRepository.create({
        userId: user.id,
        date: today,
        likesUsed: 0,
        superLikesUsed: 0,
        boostsUsed: 0,
      });
    }

    if (dailyLimits.superLikesUsed >= 1) {
      throw new BadRequestException('Daily super like limit reached');
    }

    dailyLimits.superLikesUsed++;
    await this.dailyLimitsRepository.save(dailyLimits);

    return { success: true, remaining: 1 - dailyLimits.superLikesUsed };
  }

  async boostProfile(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isPremium =
      user.isPremium &&
      (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());

    if (!isPremium) {
      throw new BadRequestException('Boost is a premium feature');
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let dailyLimits = await this.dailyLimitsRepository.findOne({
      where: { userId: user.id, date: today },
    });

    if (!dailyLimits) {
      dailyLimits = this.dailyLimitsRepository.create({
        userId: user.id,
        date: today,
        likesUsed: 0,
        superLikesUsed: 0,
        boostsUsed: 0,
      });
    }

    dailyLimits.boostsUsed++;
    await this.dailyLimitsRepository.save(dailyLimits);

    // TODO: Implement boost logic (show profile to more users for 30 minutes)

    return { success: true, message: 'Profile boosted for 30 minutes' };
  }
}
