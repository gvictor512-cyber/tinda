# RoomMate Match - Project Structure

## Overview
Cross-platform mobile app (Flutter) + NestJS Backend + PostgreSQL + Firebase

## Directory Structure

```
roommate-match/
├── mobile/                          # Flutter App (iOS & Android)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── config/
│   │   │   ├── theme.dart
│   │   │   ├── routes.dart
│   │   │   └── constants.dart
│   │   ├── core/
│   │   │   ├── auth/
│   │   │   │   ├── auth_service.dart
│   │   │   │   ├── auth_provider.dart
│   │   │   │   └── login_screen.dart
│   │   │   ├── models/
│   │   │   │   ├── user.dart
│   │   │   │   ├── profile.dart
│   │   │   │   ├── match.dart
│   │   │   │   └── message.dart
│   │   │   ├── services/
│   │   │   │   ├── api_service.dart
│   │   │   │   ├── storage_service.dart
│   │   │   │   └── notification_service.dart
│   │   │   └── widgets/
│   │   │       ├── custom_card.dart
│   │   │       ├── swipe_card.dart
│   │   │       └── loading_indicator.dart
│   │   ├── features/
│   │   │   ├── profile/
│   │   │   │   ├── profile_screen.dart
│   │   │   │   ├── edit_profile_screen.dart
│   │   │   │   ├── photo_upload.dart
│   │   │   │   └── compatibility_settings.dart
│   │   │   ├── swipe/
│   │   │   │   ├── swipe_screen.dart
│   │   │   │   ├── profile_card.dart
│   │   │   │   └── compatibility_badge.dart
│   │   │   ├── match/
│   │   │   │   ├── match_screen.dart
│   │   │   │   ├── match_animation.dart
│   │   │   │   └── match_list.dart
│   │   │   ├── chat/
│   │   │   │   ├── chat_screen.dart
│   │   │   │   ├── chat_list_screen.dart
│   │   │   │   ├── message_bubble.dart
│   │   │   │   └── chat_service.dart
│   │   │   ├── housing/
│   │   │   │   ├── housing_search_screen.dart
│   │   │   │   ├── housing_card.dart
│   │   │   │   ├── favorites_screen.dart
│   │   │   │   └── shared_list_screen.dart
│   │   │   ├── group/
│   │   │   │   ├── group_creation_screen.dart
│   │   │   │   ├── group_screen.dart
│   │   │   │   └── group_compatibility.dart
│   │   │   ├── premium/
│   │   │   │   ├── premium_screen.dart
│   │   │   │   ├── subscription_screen.dart
│   │   │   │   └── features_list.dart
│   │   │   ├── filters/
│   │   │   │   ├── filters_screen.dart
│   │   │   │   └── filter_chip.dart
│   │   │   ├── verification/
│   │   │   │   ├── verification_screen.dart
│   │   │   │   ├── email_verification.dart
│   │   │   │   ├── phone_verification.dart
│   │   │   │   └── selfie_verification.dart
│   │   │   └── settings/
│   │   │       ├── settings_screen.dart
│   │   │       ├── privacy_settings.dart
│   │   │       └── notification_settings.dart
│   │   └── utils/
│   │       ├── helpers.dart
│   │       ├── validators.dart
│   │       └── formatters.dart
│   ├── android/
│   ├── ios/
│   ├── test/
│   └── pubspec.yaml
│
├── backend/                         # NestJS Backend
│   ├── src/
│   │   ├── main.ts
│   │   ├── app.module.ts
│   │   ├── config/
│   │   │   ├── database.config.ts
│   │   │   ├── firebase.config.ts
│   │   │   └── environment.config.ts
│   │   ├── common/
│   │   │   ├── guards/
│   │   │   │   ├── auth.guard.ts
│   │   │   │   └── roles.guard.ts
│   │   │   ├── decorators/
│   │   │   │   └── roles.decorator.ts
│   │   │   ├── filters/
│   │   │   │   └── http-exception.filter.ts
│   │   │   └── interceptors/
│   │   │       └── logging.interceptor.ts
│   │   ├── modules/
│   │   │   ├── auth/
│   │   │   │   ├── auth.module.ts
│   │   │   │   ├── auth.controller.ts
│   │   │   │   ├── auth.service.ts
│   │   │   │   ├── strategies/
│   │   │   │   │   └── firebase.strategy.ts
│   │   │   │   └── dto/
│   │   │   │       ├── login.dto.ts
│   │   │   │       └── register.dto.ts
│   │   │   ├── users/
│   │   │   │   ├── users.module.ts
│   │   │   │   ├── users.controller.ts
│   │   │   │   ├── users.service.ts
│   │   │   │   ├── entities/
│   │   │   │   │   └── user.entity.ts
│   │   │   │   └── dto/
│   │   │   │       ├── create-user.dto.ts
│   │   │   │       └── update-user.dto.ts
│   │   │   ├── profiles/
│   │   │   │   ├── profiles.module.ts
│   │   │   │   ├── profiles.controller.ts
│   │   │   │   ├── profiles.service.ts
│   │   │   │   ├── entities/
│   │   │   │   │   └── profile.entity.ts
│   │   │   │   └── dto/
│   │   │   │       ├── create-profile.dto.ts
│   │   │   │       └── update-profile.dto.ts
│   │   │   ├── compatibility/
│   │   │   │   ├── compatibility.module.ts
│   │   │   │   ├── compatibility.controller.ts
│   │   │   │   ├── compatibility.service.ts
│   │   │   │   ├── algorithm/
│   │   │   │   │   ├── compatibility-calculator.ts
│   │   │   │   │   └── weight-config.ts
│   │   │   │   └── dto/
│   │   │   │       └── compatibility.dto.ts
│   │   │   ├── matches/
│   │   │   │   ├── matches.module.ts
│   │   │   │   ├── matches.controller.ts
│   │   │   │   ├── matches.service.ts
│   │   │   │   ├── entities/
│   │   │   │   │   └── match.entity.ts
│   │   │   │   └── dto/
│   │   │   │       ├── create-match.dto.ts
│   │   │   │       └── swipe.dto.ts
│   │   │   ├── chat/
│   │   │   │   ├── chat.module.ts
│   │   │   │   ├── chat.gateway.ts
│   │   │   │   ├── chat.service.ts
│   │   │   │   ├── entities/
│   │   │   │   │   └── message.entity.ts
│   │   │   │   └── dto/
│   │   │   │       └── message.dto.ts
│   │   │   ├── housing/
│   │   │   │   ├── housing.module.ts
│   │   │   │   ├── housing.controller.ts
│   │   │   │   ├── housing.service.ts
│   │   │   │   ├── entities/
│   │   │   │   │   └── housing.entity.ts
│   │   │   │   ├── integrations/
│   │   │   │   │   ├── idealista.service.ts
│   │   │   │   │   └── fotocasa.service.ts
│   │   │   │   └── dto/
│   │   │   │       └── housing.dto.ts
│   │   │   ├── groups/
│   │   │   │   ├── groups.module.ts
│   │   │   │   ├── groups.controller.ts
│   │   │   │   ├── groups.service.ts
│   │   │   │   ├── entities/
│   │   │   │   │   └── group.entity.ts
│   │   │   │   └── dto/
│   │   │   │       └── group.dto.ts
│   │   │   ├── premium/
│   │   │   │   ├── premium.module.ts
│   │   │   │   ├── premium.controller.ts
│   │   │   │   ├── premium.service.ts
│   │   │   │   ├── entities/
│   │   │   │   │   └── subscription.entity.ts
│   │   │   │   └── dto/
│   │   │   │       └── subscription.dto.ts
│   │   │   ├── verification/
│   │   │   │   ├── verification.module.ts
│   │   │   │   ├── verification.controller.ts
│   │   │   │   ├── verification.service.ts
│   │   │   │   ├── entities/
│   │   │   │   │   └── verification.entity.ts
│   │   │   │   └── dto/
│   │   │   │       └── verification.dto.ts
│   │   │   ├── notifications/
│   │   │   │   ├── notifications.module.ts
│   │   │   │   ├── notifications.controller.ts
│   │   │   │   ├── notifications.service.ts
│   │   │   │   └── dto/
│   │   │   │       └── notification.dto.ts
│   │   │   ├── gamification/
│   │   │   │   ├── gamification.module.ts
│   │   │   │   ├── gamification.controller.ts
│   │   │   │   ├── gamification.service.ts
│   │   │   │   ├── entities/
│   │   │   │   │   └── badge.entity.ts
│   │   │   │   └── dto/
│   │   │   │       └── badge.dto.ts
│   │   │   ├── ai/
│   │   │   │   ├── ai.module.ts
│   │   │   │   ├── ai.controller.ts
│   │   │   │   ├── ai.service.ts
│   │   │   │   └── dto/
│   │   │   │       └── recommendation.dto.ts
│   │   │   └── admin/
│   │   │       ├── admin.module.ts
│   │   │       ├── admin.controller.ts
│   │   │       ├── admin.service.ts
│   │   │       └── dto/
│   │   │           └── admin.dto.ts
│   │   └── database/
│   │       ├── migrations/
│   │       └── seeds/
│   ├── test/
│   ├── package.json
│   ├── tsconfig.json
│   └── nest-cli.json
│
├── database/                        # PostgreSQL Schema
│   ├── schema.sql
│   ├── migrations/
│   └── seeds/
│
├── docs/                           # Documentation
│   ├── API.md
│   ├── DEPLOYMENT.md
│   └── DEVELOPMENT.md
│
└── README.md
```

## Technology Stack

### Frontend (Mobile)
- **Framework**: Flutter 3.x
- **State Management**: Provider / Riverpod
- **Navigation**: GoRouter
- **Networking**: Dio
- **Local Storage**: Hive / SharedPreferences
- **Firebase**: FlutterFire
- **UI Components**: Material Design 3

### Backend
- **Framework**: NestJS 10.x
- **Language**: TypeScript
- **Database**: PostgreSQL 15
- **ORM**: TypeORM
- **Authentication**: Firebase Auth
- **Real-time**: Socket.io
- **Validation**: class-validator
- **Documentation**: Swagger

### Infrastructure
- **Hosting**: Google Cloud Platform / AWS
- **Database**: Cloud SQL / RDS
- **Storage**: Firebase Storage
- **Notifications**: Firebase Cloud Messaging
- **CI/CD**: GitHub Actions
