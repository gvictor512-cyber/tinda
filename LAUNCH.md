# Guía de Lanzamiento - RoomMate Match

Resumen de lo que queda para lanzar la app, con los pasos que ya están preparados y los que requieren acción manual externa.

## Estado actual del código

| Componente | Estado |
|------------|--------|
| App Flutter | Construye release APK y AAB firmado. Web, Windows, Linux y macOS disponibles. |
| Backend NestJS | Compila correctamente. Admin endpoints listos. |
| Base de datos | Esquema PostgreSQL y SQLite local listos. |
| SEO | Metadatos y sitemap configurados para web. |
| Escritorio | Directorios `windows/`, `macos/`, `linux/` configurados. |

## Builds disponibles

### Android
```powershell
cd mobile
flutter build apk --release          # APK de test/local
flutter build appbundle --release    # AAB para Google Play (requiere cmdline-tools)
```

Si `flutter build appbundle` falla por `strip debug symbols`, compila directamente con Gradle:
```powershell
cd mobile/android
.\gradlew.bat :app:bundleRelease
```

**Build AAB firmado**: `mobile/build/app/outputs/bundle/release/app-release.aab` (~19 MB).

**Automatizado**: Ejecuta `mobile/build_release.ps1` para generar APK y AAB juntos.

**Producción Android**: Revisa `mobile/android/app/proguard-rules.pro` (Stripe, Firebase, in-app purchase) y `AndroidManifest.xml` (etiqueta `RoomMate Match`).

### Web
```powershell
cd mobile
flutter build web --release --base-href /
```

### Windows (escritorio)
```powershell
cd mobile
flutter build windows --release
```

### iOS
Requiere una Mac con Xcode. No se puede construir desde Windows.

```bash
cd mobile/ios
open Runner.xcworkspace
# Product > Archive y subir a App Store Connect
```

### Backend
```powershell
cd backend
npm install
npm run build
npm run start:prod
```

Necesita PostgreSQL levantado y el archivo `.env` completado con valores reales.

## Pasos manuales imprescindibles que no puedo hacer por ti

### 1. Cuentas de desarrollador
- **Google Play Console**: $25 one-time. https://play.google.com/console
- **Apple Developer**: $99/año. Requiere Mac. https://developer.apple.com

### 2. Proyecto Firebase real
- Crear proyecto en https://console.firebase.google.com
- Añadir apps Android e iOS.
- Descargar y colocar:
  - `mobile/android/app/google-services.json`
  - `mobile/ios/Runner/GoogleService-Info.plist`
- Habilitar Authentication (Email/Password, Google, Apple).
- Configurar Firestore, Storage y Cloud Messaging.

### 3. Keystore de Android
Generar en `mobile/android/`:

```powershell
cd mobile/android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Crear `mobile/android/key.properties` a partir de `key.properties.example`:

```properties
storePassword=TU_CONTRASEÑA
keyPassword=TU_CONTRASEÑA
keyAlias=upload
storeFile=C:\ruta\absoluta\a\upload-keystore.jks
```

### 4. PostgreSQL real
- Crear base de datos `roommatematch`.
- Ejecutar `database/schema.sql`.
- Completar `backend/.env` con host, usuario y contraseña.

### 5. Pagos (IAP nativo)
- El código usa `in_app_purchase` y `IapService` para Google Play Billing / StoreKit.
- Crea los productos/suscripciones en Google Play Console y App Store Connect con los IDs listados en `LAUNCH_NEXT_STEPS.md`.
- Stripe se mantiene solo para web (`STRIPE_SECRET_KEY` y `STRIPE_WEBHOOK_SECRET` en `backend/.env`).

### 6. Legal y tiendas
- URL pública de política de privacidad.
- Cuentas de redes sociales y dominios.
- Proceso de data safety en Google Play.
- Responder cuestionario de clasificación de contenido.

## Orden de trabajo recomendado

1. Configurar Firebase real y probar autenticación.
2. Implementar matching, chat y perfil completo.
3. Configurar pagos y suscripciones.
4. Levantar backend y PostgreSQL.
5. Generar keystore y builds firmados.
6. Crear cuentas de desarrollador.
7. Subir a tracks internos y probar con usuarios reales.

## Archivos de ayuda creados

- `INSTRUCCIONES_PUBLICACION.md` → pasos detallados para Android e iOS.
- `PUBLICATION_CHECKLIST.md` → checklist completo de publicación.
- `LEGAL_PROTECTION_CHECKLIST.md` → protección legal, marca y dominios.
- `local_database/` → base de datos SQLite local para pruebas y visor.

## Nota importante

El código compila y los assets están listos. Lo que falta son cuentas externas (Google, Apple, Firebase, Stripe, PostgreSQL) y la conexión real de esos servicios. Sin eso, la app funciona en local pero no puede publicarse ni operar con usuarios reales.

---

© 2026 RoomMate Match. Todos los derechos reservados.
