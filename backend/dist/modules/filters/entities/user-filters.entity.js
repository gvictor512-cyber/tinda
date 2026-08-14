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
exports.UserFilters = void 0;
const typeorm_1 = require("typeorm");
let UserFilters = class UserFilters {
};
exports.UserFilters = UserFilters;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], UserFilters.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'user_id' }),
    __metadata("design:type", String)
], UserFilters.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'age_min', default: 18 }),
    __metadata("design:type", Number)
], UserFilters.prototype, "ageMin", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'age_max', default: 40 }),
    __metadata("design:type", Number)
], UserFilters.prototype, "ageMax", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'jsonb', default: '[]' }),
    __metadata("design:type", Array)
], UserFilters.prototype, "cities", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'budget_min', default: 300 }),
    __metadata("design:type", Number)
], UserFilters.prototype, "budgetMin", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'budget_max', default: 1000 }),
    __metadata("design:type", Number)
], UserFilters.prototype, "budgetMax", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'jsonb', default: '[]' }),
    __metadata("design:type", Array)
], UserFilters.prototype, "smokingPreferences", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'jsonb', default: '[]' }),
    __metadata("design:type", Array)
], UserFilters.prototype, "petsPreferences", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'work_from_home', nullable: true }),
    __metadata("design:type", Boolean)
], UserFilters.prototype, "workFromHome", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], UserFilters.prototype, "gender", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'jsonb', default: '[]' }),
    __metadata("design:type", Array)
], UserFilters.prototype, "languages", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'jsonb', default: '[]' }),
    __metadata("design:type", Array)
], UserFilters.prototype, "userTypes", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: 'created_at' }),
    __metadata("design:type", Date)
], UserFilters.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ name: 'updated_at' }),
    __metadata("design:type", Date)
], UserFilters.prototype, "updatedAt", void 0);
exports.UserFilters = UserFilters = __decorate([
    (0, typeorm_1.Entity)('user_filters')
], UserFilters);
//# sourceMappingURL=user-filters.entity.js.map