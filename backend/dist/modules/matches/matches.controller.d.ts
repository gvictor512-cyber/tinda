import { MatchesService } from './matches.service';
import { SwipeDto } from './dto/swipe.dto';
export declare class MatchesController {
    private readonly matchesService;
    constructor(matchesService: MatchesService);
    swipe(req: any, swipeDto: SwipeDto): Promise<{
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
    getMyMatches(req: any): Promise<{
        otherUser: import("../profiles/entities/profile.entity").Profile;
        id: string;
        user1Id: string;
        user2Id: string;
        compatibilityScore: number;
        compatibilityExplanation: string;
        createdAt: Date;
        isActive: boolean;
    }[]>;
    getMatch(req: any, matchId: string): Promise<{
        otherUser: import("../profiles/entities/profile.entity").Profile;
        id: string;
        user1Id: string;
        user2Id: string;
        compatibilityScore: number;
        compatibilityExplanation: string;
        createdAt: Date;
        isActive: boolean;
    }>;
    unmatch(req: any, matchId: string): Promise<{
        message: string;
    }>;
    getPendingLikes(req: any): Promise<any[]>;
}
