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
exports.CompatibilityController = void 0;
const common_1 = require("@nestjs/common");
const compatibility_service_1 = require("./compatibility.service");
const auth_guard_1 = require("../../common/guards/auth.guard");
let CompatibilityController = class CompatibilityController {
    constructor(compatibilityService) {
        this.compatibilityService = compatibilityService;
    }
    async calculateCompatibility(req, targetUserId) {
        return this.compatibilityService.calculateCompatibility(req.user.uid, targetUserId);
    }
    async getCompatibilityScore(req, userId) {
        return this.compatibilityService.calculateCompatibility(req.user.uid, userId);
    }
    async getCompatibilityExplanation(req, userId) {
        const result = await this.compatibilityService.calculateCompatibility(req.user.uid, userId);
        return {
            score: result.score,
            explanation: result.explanation,
            factors: result.factors,
        };
    }
    async getRecommendations(req) {
        return this.compatibilityService.getRecommendations(req.user.uid);
    }
};
exports.CompatibilityController = CompatibilityController;
__decorate([
    (0, common_1.Post)('calculate'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('targetUserId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], CompatibilityController.prototype, "calculateCompatibility", null);
__decorate([
    (0, common_1.Get)('score/:userId'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('userId', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], CompatibilityController.prototype, "getCompatibilityScore", null);
__decorate([
    (0, common_1.Get)('explanation/:userId'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('userId', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], CompatibilityController.prototype, "getCompatibilityExplanation", null);
__decorate([
    (0, common_1.Get)('recommendations'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], CompatibilityController.prototype, "getRecommendations", null);
exports.CompatibilityController = CompatibilityController = __decorate([
    (0, common_1.Controller)('compatibility'),
    (0, common_1.UseGuards)(auth_guard_1.FirebaseAuthGuard),
    __metadata("design:paramtypes", [compatibility_service_1.CompatibilityService])
], CompatibilityController);
//# sourceMappingURL=compatibility.controller.js.map