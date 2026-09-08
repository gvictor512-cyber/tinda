# RoomMate Match - Pasos de lanzamiento que debes completar

He preparado el código y la configuración local. Esto es lo que **sólo tú puedes hacer** para publicar la app.

## ✅ Lo que ya está listo

- **Android keystore**: `mobile/android/upload-keystore.jks` y `mobile/android/key.properties`.
  - Contraseña temporal: `RoomMateMatch2026!`.
  - **Cámbiala y guarda la contraseña en un lugar seguro** antes de publicar.
- **Build AAB firmado**: generado en `mobile/build/app/outputs/bundle/release/app-release.aab`.
  - El comando `flutter build appbundle` falla por falta de `cmdline-tools`, pero `./gradlew :app:bundleRelease` en `mobile/android` funciona.
- **Pagos en tiendas (IAP)**: se ha añadido `in_app_purchase` y un `IapService` en `mobile/lib/services/iap_service.dart`.
  - La pantalla de premium (`premium_screen.dart`) ya usa el flujo nativo de compras.
  - Stripe se mantiene solo para la versión web (`kIsWeb`).
- **Backend PostgreSQL**: `backend/docker-compose.yml` levanta PostgreSQL y aplica `database/schema.sql` y `database/rls.sql`.
- **Script de roles**: `database/setup_roles.sh` crea el usuario `app_user` al iniciar PostgreSQL.

## 📋 Pendiente obligatorio antes del lanzamiento

### 1. Cuentas de desarrollador

- [ ] **Google Play Console**: 25 $, https://play.google.com/console
- [ ] **Apple Developer**: 99 $/año, https://developer.apple.com
- [ ] Completar verificación de identidad en ambas.

### 2. Proyecto Firebase real

- [ ] Crear proyecto en https://console.firebase.google.com
- [ ] Añadir app Android (`com.roommatematch.app`):
  - Descargar `google-services.json` y colocarlo en `mobile/android/app/google-services.json`
- [ ] Añadir app iOS:
  - Descargar `GoogleService-Info.plist` y colocarlo en `mobile/ios/Runner/GoogleService-Info.plist`
- [ ] Habilitar Authentication:
  - Email/Password
  - Google Sign-In
  - Apple Sign-In (iOS)
- [ ] Crear Firestore Database y subir reglas (`database/firestore.rules`)
- [ ] Activar Firebase Storage y subir reglas (`database/storage.rules`)
- [ ] Activar Firebase Cloud Messaging

### 3. Productos de pago en las tiendas

En Google Play Console y App Store Connect, crear los productos con **exactamente** estos IDs:

| ID            | Tipo       | Precio orientativo |
|---------------|------------|--------------------|
| premium_monthly | Suscripción | 9,99 €/mes        |
| premium_annual  | Suscripción | 79,99 €/año       |
| boost           | Consumible  | 1,99 €            |
| super_like      | Consumible  | 0,99 €            |
| premium_verification | Consumible | 2,99 €       |
| highlight_listing    | Consumible | 3,99 €       |

- [ ] Configurar impuestos y precios por país.
- [ ] Activar los productos en ambas consolas.

### 4. Backend y base de datos

- [ ] Levantar PostgreSQL:
  ```powershell
  cd backend
  docker-compose up -d
  ```
- [ ] Copiar `backend/.env.example` a `backend/.env` y rellenar con:
  - `STRIPE_SECRET_KEY`
  - `STRIPE_WEBHOOK_SECRET`
  - `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`
  - `DB_PASSWORD` (la contraseña que uses para `app_user`)
  - `JWT_SECRET` (cadena larga aleatoria)
- [ ] Ejecutar `npm install` y `npm run start:prod`.
- [ ] Desplegar en un servidor accesible (Render, GCP, AWS, etc.) y actualizar `BACKEND_BASE_URL`.

### 5. Firma y build final

- [ ] Cambiar la contraseña del keystore generado y actualizar `key.properties`.
- [ ] Ejecutar:
  ```powershell
  cd mobile
  flutter build appbundle --release
  ```
- [ ] Subir el AAB a Google Play Console (track interno).
- [ ] Desde Mac con Xcode, hacer Archive y subir el IPA a App Store Connect.

### 6. Testing en dispositivos reales

- [ ] Registrar testers internos en ambas consolas.
- [ ] Probar flujo de registro, login, swipe, match, chat, pago premium y restaurar compras.
- [ ] Probar en red lenta (3G) y dispositivos antiguos.

### 7. Legal y tiendas

- [ ] Subir política de privacidad pública.
- [ ] Completar Data Safety de Google Play.
- [ ] Responder cuestionario de clasificación de contenido.
- [ ] Rellenar descripción, screenshots, keywords y assets en ambas consolas.

---

**Nota importante**: no puedo realizar por ti los pagos, las altas de cuenta ni la configuración de consolas externas. Una vez completados estos pasos, el proyecto estará listo para publicar.

---

© 2026 RoomMate Match. Todos los derechos reservados.
