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
exports.CreateProfileDto = exports.CompatibilitySettingsDto = void 0;
const swagger_1 = require("@nestjs/swagger");
const class_validator_1 = require("class-validator");
class CompatibilitySettingsDto {
}
exports.CompatibilitySettingsDto = CompatibilitySettingsDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'madrugador', required: false }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(['madrugador', 'nocturno', 'trabajo_remoto', 'turnos', 'estudiante']),
    __metadata("design:type", String)
], CompatibilitySettingsDto.prototype, "scheduleType", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 4, required: false }),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.Min)(1),
    (0, class_validator_1.Max)(5),
    __metadata("design:type", Number)
], CompatibilitySettingsDto.prototype, "cleanlinessLevel", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'no_fuma', required: false }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(['no_fuma', 'fuma_fuera', 'fuma_dentro']),
    __metadata("design:type", String)
], CompatibilitySettingsDto.prototype, "smokingPreference", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'me_encantan', required: false }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(['me_encantan', 'tengo_mascotas', 'no_quiero_mascotas', 'soy_alergico']),
    __metadata("design:type", String)
], CompatibilitySettingsDto.prototype, "petsPreference", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: ['deportista', 'tranquilo'], required: false }),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.IsString)({ each: true }),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", Array)
], CompatibilitySettingsDto.prototype, "personalityTraits", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'a_veces', required: false }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(['nunca', 'a_veces', 'frecuentemente']),
    __metadata("design:type", String)
], CompatibilitySettingsDto.prototype, "guestsFrequency", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'ocasionalmente', required: false }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(['nunca', 'ocasionalmente', 'todos_los_dias']),
    __metadata("design:type", String)
], CompatibilitySettingsDto.prototype, "cookingFrequency", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'a_veces', required: false }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(['nunca', 'a_veces', 'mucho']),
    __metadata("design:type", String)
], CompatibilitySettingsDto.prototype, "musicVolume", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: true, required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsBoolean)(),
    __metadata("design:type", Boolean)
], CompatibilitySettingsDto.prototype, "workFromHome", void 0);
class CreateProfileDto {
}
exports.CreateProfileDto = CreateProfileDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'Juan' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateProfileDto.prototype, "firstName", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'García', required: false }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateProfileDto.prototype, "lastName", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 25, required: false }),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.Min)(18),
    (0, class_validator_1.Max)(100),
    __metadata("design:type", Number)
], CreateProfileDto.prototype, "age", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'male', required: false }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(['male', 'female', 'other']),
    __metadata("design:type", String)
], CreateProfileDto.prototype, "gender", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'Estudiante', required: false }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateProfileDto.prototype, "profession", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'Madrid' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateProfileDto.prototype, "city", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'Busco compañeros tranquilos y ordenados', required: false }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateProfileDto.prototype, "bio", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: ['https://example.com/photo1.jpg'], required: false }),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.IsString)({ each: true }),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", Array)
], CreateProfileDto.prototype, "photos", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 400, required: false }),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.Min)(300),
    __metadata("design:type", Number)
], CreateProfileDto.prototype, "budgetMin", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 600, required: false }),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.Min)(300),
    __metadata("design:type", Number)
], CreateProfileDto.prototype, "budgetMax", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'Centro', required: false }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateProfileDto.prototype, "preferredLocation", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: ['Español', 'Inglés'], required: false }),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.IsString)({ each: true }),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", Array)
], CreateProfileDto.prototype, "languages", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ required: false }),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", CompatibilitySettingsDto)
], CreateProfileDto.prototype, "compatibilitySettings", void 0);
//# sourceMappingURL=create-profile.dto.js.map