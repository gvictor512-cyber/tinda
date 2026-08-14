import { AuthService } from './auth.service';
import { FirebaseAuthDto } from './dto/firebase-auth.dto';
import { RegisterDto } from './dto/register.dto';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    firebaseAuth(firebaseAuthDto: FirebaseAuthDto): Promise<{
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
    getCurrentUser(req: any): Promise<{
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
    logout(req: any): Promise<{
        message: string;
    }>;
}
