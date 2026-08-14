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
exports.UpdateFiltersDto = void 0;
const swagger_1 = require("@nestjs/swagger");
const class_validator_1 = require("class-validator");
class UpdateFiltersDto {
}
exports.UpdateFiltersDto = UpdateFiltersDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: 18, required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(18),
    (0, class_validator_1.Max)(100),
    __metadata("design:type", Number)
], UpdateFiltersDto.prototype, "ageMin", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 40, required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(18),
    (0, class_validator_1.Max)(100),
    __metadata("design:type", Number)
], UpdateFiltersDto.prototype, "ageMax", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: ['Madrid', 'Barcelona'], required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.IsString)({ each: true }),
    __metadata("design:type", Array)
], UpdateFiltersDto.prototype, "cities", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 300, required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], UpdateFiltersDto.prototype, "budgetMin", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 1000, required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], UpdateFiltersDto.prototype, "budgetMax", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: ['no_fuma', 'fuma_fuera'], required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.IsString)({ each: true }),
    __metadata("design:type", Array)
], UpdateFiltersDto.prototype, "smokingPreferences", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: ['me_encantan', 'tengo_mascotas'], required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.IsString)({ each: true }),
    __metadata("design:type", Array)
], UpdateFiltersDto.prototype, "petsPreferences", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: true, required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsBoolean)(),
    __metadata("design:type", Boolean)
], UpdateFiltersDto.prototype, "workFromHome", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'male', required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsEnum)(['male', 'female', 'other']),
    __metadata("design:type", String)
], UpdateFiltersDto.prototype, "gender", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: ['Español', 'Inglés'], required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.IsString)({ each: true }),
    __metadata("design:type", Array)
], UpdateFiltersDto.prototype, "languages", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: ['Estudiante', 'Profesional'], required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.IsString)({ each: true }),
    __metadata("design:type", Array)
], UpdateFiltersDto.prototype, "userTypes", void 0);
//# sourceMappingURL=update-filters.dto.js.map