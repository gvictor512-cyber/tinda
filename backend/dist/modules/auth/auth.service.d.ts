import { JwtService } from '@nestjs/jwt';
import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { FirebaseAuthDto } from './dto/firebase-auth.dto';
import { RegisterDto } from './dto/register.dto';
export declare class AuthService {
    private usersRepository;
    private jwtService;
    constructor(usersRepository: Repository<User>, jwtService: JwtService);
    authenticateWithFirebase(firebaseAuthDto: FirebaseAuthDto): Promise<{
        accessToken: string;
        refreshToken: string;
        tokenType: string;
        user: {
            id: string;
            email: string;
            phone: string;
            isActive: boolean;
            isPremium: boolean;
            premiumExpiresAt: Date;
            createdAt: Date;
        };
    }>;
    register(registerDto: RegisterDto): Promise<{
        accessToken: string;
        refreshToken: string;
        tokenType: string;
        user: {
            id: string;
            email: string;
            phone: string;
            isActive: boolean;
            isPremium: boolean;
            premiumExpiresAt: Date;
            createdAt: Date;
        };
    }>;
    login(firebaseAuthDto: FirebaseAuthDto): Promise<{
        accessToken: string;
        refreshToken: string;
        tokenType: string;
        user: {
            id: string;
            email: string;
            phone: string;
            isActive: boolean;
            isPremium: boolean;
            premiumExpiresAt: Date;
            createdAt: Date;
        };
    }>;
    getCurrentUser(firebaseUid: string): Promise<{
        id: string;
        email: string;
        phone: string;
        isActive: boolean;
        isPremium: boolean;
        premiumExpiresAt: Date;
        createdAt: Date;
    }>;
    refreshToken(refreshToken: string): Promise<{
        accessToken: string;
        refreshToken: string;
        tokenType: string;
    }>;
    logout(firebaseUid: string): Promise<{
        message: string;
    }>;
    private generateTokens;
    private sanitizeUser;
}
