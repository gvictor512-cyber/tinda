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
exports.FiltersController = void 0;
const common_1 = require("@nestjs/common");
const filters_service_1 = require("./filters.service");
const update_filters_dto_1 = require("./dto/update-filters.dto");
const auth_guard_1 = require("../../common/guards/auth.guard");
let FiltersController = class FiltersController {
    constructor(filtersService) {
        this.filtersService = filtersService;
    }
    async getMyFilters(req) {
        return this.filtersService.getUserFilters(req.user.uid);
    }
    async updateFilters(req, updateFiltersDto) {
        return this.filtersService.updateFilters(req.user.uid, updateFiltersDto);
    }
    async resetFilters(req) {
        return this.filtersService.resetFilters(req.user.uid);
    }
};
exports.FiltersController = FiltersController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], FiltersController.prototype, "getMyFilters", null);
__decorate([
    (0, common_1.Put)(),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, update_filters_dto_1.UpdateFiltersDto]),
    __metadata("design:returntype", Promise)
], FiltersController.prototype, "updateFilters", null);
__decorate([
    (0, common_1.Post)('reset'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], FiltersController.prototype, "resetFilters", null);
exports.FiltersController = FiltersController = __decorate([
    (0, common_1.Controller)('filters'),
    (0, common_1.UseGuards)(auth_guard_1.FirebaseAuthGuard),
    __metadata("design:paramtypes", [filters_service_1.FiltersService])
], FiltersController);
//# sourceMappingURL=filters.controller.js.map