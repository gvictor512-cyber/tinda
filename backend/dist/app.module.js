"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const core_1 = require("@nestjs/core");
const typeorm_1 = require("@nestjs/typeorm");
const config_1 = require("@nestjs/config");
const cache_manager_1 = require("@nestjs/cache-manager");
const throttler_1 = require("@nestjs/throttler");
const Joi = __importStar(require("joi"));
const roles_guard_1 = require("./common/guards/roles.guard");
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
const moderation_module_1 = require("./modules/moderation/moderation.module");
const app_check_middleware_1 = require("./common/middleware/app-check.middleware");
let AppModule = class AppModule {
    configure(consumer) {
        consumer.apply(app_check_middleware_1.AppCheckMiddleware).forRoutes('*');
    }
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({
                isGlobal: true,
                validationSchema: Joi.object({
                    NODE_ENV: Joi.string()
                        .valid('development', 'production', 'test')
                        .default('development'),
                    PORT: Joi.number().port().default(3000),
                    DB_HOST: Joi.string().hostname().default('localhost'),
                    DB_PORT: Joi.number().port().default(5432),
                    DB_USERNAME: Joi.string().required(),
                    DB_PASSWORD: Joi.string().required(),
                    DB_DATABASE: Joi.string().required(),
                    DB_SYNC: Joi.boolean().default(false),
                    DB_POOL_MIN: Joi.number().min(1).default(5),
                    DB_POOL_MAX: Joi.number().min(1).max(100).default(20),
                    CORS_ORIGIN: Joi.string().required(),
                    JWT_SECRET: Joi.string().min(32).required(),
                    REDIS_URL: Joi.string().uri().optional(),
                    STRIPE_SECRET_KEY: Joi.string().optional(),
                    FIREBASE_CLIENT_EMAIL: Joi.string().email().optional(),
                }),
                validationOptions: {
                    allowUnknown: true,
                    abortEarly: false,
                },
            }),
            cache_manager_1.CacheModule.register({
                isGlobal: true,
                ttl: 60000,
                max: 1000,
            }),
            throttler_1.ThrottlerModule.forRoot([
                {
                    name: 'burst',
                    ttl: 1000,
                    limit: 10,
                },
                {
                    name: 'ip',
                    ttl: 60_000,
                    limit: 60,
                },
                {
                    name: 'long',
                    ttl: 600_000,
                    limit: 500,
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
                synchronize: process.env.DB_SYNC === 'true',
                logging: process.env.NODE_ENV === 'development',
                ssl: process.env.NODE_ENV === 'production'
                    ? { rejectUnauthorized: false }
                    : false,
                extra: {
                    max: parseInt(process.env.DB_POOL_MAX, 10) || 20,
                    min: parseInt(process.env.DB_POOL_MIN, 10) || 5,
                    idleTimeoutMillis: 30000,
                    connectionTimeoutMillis: 2000,
                    acquireTimeoutMillis: 5000,
                    statement_timeout: 30000,
                },
                maxQueryExecutionTime: 5000,
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
            moderation_module_1.ModerationModule,
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
            roles_guard_1.RolesGuard,
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map