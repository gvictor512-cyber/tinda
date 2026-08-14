"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.VerificationService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const verification_entity_1 = require("./entities/verification.entity");
const user_entity_1 = require("../users/entities/user.entity");
let VerificationService = class VerificationService {
    constructor(verificationRepository, usersRepository) {
        this.verificationRepository = verificationRepository;
        this.usersRepository = usersRepository;
    }
    async getVerificationStatus(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        let verification = await this.verificationRepository.findOne({
            where: { userId: user.id },
        });
        if (!verification) {
            verification = this.verificationRepository.create({
                userId: user.id,
                emailVerified: false,
                phoneVerified: false,
                selfieVerified: false,
                documentVerified: false,
                isVerified: false,
                verificationLevel: 'basic',
            });
            await this.verificationRepository.save(verification);
        }
        return {
            isVerified: verification.isVerified,
            verificationLevel: verification.verificationLevel,
            emailVerified: verification.emailVerified,
            phoneVerified: verification.phoneVerified,
            selfieVerified: verification.selfieVerified,
            documentVerified: verification.documentVerified,
        };
    }
    async verifyEmail(firebaseUid, verifyEmailDto) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        let verification = await this.verificationRepository.findOne({
            where: { userId: user.id },
        });
        if (!verification) {
            verification = this.verificationRepository.create({
                userId: user.id,
            });
        }
        verification.emailVerified = true;
        verification.emailVerifiedAt = new Date();
        verification.verificationLevel = 'standard';
        await this.verificationRepository.save(verification);
        await this.updateOverallVerification(verification);
        return { success: true, message: 'Email verified successfully' };
    }
    async verifyPhone(firebaseUid, verifyPhoneDto) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        let verification = await this.verificationRepository.findOne({
            where: { userId: user.id },
        });
        if (!verification) {
            verification = this.verificationRepository.create({
                userId: user.id,
            });
        }
        verification.phoneVerified = true;
        verification.phoneVerifiedAt = new Date();
        verification.verificationLevel = 'standard';
        await this.verificationRepository.save(verification);
        user.phone = verifyPhoneDto.phoneNumber;
        await this.usersRepository.save(user);
        await this.updateOverallVerification(verification);
        return { success: true, message: 'Phone verified successfully' };
    }
    async verifySelfie(firebaseUid, verifySelfieDto) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        let verification = await this.verificationRepository.findOne({
            where: { userId: user.id },
        });
        if (!verification) {
            verification = this.verificationRepository.create({
                userId: user.id,
            });
        }
        verification.selfieVerified = true;
        verification.selfieVerifiedAt = new Date();
        verification.verificationLevel = 'advanced';
        await this.verificationRepository.save(verification);
        await this.updateOverallVerification(verification);
        return { success: true, message: 'Selfie verified successfully' };
    }
    async verifyDocument(firebaseUid, documentUrl) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        let verification = await this.verificationRepository.findOne({
            where: { userId: user.id },
        });
        if (!verification) {
            verification = this.verificationRepository.create({
                userId: user.id,
            });
        }
        verification.documentVerified = true;
        verification.documentVerifiedAt = new Date();
        verification.documentUrl = documentUrl;
        verification.verificationLevel = 'advanced';
        await this.verificationRepository.save(verification);
        await this.updateOverallVerification(verification);
        return { success: true, message: 'Document verified successfully' };
    }
    async updateOverallVerification(verification) {
        const verificationsCompleted = [
            verification.emailVerified,
            verification.phoneVerified,
            verification.selfieVerified,
            verification.documentVerified,
        ].filter(Boolean).length;
        if (verificationsCompleted >= 3) {
            verification.isVerified = true;
            verification.verificationLevel = 'advanced';
        }
        else if (verificationsCompleted >= 2) {
            verification.isVerified = true;
            verification.verificationLevel = 'standard';
        }
        else if (verificationsCompleted >= 1) {
            verification.isVerified = false;
            verification.verificationLevel = 'basic';
        }
        else {
            verification.isVerified = false;
            verification.verificationLevel = 'basic';
        }
        await this.verificationRepository.save(verification);
    }
};
exports.VerificationService = VerificationService;
exports.VerificationService = VerificationService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(verification_entity_1.Verification)),
    __param(1, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], VerificationService);
//# sourceMappingURL=verification.service.js.map