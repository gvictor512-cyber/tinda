import { Repository } from 'typeorm';
import { Match } from './entities/match.entity';
import { Swipe } from './entities/swipe.entity';
import { User } from '../users/entities/user.entity';
import { Profile } from '../profiles/entities/profile.entity';
import { CompatibilityService } from '../compatibility/compatibility.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SwipeDto } from './dto/swipe.dto';
export declare class MatchesService {
    private matchesRepository;
    private swipesRepository;
    private usersRepository;
    private profilesRepository;
    private compatibilityService;
    private notificationsService;
    constructor(matchesRepository: Repository<Match>, swipesRepository: Repository<Swipe>, usersRepository: Repository<User>, profilesRepository: Repository<Profile>, compatibilityService: CompatibilityService, notificationsService: NotificationsService);
    handleSwipe(firebaseUid: string, swipeDto: SwipeDto): Promise<{
        success: boolean;
        matched: boolean;
        matchId: string;
        compatibility?: undefined;
        explanation?: undefined;
    } | {
        success: boolean;
        matched: boolean;
        matchId: string;
        compatibility: number;
        explanation: string;
    } | {
        success: boolean;
        matched: boolean;
    }>;
    createMatch(user1Id: string, user2Id: string): Promise<{
        success: boolean;
        matched: boolean;
        matchId: string;
        compatibility?: undefined;
        explanation?: undefined;
    } | {
        success: boolean;
        matched: boolean;
        matchId: string;
        compatibility: number;
        explanation: string;
    }>;
    getUserMatches(firebaseUid: string): Promise<{
        otherUser: Profile;
        id: string;
        user1Id: string;
        user2Id: string;
        compatibilityScore: number;
        compatibilityExplanation: string;
        createdAt: Date;
        isActive: boolean;
    }[]>;
    getMatch(firebaseUid: string, matchId: string): Promise<{
        otherUser: Profile;
        id: string;
        user1Id: string;
        user2Id: string;
        compatibilityScore: number;
        compatibilityExplanation: string;
        createdAt: Date;
        isActive: boolean;
    }>;
    unmatch(firebaseUid: string, matchId: string): Promise<{
        message: string;
    }>;
    getPendingLikes(firebaseUid: string): Promise<any[]>;
}
