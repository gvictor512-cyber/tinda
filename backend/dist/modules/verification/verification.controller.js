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
exports.VerificationController = void 0;
const common_1 = require("@nestjs/common");
const verification_service_1 = require("./verification.service");
const verify_email_dto_1 = require("./dto/verify-email.dto");
const verify_phone_dto_1 = require("./dto/verify-phone.dto");
const verify_selfie_dto_1 = require("./dto/verify-selfie.dto");
const auth_guard_1 = require("../../common/guards/auth.guard");
let VerificationController = class VerificationController {
    constructor(verificationService) {
        this.verificationService = verificationService;
    }
    async getVerificationStatus(req) {
        return this.verificationService.getVerificationStatus(req.user.uid);
    }
    async verifyEmail(req, verifyEmailDto) {
        return this.verificationService.verifyEmail(req.user.uid, verifyEmailDto);
    }
    async verifyPhone(req, verifyPhoneDto) {
        return this.verificationService.verifyPhone(req.user.uid, verifyPhoneDto);
    }
    async verifySelfie(req, verifySelfieDto) {
        return this.verificationService.verifySelfie(req.user.uid, verifySelfieDto);
    }
    async verifyDocument(req, documentUrl) {
        return this.verificationService.verifyDocument(req.user.uid, documentUrl);
    }
};
exports.VerificationController = VerificationController;
__decorate([
    (0, common_1.Get)('status'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], VerificationController.prototype, "getVerificationStatus", null);
__decorate([
    (0, common_1.Post)('email'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, verify_email_dto_1.VerifyEmailDto]),
    __metadata("design:returntype", Promise)
], VerificationController.prototype, "verifyEmail", null);
__decorate([
    (0, common_1.Post)('phone'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, verify_phone_dto_1.VerifyPhoneDto]),
    __metadata("design:returntype", Promise)
], VerificationController.prototype, "verifyPhone", null);
__decorate([
    (0, common_1.Post)('selfie'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, verify_selfie_dto_1.VerifySelfieDto]),
    __metadata("design:returntype", Promise)
], VerificationController.prototype, "verifySelfie", null);
__decorate([
    (0, common_1.Post)('document'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('documentUrl')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], VerificationController.prototype, "verifyDocument", null);
exports.VerificationController = VerificationController = __decorate([
    (0, common_1.Controller)('verification'),
    (0, common_1.UseGuards)(auth_guard_1.FirebaseAuthGuard),
    __metadata("design:paramtypes", [verification_service_1.VerificationService])
], VerificationController);
//# sourceMappingURL=verification.controller.js.map