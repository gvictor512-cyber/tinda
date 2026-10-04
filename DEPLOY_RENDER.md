# Despliegue en Render

## Creado

- `backend/Dockerfile` → imagen Docker del backend NestJS.
- `backend/.dockerignore` → evita subir archivos innecesarios.
- `render.yaml` → Blueprint de Render con:
  - Web service `roommatematch-api`.
  - Base de datos PostgreSQL `roommatematch-db`.
  - Variables de entorno sensibles marcadas como `sync: false` (las rellenarás en el dashboard de Render).

## Pasos en Render

1. Sube el proyecto a un repositorio de **GitHub**.
2. Ve a https://dashboard.render.com y regístrate/inicia sesión.
3. Haz clic en **New +** → **Blueprint**.
4. Conecta tu repositorio de GitHub.
5. Render leerá `render.yaml` y creará:
   - El servicio web.
   - La base de datos PostgreSQL.
6. En el dashboard del servicio web, ve a **Environment**.
7. Añade las variables de entorno que faltan:
   - `STRIPE_SECRET_KEY` → tu `sk_live_...` o `sk_test_...`.
   - `STRIPE_WEBHOOK_SECRET` → el `whsec_...` del webhook.
   - `STRIPE_DESTINATION_BANK_ACCOUNT` → tu IBAN real.
   - `FIREBASE_PROJECT_ID` → ID de tu proyecto Firebase.
   - `FIREBASE_PRIVATE_KEY` → clave privada de Firebase Admin.
   - `FIREBASE_CLIENT_EMAIL` → email del servicio de Firebase.
   - `JWT_SECRET` → Render ya la generó automáticamente.
   - `RESEND_API_KEY` → API key de https://resend.com (emails de factura de compra).
   - `MAIL_FROM` → remitente verificado en Resend, p. ej. `RoomMate Match <facturas@roommatematchapp.com>`.
8. Render desplegará tu backend automáticamente.

## Facturas por email

Tras cada compra IAP la app llama a `POST /payments/receipt`, que registra el
pago en la tabla `payments` y envía la factura al email del usuario. Se usa la
API HTTP de [Resend](https://resend.com) (los puertos SMTP están bloqueados en
Render). Para que los emails lleguen a cualquier usuario debes verificar tu
dominio en Resend (DNS) o, en pruebas, usar el remitente `onboarding@resend.dev`.

## URL del backend

Una vez desplegado, tu URL será algo como:

```text
https://roommatematch-api.onrender.com
```

Si Render te asigna otra URL, actualiza:
- `BACKEND_BASE_URL` en el servicio web de Render.
- La URL del webhook en Stripe: `https://TU_URL/payments/webhook`.

## Actualizar Stripe

Después del primer despliegue, entra en Stripe, edita el webhook y pon:

```text
https://roommatematch-api.onrender.com/payments/webhook
```

## Conectar Flutter

En `mobile/.env` o donde configures la URL del backend, usa:

```env
BACKEND_BASE_URL=https://roommatematch-api.onrender.com
```

Para Android emulador sigue siendo `10.0.2.2:3000` para desarrollo local.
