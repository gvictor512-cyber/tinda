"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const admin = __importStar(require("firebase-admin"));
const user_entity_1 = require("../users/entities/user.entity");
let AuthService = class AuthService {
    constructor(usersRepository, jwtService) {
        this.usersRepository = usersRepository;
        this.jwtService = jwtService;
        if (!admin.apps.length) {
            const serviceAccount = {
                projectId: process.env.FIREBASE_PROJECT_ID,
                privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
                clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            };
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
            });
        }
    }
    async authenticateWithFirebase(firebaseAuthDto) {
        try {
            const decodedToken = await admin.auth().verifyIdToken(firebaseAuthDto.token);
            let user = await this.usersRepository.findOne({
                where: { firebaseUid: decodedToken.uid },
            });
            if (!user) {
                const newUser = this.usersRepository.create({
                    firebaseUid: decodedToken.uid,
                    email: decodedToken.email,
                    isActive: true,
                });
                user = await this.usersRepository.save(newUser);
            }
            const tokens = await this.generateTokens(user);
            return {
                user: this.sanitizeUser(user),
                ...tokens,
            };
        }
        catch (error) {
            throw new common_1.UnauthorizedException('Invalid Firebase token');
        }
    }
    async register(registerDto) {
        try {
            const existingUser = await this.usersRepository.findOne({
                where: { email: registerDto.email },
            });
            if (existingUser) {
                throw new common_1.ConflictException('User already exists');
            }
            const newUser = this.usersRepository.create({
                email: registerDto.email,
                phone: registerDto.phone,
                isActive: true,
            });
            const savedUser = await this.usersRepository.save(newUser);
            const tokens = await this.generateTokens(savedUser);
            return {
                user: this.sanitizeUser(savedUser),
                ...tokens,
            };
        }
        catch (error) {
            throw new common_1.ConflictException('Registration failed');
        }
    }
    async login(firebaseAuthDto) {
        return this.authenticateWithFirebase(firebaseAuthDto);
    }
    async getCurrentUser(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.UnauthorizedException('User not found');
        }
        return this.sanitizeUser(user);
    }
    async refreshToken(refreshToken) {
        try {
            const payload = this.jwtService.verify(refreshToken);
            const user = await this.usersRepository.findOne({
                where: { id: payload.sub },
            });
            if (!user) {
                throw new common_1.UnauthorizedException('User not found');
            }
            return this.generateTokens(user);
        }
        catch (error) {
            throw new common_1.UnauthorizedException('Invalid refresh token');
        }
    }
    async logout(firebaseUid) {
        await admin.auth().revokeRefreshTokens(firebaseUid);
        return { message: 'Logged out successfully' };
    }
    async generateTokens(user) {
        const payload = {
            sub: user.id,
            email: user.email,
            firebaseUid: user.firebaseUid,
        };
        const accessToken = this.jwtService.sign(payload);
        const refreshToken = this.jwtService.sign(payload, {
            expiresIn: '30d',
        });
        return {
            accessToken,
            refreshToken,
            tokenType: 'Bearer',
        };
    }
    sanitizeUser(user) {
        const { id, email, phone, isActive, isPremium, premiumExpiresAt, createdAt } = user;
        return {
            id,
            email,
            phone,
            isActive,
            isPremium,
            premiumExpiresAt,
            createdAt,
        };
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        jwt_1.JwtService])
], AuthService);
//# sourceMappingURL=auth.service.js.map