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
exports.PremiumController = void 0;
const common_1 = require("@nestjs/common");
const premium_service_1 = require("./premium.service");
const create_subscription_dto_1 = require("./dto/create-subscription.dto");
const auth_guard_1 = require("../../common/guards/auth.guard");
let PremiumController = class PremiumController {
    constructor(premiumService) {
        this.premiumService = premiumService;
    }
    async getPremiumStatus(req) {
        return this.premiumService.getPremiumStatus(req.user.uid);
    }
    async getPremiumFeatures() {
        return this.premiumService.getPremiumFeatures();
    }
    async subscribe(req, createSubscriptionDto) {
        return this.premiumService.createSubscription(req.user.uid, createSubscriptionDto);
    }
    async cancelSubscription(req) {
        return this.premiumService.cancelSubscription(req.user.uid);
    }
    async getDailyLimits(req) {
        return this.premiumService.getDailyLimits(req.user.uid);
    }
    async boostProfile(req) {
        return this.premiumService.boostProfile(req.user.uid);
    }
};
exports.PremiumController = PremiumController;
__decorate([
    (0, common_1.Get)('status'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], PremiumController.prototype, "getPremiumStatus", null);
__decorate([
    (0, common_1.Get)('features'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], PremiumController.prototype, "getPremiumFeatures", null);
__decorate([
    (0, common_1.Post)('subscribe'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_subscription_dto_1.CreateSubscriptionDto]),
    __metadata("design:returntype", Promise)
], PremiumController.prototype, "subscribe", null);
__decorate([
    (0, common_1.Post)('cancel'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], PremiumController.prototype, "cancelSubscription", null);
__decorate([
    (0, common_1.Get)('daily-limits'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], PremiumController.prototype, "getDailyLimits", null);
__decorate([
    (0, common_1.Post)('boost'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], PremiumController.prototype, "boostProfile", null);
exports.PremiumController = PremiumController = __decorate([
    (0, common_1.Controller)('premium'),
    (0, common_1.UseGuards)(auth_guard_1.FirebaseAuthGuard),
    __metadata("design:paramtypes", [premium_service_1.PremiumService])
], PremiumController);
//# sourceMappingURL=premium.controller.js.map