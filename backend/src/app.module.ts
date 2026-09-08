import { Module } from '@nestjs/common';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { CacheModule } from '@nestjs/cache-manager';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import * as Joi from 'joi';
import { RolesGuard } from './common/guards/roles.guard';
import { SetFirebaseUidInterceptor } from './common/interceptors/set-firebase-uid.interceptor';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ProfilesModule } from './modules/profiles/profiles.module';
import { CompatibilityModule } from './modules/compatibility/compatibility.module';
import { MatchesModule } from './modules/matches/matches.module';
import { ChatModule } from './modules/chat/chat.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { FiltersModule } from './modules/filters/filters.module';
import { PremiumModule } from './modules/premium/premium.module';
import { DailyLimitsModule } from './modules/daily-limits/daily-limits.module';
import { VerificationModule } from './modules/verification/verification.module';
import { GroupsModule } from './modules/groups/groups.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { AdminModule } from './modules/admin/admin.module';

@Module({
  imports: [
    ConfigModule.forRoot({
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
    CacheModule.register({
      isGlobal: true,
      ttl: 60000,
      max: 1000,
    }),
    ThrottlerModule.forRoot([
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
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT) || 5432,
      username: process.env.DB_USERNAME || 'postgres',
      password: process.env.DB_PASSWORD,
      database: process.env.DB_DATABASE || 'roommatematch',
      entities: [__dirname + '/**/*.entity{.ts,.js}'],
      // synchronize SOLO cuando DB_SYNC=true (nunca por defecto en producción)
      synchronize: process.env.DB_SYNC === 'true',
      logging: process.env.NODE_ENV === 'development',
      ssl:
        process.env.NODE_ENV === 'production'
          ? { rejectUnauthorized: false }
          : false,
      // Connection pool tuning for concurrent users
      extra: {
        max: parseInt(process.env.DB_POOL_MAX, 10) || 20,
        min: parseInt(process.env.DB_POOL_MIN, 10) || 5,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 2000,
        acquireTimeoutMillis: 5000,
        statement_timeout: 30000,
      },
      // Graceful query and connection handling
      maxQueryExecutionTime: 5000,
    }),
    AuthModule,
    UsersModule,
    ProfilesModule,
    CompatibilityModule,
    MatchesModule,
    ChatModule,
    NotificationsModule,
    FiltersModule,
    PremiumModule,
    DailyLimitsModule,
    VerificationModule,
    GroupsModule,
    PaymentsModule,
    AdminModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: SetFirebaseUidInterceptor,
    },
    RolesGuard,
  ],
})
export class AppModule {}
