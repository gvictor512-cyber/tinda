import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserFilters } from './entities/user-filters.entity';
import { User } from '../users/entities/user.entity';
import { UpdateFiltersDto } from './dto/update-filters.dto';

@Injectable()
export class FiltersService {
  constructor(
    @InjectRepository(UserFilters)
    private userFiltersRepository: Repository<UserFilters>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async getUserFilters(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    let filters = await this.userFiltersRepository.findOne({
      where: { userId: user.id },
    });

    // Return default filters if none exist
    if (!filters) {
      filters = this.userFiltersRepository.create({
        userId: user.id,
        ageMin: 18,
        ageMax: 40,
        cities: [],
        budgetMin: 300,
        budgetMax: 1000,
        smokingPreferences: [],
        petsPreferences: [],
        workFromHome: null,
        gender: null,
        languages: [],
        userTypes: [],
      });
    }

    return filters;
  }

  async updateFilters(firebaseUid: string, updateFiltersDto: UpdateFiltersDto) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    let filters = await this.userFiltersRepository.findOne({
      where: { userId: user.id },
    });

    if (!filters) {
      filters = this.userFiltersRepository.create({
        userId: user.id,
        ageMin: 18,
        ageMax: 40,
        cities: [],
        budgetMin: 300,
        budgetMax: 1000,
        smokingPreferences: [],
        petsPreferences: [],
        workFromHome: null,
        gender: null,
        languages: [],
        userTypes: [],
      });
    }

    Object.assign(filters, updateFiltersDto);

    return this.userFiltersRepository.save(filters);
  }

  async resetFilters(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    let filters = await this.userFiltersRepository.findOne({
      where: { userId: user.id },
    });

    if (!filters) {
      filters = this.userFiltersRepository.create({
        userId: user.id,
      });
    }

    filters.ageMin = 18;
    filters.ageMax = 40;
    filters.cities = [];
    filters.budgetMin = 300;
    filters.budgetMax = 1000;
    filters.smokingPreferences = [];
    filters.petsPreferences = [];
    filters.workFromHome = null;
    filters.gender = null;
    filters.languages = [];
    filters.userTypes = [];

    return this.userFiltersRepository.save(filters);
  }
}
