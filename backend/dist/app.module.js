"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const core_1 = require("@nestjs/core");
const typeorm_1 = require("@nestjs/typeorm");
const config_1 = require("@nestjs/config");
const throttler_1 = require("@nestjs/throttler");
const set_firebase_uid_interceptor_1 = require("./common/interceptors/set-firebase-uid.interceptor");
const auth_module_1 = require("./modules/auth/auth.module");
const users_module_1 = require("./modules/users/users.module");
const profiles_module_1 = require("./modules/profiles/profiles.module");
const compatibility_module_1 = require("./modules/compatibility/compatibility.module");
const matches_module_1 = require("./modules/matches/matches.module");
const chat_module_1 = require("./modules/chat/chat.module");
const notifications_module_1 = require("./modules/notifications/notifications.module");
const filters_module_1 = require("./modules/filters/filters.module");
const premium_module_1 = require("./modules/premium/premium.module");
const daily_limits_module_1 = require("./modules/daily-limits/daily-limits.module");
const verification_module_1 = require("./modules/verification/verification.module");
const groups_module_1 = require("./modules/groups/groups.module");
const payments_module_1 = require("./modules/payments/payments.module");
const admin_module_1 = require("./modules/admin/admin.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({
                isGlobal: true,
            }),
            throttler_1.ThrottlerModule.forRoot([
                {
                    ttl: 60_000,
                    limit: 60,
                },
            ]),
            typeorm_1.TypeOrmModule.forRoot({
                type: 'postgres',
                host: process.env.DB_HOST || 'localhost',
                port: parseInt(process.env.DB_PORT) || 5432,
                username: process.env.DB_USERNAME || 'postgres',
                password: process.env.DB_PASSWORD,
                database: process.env.DB_DATABASE || 'roommatematch',
                entities: [__dirname + '/**/*.entity{.ts,.js}'],
                synchronize: process.env.DB_USERNAME === 'postgres' &&
                    process.env.NODE_ENV === 'development',
                logging: process.env.NODE_ENV === 'development',
                ssl: process.env.NODE_ENV === 'production'
                    ? { rejectUnauthorized: true }
                    : false,
            }),
            auth_module_1.AuthModule,
            users_module_1.UsersModule,
            profiles_module_1.ProfilesModule,
            compatibility_module_1.CompatibilityModule,
            matches_module_1.MatchesModule,
            chat_module_1.ChatModule,
            notifications_module_1.NotificationsModule,
            filters_module_1.FiltersModule,
            premium_module_1.PremiumModule,
            daily_limits_module_1.DailyLimitsModule,
            verification_module_1.VerificationModule,
            groups_module_1.GroupsModule,
            payments_module_1.PaymentsModule,
            admin_module_1.AdminModule,
        ],
        providers: [
            {
                provide: core_1.APP_GUARD,
                useClass: throttler_1.ThrottlerGuard,
            },
            {
                provide: core_1.APP_INTERCEPTOR,
                useClass: set_firebase_uid_interceptor_1.SetFirebaseUidInterceptor,
            },
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map