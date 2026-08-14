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
Object.defineProperty(exports, "__esModule", { value: true });
exports.Verification = void 0;
const typeorm_1 = require("typeorm");
let Verification = class Verification {
};
exports.Verification = Verification;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Verification.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'user_id' }),
    __metadata("design:type", String)
], Verification.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'email_verified', default: false }),
    __metadata("design:type", Boolean)
], Verification.prototype, "emailVerified", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'email_verified_at', type: 'timestamp', nullable: true }),
    __metadata("design:type", Date)
], Verification.prototype, "emailVerifiedAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'phone_verified', default: false }),
    __metadata("design:type", Boolean)
], Verification.prototype, "phoneVerified", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'phone_verified_at', type: 'timestamp', nullable: true }),
    __metadata("design:type", Date)
], Verification.prototype, "phoneVerifiedAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'selfie_verified', default: false }),
    __metadata("design:type", Boolean)
], Verification.prototype, "selfieVerified", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'selfie_verified_at', type: 'timestamp', nullable: true }),
    __metadata("design:type", Date)
], Verification.prototype, "selfieVerifiedAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'document_verified', default: false }),
    __metadata("design:type", Boolean)
], Verification.prototype, "documentVerified", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'document_verified_at', type: 'timestamp', nullable: true }),
    __metadata("design:type", Date)
], Verification.prototype, "documentVerifiedAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'document_url', nullable: true }),
    __metadata("design:type", String)
], Verification.prototype, "documentUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'is_verified', default: false }),
    __metadata("design:type", Boolean)
], Verification.prototype, "isVerified", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'verification_level' }),
    __metadata("design:type", String)
], Verification.prototype, "verificationLevel", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: 'created_at' }),
    __metadata("design:type", Date)
], Verification.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ name: 'updated_at' }),
    __metadata("design:type", Date)
], Verification.prototype, "updatedAt", void 0);
exports.Verification = Verification = __decorate([
    (0, typeorm_1.Entity)('verification')
], Verification);
//# sourceMappingURL=verification.entity.js.map