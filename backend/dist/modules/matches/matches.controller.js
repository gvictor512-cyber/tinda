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
exports.MatchesController = void 0;
const common_1 = require("@nestjs/common");
const matches_service_1 = require("./matches.service");
const swipe_dto_1 = require("./dto/swipe.dto");
const auth_guard_1 = require("../../common/guards/auth.guard");
let MatchesController = class MatchesController {
    constructor(matchesService) {
        this.matchesService = matchesService;
    }
    async swipe(req, swipeDto) {
        return this.matchesService.handleSwipe(req.user.uid, swipeDto);
    }
    async getMyMatches(req) {
        return this.matchesService.getUserMatches(req.user.uid);
    }
    async getMatch(req, matchId) {
        return this.matchesService.getMatch(req.user.uid, matchId);
    }
    async unmatch(req, matchId) {
        return this.matchesService.unmatch(req.user.uid, matchId);
    }
    async getPendingLikes(req) {
        return this.matchesService.getPendingLikes(req.user.uid);
    }
};
exports.MatchesController = MatchesController;
__decorate([
    (0, common_1.Post)('swipe'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, swipe_dto_1.SwipeDto]),
    __metadata("design:returntype", Promise)
], MatchesController.prototype, "swipe", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], MatchesController.prototype, "getMyMatches", null);
__decorate([
    (0, common_1.Get)(':matchId'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('matchId', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], MatchesController.prototype, "getMatch", null);
__decorate([
    (0, common_1.Delete)(':matchId'),
    (0, common_1.HttpCode)(common_1.HttpStatus.NO_CONTENT),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('matchId', common_1.ParseUUIDPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], MatchesController.prototype, "unmatch", null);
__decorate([
    (0, common_1.Get)('pending/likes'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], MatchesController.prototype, "getPendingLikes", null);
exports.MatchesController = MatchesController = __decorate([
    (0, common_1.Controller)('matches'),
    (0, common_1.UseGuards)(auth_guard_1.FirebaseAuthGuard),
    __metadata("design:paramtypes", [matches_service_1.MatchesService])
], MatchesController);
//# sourceMappingURL=matches.controller.js.map