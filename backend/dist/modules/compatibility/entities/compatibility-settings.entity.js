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
exports.CompatibilitySettings = void 0;
const typeorm_1 = require("typeorm");
let CompatibilitySettings = class CompatibilitySettings {
};
exports.CompatibilitySettings = CompatibilitySettings;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], CompatibilitySettings.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'user_id' }),
    __metadata("design:type", String)
], CompatibilitySettings.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'schedule_type', nullable: true }),
    __metadata("design:type", String)
], CompatibilitySettings.prototype, "scheduleType", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'cleanliness_level', nullable: true }),
    __metadata("design:type", Number)
], CompatibilitySettings.prototype, "cleanlinessLevel", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'smoking_preference', nullable: true }),
    __metadata("design:type", String)
], CompatibilitySettings.prototype, "smokingPreference", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'pets_preference', nullable: true }),
    __metadata("design:type", String)
], CompatibilitySettings.prototype, "petsPreference", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'jsonb', default: '[]' }),
    __metadata("design:type", Array)
], CompatibilitySettings.prototype, "personalityTraits", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'guests_frequency', nullable: true }),
    __metadata("design:type", String)
], CompatibilitySettings.prototype, "guestsFrequency", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'cooking_frequency', nullable: true }),
    __metadata("design:type", String)
], CompatibilitySettings.prototype, "cookingFrequency", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'music_volume', nullable: true }),
    __metadata("design:type", String)
], CompatibilitySettings.prototype, "musicVolume", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'work_from_home', default: false }),
    __metadata("design:type", Boolean)
], CompatibilitySettings.prototype, "workFromHome", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: 'created_at' }),
    __metadata("design:type", Date)
], CompatibilitySettings.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ name: 'updated_at' }),
    __metadata("design:type", Date)
], CompatibilitySettings.prototype, "updatedAt", void 0);
exports.CompatibilitySettings = CompatibilitySettings = __decorate([
    (0, typeorm_1.Entity)('compatibility_settings')
], CompatibilitySettings);
//# sourceMappingURL=compatibility-settings.entity.js.map