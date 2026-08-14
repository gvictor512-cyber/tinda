import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CompatibilitySettings } from './entities/compatibility-settings.entity';
import { Profile } from '../profiles/entities/profile.entity';
import { User } from '../users/entities/user.entity';
import { CompatibilityCalculator } from './algorithm/compatibility-calculator';

export interface CompatibilityResult {
  score: number;
  explanation: string;
  factors: FactorResult[];
}

export interface FactorResult {
  factor: string;
  weight: number;
  score: number;
  contribution: number;
  details: string;
}

@Injectable()
export class CompatibilityService {
  private calculator: CompatibilityCalculator;

  constructor(
    @InjectRepository(CompatibilitySettings)
    private compatibilitySettingsRepository: Repository<CompatibilitySettings>,
    @InjectRepository(Profile)
    private profilesRepository: Repository<Profile>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {
    this.calculator = new CompatibilityCalculator();
  }

  async calculateCompatibility(firebaseUid: string, targetUserId: string): Promise<CompatibilityResult> {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const targetUser = await this.usersRepository.findOne({
      where: { id: targetUserId },
    });

    if (!targetUser) {
      throw new NotFoundException('Target user not found');
    }

    const userSettings = await this.compatibilitySettingsRepository.findOne({
      where: { userId: user.id },
    });

    const targetSettings = await this.compatibilitySettingsRepository.findOne({
      where: { userId: targetUser.id },
    });

    const userProfile = await this.profilesRepository.findOne({
      where: { userId: user.id },
    });

    const targetProfile = await this.profilesRepository.findOne({
      where: { userId: targetUser.id },
    });

    return this.calculator.calculate(
      {
        settings: userSettings,
        profile: userProfile,
      },
      {
        settings: targetSettings,
        profile: targetProfile,
      },
    );
  }

  async getRecommendations(firebaseUid: string, limit: number = 20) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const userProfile = await this.profilesRepository.findOne({
      where: { userId: user.id },
    });

    if (!userProfile) {
      throw new NotFoundException('User profile not found');
    }

    // Get potential matches from same city
    const potentialMatches = await this.profilesRepository.find({
      where: { city: userProfile.city },
      relations: ['user'],
      take: limit * 2,
    });

    // Filter out self and already swiped users
    // TODO: Implement swipe filtering

    // Calculate compatibility for each potential match
    const recommendations = [];
    for (const match of potentialMatches) {
      if (match.userId === user.id) continue;

      const compatibility = await this.calculateCompatibility(
        firebaseUid,
        match.userId,
      );

      recommendations.push({
        profile: match,
        compatibility: compatibility.score,
        explanation: compatibility.explanation,
      });
    }

    // Sort by compatibility score
    recommendations.sort((a, b) => b.compatibility - a.compatibility);

    return recommendations.slice(0, limit);
  }
}
