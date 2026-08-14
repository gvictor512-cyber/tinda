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
exports.FiltersService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const user_filters_entity_1 = require("./entities/user-filters.entity");
const user_entity_1 = require("../users/entities/user.entity");
let FiltersService = class FiltersService {
    constructor(userFiltersRepository, usersRepository) {
        this.userFiltersRepository = userFiltersRepository;
        this.usersRepository = usersRepository;
    }
    async getUserFilters(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
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
        return filters;
    }
    async updateFilters(firebaseUid, updateFiltersDto) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
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
    async resetFilters(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
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
};
exports.FiltersService = FiltersService;
exports.FiltersService = FiltersService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_filters_entity_1.UserFilters)),
    __param(1, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], FiltersService);
//# sourceMappingURL=filters.service.js.map