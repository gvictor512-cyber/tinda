# Guía de Configuración de Stripe para RoomMate Match

## 1. Crear cuenta en Stripe

- Ve a https://stripe.com y crea una cuenta (modo test primero).
- Activa el modo de pago real cuando estés listo.

## 2. Obtener claves de API

1. En el dashboard de Stripe, ve a **Desarrolladores → Claves API**.
2. Copia la **Secret key** (empieza por `sk_test_` o `sk_live_`).
3. Abre `backend/.env` y añade:

```env
STRIPE_SECRET_KEY=sk_test_TU_CLAVE
```

## 3. Configurar el webhook

1. Ve a **Desarrolladores → Webhooks**.
2. Añade un endpoint:
   - URL: `https://TU_BACKEND_URL/payments/webhook`
   - O en local para pruebas: `http://localhost:3000/payments/webhook`
3. Selecciona los eventos:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `charge.succeeded` (opcional)
   - `invoice.payment_succeeded` (si usas suscripciones)
4. Stripe te dará un **Signing secret** (`whsec_...`). Copia y pégalo en `backend/.env`:

```env
STRIPE_WEBHOOK_SECRET=whsec_TU_SECRETO
```

## 4. Configurar la cuenta bancaria de destino

Tu IBAN real ya está en `backend/.env`:

```env
STRIPE_DESTINATION_BANK_ACCOUNT=ES5101829732190202180050
```

Si quieres cambiarlo:

1. En Stripe, ve a **Configuración → Cuenta bancaria**.
2. Verifica tu cuenta bancaria con los documentos que pida Stripe.
3. Copia el IBAN verificado en `backend/.env`.

## 5. Para pagos desde la app móvil

- La app usa `flutter_stripe` para mostrar la hoja de pago (PaymentSheet).
- El flujo normal:
  1. App pide al backend un `PaymentIntent`.
  2. Backend crea el `PaymentIntent` con Stripe y devuelve `clientSecret`.
  3. App muestra el PaymentSheet con `flutter_stripe`.
  4. Stripe cobra al usuario y notifica al backend vía webhook.

## 6. Para suscripciones mensuales/anuales

- Crea productos en Stripe: `Premium Mensual` y `Premium Anual`.
- Crea precios recurrentes para cada uno.
- Guarda los `price_id` y úsalos en el backend para generar `Subscription`.
- En iOS/Android, para compras dentro de la app Apple/Google exigen usar sus in-app purchases, no Stripe directamente.

## 7. Variables mínimas en `backend/.env`

```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_DESTINATION_BANK_ACCOUNT=ES5101829732190202180050
```

## 8. Prueba

1. Inicia el backend:
   ```powershell
   cd backend
   npm run start:dev
   ```
2. Crea un PaymentIntent de prueba:
   ```powershell
   curl -X POST http://localhost:3000/payments/intent -d '{"amount": 1000, "currency": "eur"}'
   ```
3. Usa una tarjeta de prueba de Stripe, por ejemplo:
   - Número: `4242 4242 4242 4242`
   - Fecha: cualquier futura
   - CVC: cualquier 3 dígitos

## 9. Antes de producción

- Cambia `sk_test_` por `sk_live_` y el webhook a tu dominio real.
- Asegúrate de que `BACKEND_BASE_URL` apunta a tu backend real.
- Verifica tu identidad y cuenta bancaria en Stripe.
- Configura impuestos si es necesario.
