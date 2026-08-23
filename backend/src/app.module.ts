import { Module } from '@nestjs/common';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
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
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60_000,
        limit: 60,
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
      // synchronize solo para superusuario (postgres) en dev; con app_user se desactiva
      synchronize:
        process.env.DB_USERNAME === 'postgres' &&
        process.env.NODE_ENV === 'development',
      logging: process.env.NODE_ENV === 'development',
      ssl:
        process.env.NODE_ENV === 'production'
          ? { rejectUnauthorized: false }
          : false,
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
  ],
})
export class AppModule {}
