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
exports.AdminController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const admin_service_1 = require("./admin.service");
const auth_guard_1 = require("../../common/guards/auth.guard");
let AdminController = class AdminController {
    constructor(adminService) {
        this.adminService = adminService;
    }
    getDashboard(period = 'month') {
        return this.adminService.getDashboard(period);
    }
    getUsers(take = 20, skip = 0) {
        return this.adminService.getUsers(Number(take), Number(skip));
    }
    getNewUsers(period = 'week', take = 20, skip = 0) {
        return this.adminService.getNewUsers(period, Number(take), Number(skip));
    }
    getPayments(take = 20, skip = 0) {
        return this.adminService.getPayments(Number(take), Number(skip));
    }
    getCancellations(take = 20, skip = 0) {
        return this.adminService.getCancellations(Number(take), Number(skip));
    }
};
exports.AdminController = AdminController;
__decorate([
    (0, common_1.Get)('dashboard'),
    (0, swagger_1.ApiQuery)({ name: 'period', required: false, description: 'today | week | month | year | all', example: 'month' }),
    __param(0, (0, common_1.Query)('period')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], AdminController.prototype, "getDashboard", null);
__decorate([
    (0, common_1.Get)('users'),
    (0, swagger_1.ApiQuery)({ name: 'take', required: false, type: 'number', example: 20 }),
    (0, swagger_1.ApiQuery)({ name: 'skip', required: false, type: 'number', example: 0 }),
    __param(0, (0, common_1.Query)('take')),
    __param(1, (0, common_1.Query)('skip')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], AdminController.prototype, "getUsers", null);
__decorate([
    (0, common_1.Get)('users/new'),
    (0, swagger_1.ApiQuery)({ name: 'period', required: false, description: 'today | week | month | year | all', example: 'week' }),
    (0, swagger_1.ApiQuery)({ name: 'take', required: false, type: 'number', example: 20 }),
    (0, swagger_1.ApiQuery)({ name: 'skip', required: false, type: 'number', example: 0 }),
    __param(0, (0, common_1.Query)('period')),
    __param(1, (0, common_1.Query)('take')),
    __param(2, (0, common_1.Query)('skip')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object, Object]),
    __metadata("design:returntype", void 0)
], AdminController.prototype, "getNewUsers", null);
__decorate([
    (0, common_1.Get)('payments'),
    (0, swagger_1.ApiQuery)({ name: 'take', required: false, type: 'number', example: 20 }),
    (0, swagger_1.ApiQuery)({ name: 'skip', required: false, type: 'number', example: 0 }),
    __param(0, (0, common_1.Query)('take')),
    __param(1, (0, common_1.Query)('skip')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], AdminController.prototype, "getPayments", null);
__decorate([
    (0, common_1.Get)('cancellations'),
    (0, swagger_1.ApiQuery)({ name: 'take', required: false, type: 'number', example: 20 }),
    (0, swagger_1.ApiQuery)({ name: 'skip', required: false, type: 'number', example: 0 }),
    __param(0, (0, common_1.Query)('take')),
    __param(1, (0, common_1.Query)('skip')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], AdminController.prototype, "getCancellations", null);
exports.AdminController = AdminController = __decorate([
    (0, swagger_1.ApiTags)('admin'),
    (0, common_1.Controller)('admin'),
    (0, common_1.UseGuards)(auth_guard_1.FirebaseAuthGuard),
    (0, swagger_1.ApiBearerAuth)(),
    __metadata("design:paramtypes", [admin_service_1.AdminService])
], AdminController);
//# sourceMappingURL=admin.controller.js.map