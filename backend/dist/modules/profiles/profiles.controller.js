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
exports.ProfilesController = void 0;
const common_1 = require("@nestjs/common");
const profiles_service_1 = require("./profiles.service");
const create_profile_dto_1 = require("./dto/create-profile.dto");
const update_profile_dto_1 = require("./dto/update-profile.dto");
const auth_guard_1 = require("../../common/guards/auth.guard");
let ProfilesController = class ProfilesController {
    constructor(profilesService) {
        this.profilesService = profilesService;
    }
    async create(req, createProfileDto) {
        return this.profilesService.create(req.user.uid, createProfileDto);
    }
    async findMyProfile(req) {
        return this.profilesService.findByUserId(req.user.uid);
    }
    async search(city, ageMin, ageMax, budgetMin, budgetMax, gender, page = 1, limit = 20) {
        const filters = {};
        if (city)
            filters.city = city;
        if (ageMin)
            filters.ageMin = parseInt(ageMin, 10);
        if (ageMax)
            filters.ageMax = parseInt(ageMax, 10);
        if (budgetMin)
            filters.budgetMin = parseInt(budgetMin, 10);
        if (budgetMax)
            filters.budgetMax = parseInt(budgetMax, 10);
        if (gender)
            filters.gender = gender;
        return this.profilesService.searchProfiles(filters, page, limit);
    }
    async findByCity(city, page = 1, limit = 20) {
        return this.profilesService.findProfilesByCity(city, page, limit);
    }
    async findOne(id) {
        return this.profilesService.findOne(id);
    }
    async update(req, updateProfileDto) {
        return this.profilesService.update(req.user.uid, updateProfileDto);
    }
    async delete(req) {
        return this.profilesService.delete(req.user.uid);
    }
    async addPhoto(req, photoUrl) {
        return this.profilesService.addPhoto(req.user.uid, photoUrl);
    }
    async removePhoto(req, index) {
        return this.profilesService.removePhoto(req.user.uid, parseInt(index));
    }
};
exports.ProfilesController = ProfilesController;
__decorate([
    (0, common_1.Post)(),
    (0, common_1.HttpCode)(common_1.HttpStatus.CREATED),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_profile_dto_1.CreateProfileDto]),
    __metadata("design:returntype", Promise)
], ProfilesController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ProfilesController.prototype, "findMyProfile", null);
__decorate([
    (0, common_1.Get)('search'),
    __param(0, (0, common_1.Query)('city')),
    __param(1, (0, common_1.Query)('ageMin')),
    __param(2, (0, common_1.Query)('ageMax')),
    __param(3, (0, common_1.Query)('budgetMin')),
    __param(4, (0, common_1.Query)('budgetMax')),
    __param(5, (0, common_1.Query)('gender')),
    __param(6, (0, common_1.Query)('page', new common_1.DefaultValuePipe(1), common_1.ParseIntPipe)),
    __param(7, (0, common_1.Query)('limit', new common_1.DefaultValuePipe(20), common_1.ParseIntPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String, String, String, Number, Number]),
    __metadata("design:returntype", Promise)
], ProfilesController.prototype, "search", null);
__decorate([
    (0, common_1.Get)('city/:city'),
    __param(0, (0, common_1.Param)('city')),
    __param(1, (0, common_1.Query)('page', new common_1.DefaultValuePipe(1), common_1.ParseIntPipe)),
    __param(2, (0, common_1.Query)('limit', new common_1.DefaultValuePipe(20), common_1.ParseIntPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Number, Number]),
    __metadata("design:returntype", Promise)
], ProfilesController.prototype, "findByCity", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ProfilesController.prototype, "findOne", null);
__decorate([
    (0, common_1.Put)(),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, update_profile_dto_1.UpdateProfileDto]),
    __metadata("design:returntype", Promise)
], ProfilesController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(),
    (0, common_1.HttpCode)(common_1.HttpStatus.NO_CONTENT),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ProfilesController.prototype, "delete", null);
__decorate([
    (0, common_1.Post)('photos'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('photoUrl')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ProfilesController.prototype, "addPhoto", null);
__decorate([
    (0, common_1.Delete)('photos/:index'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('index')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], ProfilesController.prototype, "removePhoto", null);
exports.ProfilesController = ProfilesController = __decorate([
    (0, common_1.Controller)('profiles'),
    (0, common_1.UseGuards)(auth_guard_1.FirebaseAuthGuard),
    __metadata("design:paramtypes", [profiles_service_1.ProfilesService])
], ProfilesController);
//# sourceMappingURL=profiles.controller.js.map