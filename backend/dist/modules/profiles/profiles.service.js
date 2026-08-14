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
exports.ProfilesService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const profile_entity_1 = require("./entities/profile.entity");
const compatibility_settings_entity_1 = require("../compatibility/entities/compatibility-settings.entity");
const user_entity_1 = require("../users/entities/user.entity");
let ProfilesService = class ProfilesService {
    constructor(profilesRepository, compatibilitySettingsRepository, usersRepository) {
        this.profilesRepository = profilesRepository;
        this.compatibilitySettingsRepository = compatibilitySettingsRepository;
        this.usersRepository = usersRepository;
    }
    async create(firebaseUid, createProfileDto) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const existingProfile = await this.profilesRepository.findOne({
            where: { userId: user.id },
        });
        if (existingProfile) {
            throw new common_1.BadRequestException('Profile already exists');
        }
        const profile = this.profilesRepository.create({
            userId: user.id,
            ...createProfileDto,
            photos: createProfileDto.photos || [],
            languages: createProfileDto.languages || [],
        });
        const savedProfile = await this.profilesRepository.save(profile);
        if (createProfileDto.compatibilitySettings) {
            const compatibilitySettings = this.compatibilitySettingsRepository.create({
                userId: user.id,
                ...createProfileDto.compatibilitySettings,
                personalityTraits: createProfileDto.compatibilitySettings.personalityTraits || [],
            });
            await this.compatibilitySettingsRepository.save(compatibilitySettings);
        }
        return savedProfile;
    }
    async findByUserId(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const profile = await this.profilesRepository.findOne({
            where: { userId: user.id },
            relations: ['user'],
        });
        if (!profile) {
            throw new common_1.NotFoundException('Profile not found');
        }
        const compatibilitySettings = await this.compatibilitySettingsRepository.findOne({
            where: { userId: user.id },
        });
        return {
            ...profile,
            compatibilitySettings,
        };
    }
    async findOne(id) {
        const profile = await this.profilesRepository.findOne({
            where: { id },
            relations: ['user'],
        });
        if (!profile) {
            throw new common_1.NotFoundException('Profile not found');
        }
        const compatibilitySettings = await this.compatibilitySettingsRepository.findOne({
            where: { userId: profile.userId },
        });
        return {
            ...profile,
            compatibilitySettings,
        };
    }
    async update(firebaseUid, updateProfileDto) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const profile = await this.profilesRepository.findOne({
            where: { userId: user.id },
        });
        if (!profile) {
            throw new common_1.NotFoundException('Profile not found');
        }
        Object.assign(profile, updateProfileDto);
        if (updateProfileDto.photos) {
            profile.photos = updateProfileDto.photos;
        }
        if (updateProfileDto.languages) {
            profile.languages = updateProfileDto.languages;
        }
        const updatedProfile = await this.profilesRepository.save(profile);
        if (updateProfileDto.compatibilitySettings) {
            const compatibilitySettings = await this.compatibilitySettingsRepository.findOne({
                where: { userId: user.id },
            });
            if (compatibilitySettings) {
                Object.assign(compatibilitySettings, updateProfileDto.compatibilitySettings);
                if (updateProfileDto.compatibilitySettings.personalityTraits) {
                    compatibilitySettings.personalityTraits = updateProfileDto.compatibilitySettings.personalityTraits;
                }
                await this.compatibilitySettingsRepository.save(compatibilitySettings);
            }
        }
        return updatedProfile;
    }
    async delete(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const profile = await this.profilesRepository.findOne({
            where: { userId: user.id },
        });
        if (!profile) {
            throw new common_1.NotFoundException('Profile not found');
        }
        await this.profilesRepository.remove(profile);
        await this.compatibilitySettingsRepository.delete({
            userId: user.id,
        });
        return { message: 'Profile deleted successfully' };
    }
    async addPhoto(firebaseUid, photoUrl) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const profile = await this.profilesRepository.findOne({
            where: { userId: user.id },
        });
        if (!profile) {
            throw new common_1.NotFoundException('Profile not found');
        }
        if (profile.photos && profile.photos.length >= 6) {
            throw new common_1.BadRequestException('Maximum 6 photos allowed');
        }
        if (!profile.photos) {
            profile.photos = [];
        }
        profile.photos.push(photoUrl);
        if (profile.photos.length === 1) {
            profile.profilePhotoUrl = photoUrl;
        }
        return this.profilesRepository.save(profile);
    }
    async removePhoto(firebaseUid, index) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const profile = await this.profilesRepository.findOne({
            where: { userId: user.id },
        });
        if (!profile) {
            throw new common_1.NotFoundException('Profile not found');
        }
        if (!profile.photos || profile.photos.length <= index) {
            throw new common_1.BadRequestException('Invalid photo index');
        }
        profile.photos.splice(index, 1);
        if (index === 0 && profile.photos.length > 0) {
            profile.profilePhotoUrl = profile.photos[0];
        }
        else if (profile.photos.length === 0) {
            profile.profilePhotoUrl = null;
        }
        return this.profilesRepository.save(profile);
    }
    async findProfilesByCity(city, limit = 20) {
        return this.profilesRepository.find({
            where: { city },
            relations: ['user'],
            take: limit,
            order: { createdAt: 'DESC' },
        });
    }
    async searchProfiles(filters) {
        const queryBuilder = this.profilesRepository.createQueryBuilder('profile')
            .leftJoinAndSelect('profile.user', 'user')
            .where('user.isActive = :isActive', { isActive: true });
        if (filters.city) {
            queryBuilder.andWhere('profile.city = :city', { city: filters.city });
        }
        if (filters.ageMin && filters.ageMax) {
            queryBuilder.andWhere('profile.age >= :ageMin AND profile.age <= :ageMax', {
                ageMin: filters.ageMin,
                ageMax: filters.ageMax,
            });
        }
        if (filters.budgetMin && filters.budgetMax) {
            queryBuilder.andWhere('profile.budgetMin >= :budgetMin AND profile.budgetMax <= :budgetMax', {
                budgetMin: filters.budgetMin,
                budgetMax: filters.budgetMax,
            });
        }
        if (filters.gender) {
            queryBuilder.andWhere('profile.gender = :gender', { gender: filters.gender });
        }
        queryBuilder.orderBy('profile.createdAt', 'DESC')
            .take(filters.limit || 20);
        return queryBuilder.getMany();
    }
};
exports.ProfilesService = ProfilesService;
exports.ProfilesService = ProfilesService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(profile_entity_1.Profile)),
    __param(1, (0, typeorm_1.InjectRepository)(compatibility_settings_entity_1.CompatibilitySettings)),
    __param(2, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], ProfilesService);
//# sourceMappingURL=profiles.service.js.map