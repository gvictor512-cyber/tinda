import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Match } from './entities/match.entity';
import { Swipe } from './entities/swipe.entity';
import { User } from '../users/entities/user.entity';
import { Profile } from '../profiles/entities/profile.entity';
import { CompatibilityService } from '../compatibility/compatibility.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SwipeDto } from './dto/swipe.dto';

@Injectable()
export class MatchesService {
  constructor(
    @InjectRepository(Match)
    private matchesRepository: Repository<Match>,
    @InjectRepository(Swipe)
    private swipesRepository: Repository<Swipe>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(Profile)
    private profilesRepository: Repository<Profile>,
    private compatibilityService: CompatibilityService,
    private notificationsService: NotificationsService,
  ) {}

  async handleSwipe(firebaseUid: string, swipeDto: SwipeDto) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const targetUser = await this.usersRepository.findOne({
      where: { id: swipeDto.targetUserId },
    });

    if (!targetUser) {
      throw new NotFoundException('Target user not found');
    }

    if (user.id === targetUser.id) {
      throw new BadRequestException('Cannot swipe yourself');
    }

    // Check if already swiped
    const existingSwipe = await this.swipesRepository.findOne({
      where: {
        swiperId: user.id,
        swipedId: targetUser.id,
      },
    });

    if (existingSwipe) {
      throw new BadRequestException('Already swiped this user');
    }

    // Create swipe record
    const swipe = this.swipesRepository.create({
      swiperId: user.id,
      swipedId: targetUser.id,
      swipeType: swipeDto.type,
    });

    await this.swipesRepository.save(swipe);

    // Check for match if swipe type is like or super_like
    if (swipeDto.type === 'like' || swipeDto.type === 'super_like') {
      const reciprocalSwipe = await this.swipesRepository.findOne({
        where: {
          swiperId: targetUser.id,
          swipedId: user.id,
          swipeType: ['like', 'super_like'] as any,
        },
      });

      if (reciprocalSwipe) {
        // It's a match!
        return this.createMatch(user.id, targetUser.id);
      }
    }

    return { success: true, matched: false };
  }

  async createMatch(user1Id: string, user2Id: string) {
    // Calculate compatibility
    const user1 = await this.usersRepository.findOne({ where: { id: user1Id } });
    const user2 = await this.usersRepository.findOne({ where: { id: user2Id } });

    const compatibility = await this.compatibilityService.calculateCompatibility(
      user1.firebaseUid,
      user2Id,
    );

    // Ensure user1Id < user2Id for uniqueness
    const [smallerId, largerId] = [user1Id, user2Id].sort();

    // Check if match already exists
    const existingMatch = await this.matchesRepository.findOne({
      where: {
        user1Id: smallerId,
        user2Id: largerId,
      },
    });

    if (existingMatch) {
      return { success: true, matched: true, matchId: existingMatch.id };
    }

    // Create match
    const match = this.matchesRepository.create({
      user1Id: smallerId,
      user2Id: largerId,
      compatibilityScore: compatibility.score,
      compatibilityExplanation: compatibility.explanation,
    });

    const savedMatch = await this.matchesRepository.save(match);

    // Send notifications to both users
    await this.notificationsService.sendMatchNotification(user1Id, user2Id, savedMatch.id);
    await this.notificationsService.sendMatchNotification(user2Id, user1Id, savedMatch.id);

    return {
      success: true,
      matched: true,
      matchId: savedMatch.id,
      compatibility: compatibility.score,
      explanation: compatibility.explanation,
    };
  }

  async getUserMatches(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const matches = await this.matchesRepository
      .createQueryBuilder('match')
      .leftJoinAndSelect('match.user1', 'user1')
      .leftJoinAndSelect('match.user2', 'user2')
      .where('(match.user1Id = :userId OR match.user2Id = :userId)', { userId: user.id })
      .andWhere('match.isActive = :isActive', { isActive: true })
      .orderBy('match.createdAt', 'DESC')
      .getMany();

    // Enrich with profile data
    const enrichedMatches = await Promise.all(
      matches.map(async (match) => {
        const otherUserId = match.user1Id === user.id ? match.user2Id : match.user1Id;
        const otherProfile = await this.profilesRepository.findOne({
          where: { userId: otherUserId },
          relations: ['user'],
        });

        return {
          ...match,
          otherUser: otherProfile,
        };
      }),
    );

    return enrichedMatches;
  }

  async getMatch(firebaseUid: string, matchId: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const match = await this.matchesRepository.findOne({
      where: { id: matchId },
      relations: ['user1', 'user2'],
    });

    if (!match) {
      throw new NotFoundException('Match not found');
    }

    // Verify user is part of the match
    if (match.user1Id !== user.id && match.user2Id !== user.id) {
      throw new BadRequestException('Access denied');
    }

    const otherUserId = match.user1Id === user.id ? match.user2Id : match.user1Id;
    const otherProfile = await this.profilesRepository.findOne({
      where: { userId: otherUserId },
      relations: ['user'],
    });

    return {
      ...match,
      otherUser: otherProfile,
    };
  }

  async unmatch(firebaseUid: string, matchId: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const match = await this.matchesRepository.findOne({
      where: { id: matchId },
    });

    if (!match) {
      throw new NotFoundException('Match not found');
    }

    // Verify user is part of the match
    if (match.user1Id !== user.id && match.user2Id !== user.id) {
      throw new BadRequestException('Access denied');
    }

    match.isActive = false;
    await this.matchesRepository.save(match);

    return { message: 'Unmatched successfully' };
  }

  async getPendingLikes(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Get users who liked current user but current user hasn't swiped yet
    const swipes = await this.swipesRepository
      .createQueryBuilder('swipe')
      .leftJoinAndSelect('swipe.swiper', 'swiper')
      .where('swipe.swipedId = :userId', { userId: user.id })
      .andWhere('swipe.swipeType IN (:...types)', { types: ['like', 'super_like'] })
      .getMany();

    const pendingLikes = [];

    for (const swipe of swipes) {
      // Check if current user has already swiped back
      const existingSwipe = await this.swipesRepository.findOne({
        where: {
          swiperId: user.id,
          swipedId: swipe.swiperId,
        },
      });

      if (!existingSwipe) {
        const profile = await this.profilesRepository.findOne({
          where: { userId: swipe.swiperId },
          relations: ['user'],
        });

        if (profile) {
          pendingLikes.push({
            profile,
            swipeType: swipe.swipeType,
            swipedAt: swipe.createdAt,
          });
        }
      }
    }

    return pendingLikes;
  }
}
