import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Profile } from './entities/profile.entity';
import { CompatibilitySettings } from '../compatibility/entities/compatibility-settings.entity';
import { User } from '../users/entities/user.entity';
import { CreateProfileDto } from './dto/create-profile.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class ProfilesService {
  constructor(
    @InjectRepository(Profile)
    private profilesRepository: Repository<Profile>,
    @InjectRepository(CompatibilitySettings)
    private compatibilitySettingsRepository: Repository<CompatibilitySettings>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async create(firebaseUid: string, createProfileDto: CreateProfileDto) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const existingProfile = await this.profilesRepository.findOne({
      where: { userId: user.id },
    });

    if (existingProfile) {
      throw new BadRequestException('Profile already exists');
    }

    const profile = this.profilesRepository.create({
      userId: user.id,
      ...createProfileDto,
      photos: createProfileDto.photos || [],
      languages: createProfileDto.languages || [],
    });

    const savedProfile = await this.profilesRepository.save(profile);

    // Create compatibility settings
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

  async findByUserId(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const profile = await this.profilesRepository.findOne({
      where: { userId: user.id },
      relations: ['user'],
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    const compatibilitySettings = await this.compatibilitySettingsRepository.findOne({
      where: { userId: user.id },
    });

    return {
      ...profile,
      compatibilitySettings,
    };
  }

  async findOne(id: string) {
    const profile = await this.profilesRepository.findOne({
      where: { id },
      relations: ['user'],
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    const compatibilitySettings = await this.compatibilitySettingsRepository.findOne({
      where: { userId: profile.userId },
    });

    return {
      ...profile,
      compatibilitySettings,
    };
  }

  async update(firebaseUid: string, updateProfileDto: UpdateProfileDto) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const profile = await this.profilesRepository.findOne({
      where: { userId: user.id },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    Object.assign(profile, updateProfileDto);

    if (updateProfileDto.photos) {
      profile.photos = updateProfileDto.photos;
    }

    if (updateProfileDto.languages) {
      profile.languages = updateProfileDto.languages;
    }

    const updatedProfile = await this.profilesRepository.save(profile);

    // Update compatibility settings if provided
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

  async delete(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const profile = await this.profilesRepository.findOne({
      where: { userId: user.id },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    await this.profilesRepository.remove(profile);

    // Also delete compatibility settings
    await this.compatibilitySettingsRepository.delete({
      userId: user.id,
    });

    return { message: 'Profile deleted successfully' };
  }

  async addPhoto(firebaseUid: string, photoUrl: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const profile = await this.profilesRepository.findOne({
      where: { userId: user.id },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    if (profile.photos && profile.photos.length >= 6) {
      throw new BadRequestException('Maximum 6 photos allowed');
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

  async removePhoto(firebaseUid: string, index: number) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const profile = await this.profilesRepository.findOne({
      where: { userId: user.id },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    if (!profile.photos || profile.photos.length <= index) {
      throw new BadRequestException('Invalid photo index');
    }

    profile.photos.splice(index, 1);

    if (index === 0 && profile.photos.length > 0) {
      profile.profilePhotoUrl = profile.photos[0];
    } else if (profile.photos.length === 0) {
      profile.profilePhotoUrl = null;
    }

    return this.profilesRepository.save(profile);
  }

  async findProfilesByCity(city: string, limit: number = 20) {
    return this.profilesRepository.find({
      where: { city },
      relations: ['user'],
      take: limit,
      order: { createdAt: 'DESC' },
    });
  }

  async searchProfiles(filters: any) {
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
}
