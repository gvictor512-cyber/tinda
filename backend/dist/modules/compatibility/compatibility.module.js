"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CompatibilityModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const compatibility_controller_1 = require("./compatibility.controller");
const compatibility_service_1 = require("./compatibility.service");
const compatibility_settings_entity_1 = require("./entities/compatibility-settings.entity");
const profile_entity_1 = require("../profiles/entities/profile.entity");
const user_entity_1 = require("../users/entities/user.entity");
let CompatibilityModule = class CompatibilityModule {
};
exports.CompatibilityModule = CompatibilityModule;
exports.CompatibilityModule = CompatibilityModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([compatibility_settings_entity_1.CompatibilitySettings, profile_entity_1.Profile, user_entity_1.User]),
        ],
        controllers: [compatibility_controller_1.CompatibilityController],
        providers: [compatibility_service_1.CompatibilityService],
        exports: [compatibility_service_1.CompatibilityService],
    })
], CompatibilityModule);
//# sourceMappingURL=compatibility.module.js.map