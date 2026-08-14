# RoomMate Match

Una aplicación móvil tipo Tinder para encontrar compañeros de piso compatibles.

## 📱 Descripción

RoomMate Match es una aplicación móvil nativa para iOS y Android que prioriza la compatibilidad entre personas por encima de la vivienda. El objetivo es reducir conflictos de convivencia mediante un algoritmo de matching inteligente.

## 🎯 Características Principales

### Core Features
- **Swipe Interface**: Interfaz similar a Tinder para deslizar perfiles
- **Algoritmo de Compatibilidad**: Sistema de matching basado en múltiples factores
- **Chat en Tiempo Real**: Mensajería privada con Socket.io
- **Sistema de Matches**: Notificaciones cuando hay match mutuo
- **Filtros Avanzados**: Búsqueda por edad, ciudad, presupuesto, hábitos, etc.

### Perfil y Compatibilidad
- Perfil personal con hasta 6 fotos
- Configuración de compatibilidad detallada:
  - Horarios (madrugador, nocturno, teletrabajo, etc.)
  - Nivel de limpieza (escala 1-5)
  - Preferencias sobre tabaco y mascotas
  - Rasgos de personalidad e intereses
  - Hábitos de convivencia

### Sistema Premium (Freemium)
- **Gratis**: 10 likes diarios, chat básico, filtros básicos
- **Premium**: Likes ilimitados, ver quién te dio like, filtros avanzados, boost del perfil, modo invisible

### Verificación
- Verificación de email
- Verificación de teléfono (SMS)
- Verificación con selfie
- Verificación de documento (opcional)

### Grupos de Convivencia
- Crear grupos con tus matches
- Calcular compatibilidad grupal
- Buscar más miembros para el grupo

### Integración con Plataformas de Alquiler
- Integración con Idealista y Fotocasa (API)
- Buscar pisos juntos con tu match
- Guardar favoritos y compartir

## 🏗️ Arquitectura

### Frontend (Mobile)
- **Framework**: Flutter 3.x
- **State Management**: Provider
- **Autenticación**: Firebase Auth
- **Base de Datos**: Cloud Firestore
- **Almacenamiento**: Firebase Storage
- **Notificaciones**: Firebase Cloud Messaging
- **Chat**: Socket.io Client

### Backend
- **Framework**: NestJS 10.x
- **Lenguaje**: TypeScript
- **Base de Datos**: PostgreSQL 15
- **ORM**: TypeORM
- **Autenticación**: Firebase Admin SDK
- **Real-time**: Socket.io
- **Validación**: class-validator
- **Documentación**: Swagger

### Infraestructura
- **Hosting**: Google Cloud Platform / AWS
- **Base de Datos**: Cloud SQL / RDS
- **Almacenamiento**: Firebase Storage
- **CI/CD**: GitHub Actions

## 📁 Estructura del Proyecto

```
roommate-match/
├── mobile/                          # Flutter App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── config/
│   │   ├── core/
│   │   ├── features/
│   │   └── utils/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── backend/                         # NestJS Backend
│   ├── src/
│   │   ├── main.ts
│   │   ├── app.module.ts
│   │   ├── config/
│   │   ├── common/
│   │   └── modules/
│   ├── test/
│   └── package.json
│
├── database/                        # PostgreSQL Schema
│   └── schema.sql
│
└── README.md
```

## 🚀 Instalación

### Prerrequisitos
- Node.js 18+
- Flutter 3.x
- PostgreSQL 15
- Firebase Project

### Backend Setup

```bash
cd backend
npm install
cp .env.example .env
# Configure las variables de entorno
npm run start:dev
```

### Mobile Setup

```bash
cd mobile
flutter pub get
# Configure firebase en android/ y ios/
flutter run
```

### Base de Datos

```bash
# Crear base de datos PostgreSQL
psql -U postgres -c "CREATE DATABASE roommatematch;"

# Ejecutar schema
psql -U postgres -d roommatematch -f database/schema.sql
```

## 🔧 Configuración

### Variables de Entorno (Backend)

```env
# Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your_password
DATABASE_NAME=roommatematch

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# JWT
JWT_SECRET=your-jwt-secret
JWT_EXPIRES_IN=7d

# Server
PORT=3000
NODE_ENV=development
```

### Firebase Config (Mobile)

Configurar `android/app/google-services.json` y `ios/GoogleService-Info.plist` con las credenciales de tu proyecto Firebase.

## 📊 Algoritmo de Compatibilidad

El algoritmo calcula un score de compatibilidad (0-100%) basado en:

- **Horarios** (15%): Compatibilidad de horarios diarios
- **Limpieza** (20%): Diferencia en nivel de orden
- **Tabaco** (15%): Preferencias sobre fumar
- **Mascotas** (10%): Actitud hacia animales
- **Personalidad** (15%): Intereses compartidos
- **Visitantes** (5%): Frecuencia de visitas
- **Cocina** (5%): Hábitos culinarios
- **Música/Ruido** (5%): Tolerancia al ruido
- **Teletrabajo** (10%): Trabajo remoto

## 🎨 Diseño

- **Estilo**: Moderno y minimalista
- **Inspiración**: Tinder, Airbnb, Spotify
- **Colores**: 
  - Primary Blue: #4A90E2
  - Primary Green: #50E3C2
  - Dark Background: #1A1A2E
  - Light Background: #FFFFFF
- **Dark Mode**: Soporte completo para modo oscuro
- **Animaciones**: Transiciones suaves y fluidas

## 📱 Screenshots

(Add screenshots when available)

## 🔒 Seguridad

| Feature | Implementación |
|---------|----------------|
| Autenticación | Firebase Auth + JWT |
| Comunicación | HTTPS + WSS |
| Base de Datos | PostgreSQL con encriptación |
| Almacenamiento | Firebase Storage |
| Validación | class-validator (backend) |
| Rate Limiting | @nestjs/throttler |

## 🧪 Testing

```bash
# Backend tests
cd backend
npm run test
npm run test:e2e

# Mobile tests
cd mobile
flutter test
```

## 📦 Build

### Backend

```bash
cd backend
npm run build
npm run start:prod
```

### Mobile (Android)

```bash
cd mobile
flutter build apk --release
flutter build appbundle --release
```

### Mobile (iOS)

```bash
cd mobile
flutter build ios --release
```

## 🚀 Deployment

### Backend
- Google Cloud Run / AWS ECS
- Cloud SQL / RDS para PostgreSQL
- Cloudflare / AWS CloudFront para CDN

### Mobile
- App Store (iOS)
- Google Play (Android)

## 📄 Licencia

Proprietary - All rights reserved

## 👥 Equipo

- Product Manager
- UX/UI Designer
- Software Architect
- Full Stack Developers
- QA Engineers

## 📞 Contacto

Para soporte o preguntas, contacta a: support@roommatematch.com
