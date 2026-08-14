"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.FirebaseStrategy = void 0;
const common_1 = require("@nestjs/common");
const passport_1 = require("@nestjs/passport");
const passport_custom_1 = require("passport-custom");
const firebase_config_1 = require("../config/firebase.config");
let FirebaseStrategy = class FirebaseStrategy extends (0, passport_1.PassportStrategy)(passport_custom_1.Strategy, 'firebase') {
    async validate(req) {
        const idToken = req.headers?.authorization?.replace('Bearer ', '');
        if (!idToken) {
            throw new common_1.UnauthorizedException('No token provided');
        }
        try {
            const decodedToken = await firebase_config_1.admin.auth().verifyIdToken(idToken);
            return {
                uid: decodedToken.uid,
                email: decodedToken.email,
            };
        }
        catch (error) {
            throw new common_1.UnauthorizedException('Invalid token');
        }
    }
};
exports.FirebaseStrategy = FirebaseStrategy;
exports.FirebaseStrategy = FirebaseStrategy = __decorate([
    (0, common_1.Injectable)()
], FirebaseStrategy);
//# sourceMappingURL=firebase.strategy.js.map