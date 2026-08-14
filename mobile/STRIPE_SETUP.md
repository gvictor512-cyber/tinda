# Configuración de Stripe para Pagos In-App

## Resumen
Esta guía explica cómo configurar Stripe para procesar pagos en la aplicación RoomMate Match. Los fondos se transferirán automáticamente a la cuenta bancaria especificada: **ES5101829726210202180050**.

## Requisitos Previos

1. **Cuenta de Stripe**
   - Regístrate en [stripe.com](https://stripe.com)
   - Completa la verificación de identidad
   - Verifica tu cuenta bancaria

2. **Cuenta Bancaria de Destino**
   - IBAN: ES5101829726210202180050
   - Esta cuenta debe estar verificada en tu cuenta de Stripe

## Pasos de Configuración

### 1. Obtener las API Keys

1. Inicia sesión en tu [Dashboard de Stripe](https://dashboard.stripe.com)
2. Ve a **Developers** > **API keys**
3. Copia las siguientes keys:
   - **Publishable Key** (pk_test_...) - Para usar en la app
   - **Secret Key** (sk_test_...) - Para usar en el backend (Cloud Functions)

### 2. Configurar la Cuenta Bancaria de Destino

1. En el Dashboard de Stripe, ve a **Settings** > **Payouts**
2. Agrega tu cuenta bancaria:
   - IBAN: ES5101829726210202180050
   - Nombre del titular
   - Verifica la cuenta (Stripe hará un depósito de prueba)

### 3. Crear Productos y Precios

1. Ve a **Products** en el Dashboard
2. Crea los siguientes productos:

#### Premium Mensual
- **ID**: `premium_monthly`
- **Nombre**: Premium Mensual
- **Precio**: €9.99 EUR/mes
- **Tipo**: Recurring

#### Premium Anual
- **ID**: `premium_annual`
- **Nombre**: Premium Anual
- **Precio**: €79.99 EUR/año
- **Tipo**: Recurring

#### Items Individuales
- **Boost**: €1.99
- **Super Like**: €0.99
- **Verificación Premium**: €2.99
- **Destacar Anuncio**: €3.99

### 4. Configurar Cloud Functions (Backend)

**IMPORTANTE**: Nunca expongas tu Secret Key en el cliente. Usa Firebase Cloud Functions.

#### Crear el archivo `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const stripe = require('stripe')(functions.config().stripe.secret_key);
const admin = require('firebase-admin');
admin.initializeApp();

// Crear Payment Intent
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { amount, currency, planId, customerId } = data;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Stripe usa centavos
      currency: currency.toLowerCase(),
      customer: customerId,
      metadata: {
        plan_id: planId,
        user_id: context.auth.uid,
      },
      transfer_data: {
        destination: 'ES5101829726210202180050', // Tu cuenta bancaria
      },
      automatic_payment_methods: {
        enabled: true,
        allow_redirects: 'never',
      },
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Crear Customer en Stripe
exports.createStripeCustomer = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { email, name } = data;

  try {
    const customer = await stripe.customers.create({
      email,
      name,
      metadata: {
        firebase_uid: context.auth.uid,
      },
    });

    // Guardar customer ID en Firestore
    await admin.firestore().collection('users').doc(context.auth.uid).update({
      stripeCustomerId: customer.id,
    });

    return { customerId: customer.id };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Crear suscripción recurrente
exports.createSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { priceId, paymentMethodId } = data;

  try {
    // Obtener customer ID del usuario
    const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
    const customerId = userDoc.data().stripeCustomerId;

    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{ price: priceId }],
      default_payment_method: paymentMethodId,
      transfer_data: {
        destination: 'ES5101829726210202180050',
      },
    });

    return { subscriptionId: subscription.id };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Webhook para eventos de Stripe
exports.handleStripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = functions.config().stripe.webhook_secret;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      await admin.firestore().collection('transactions').add({
        paymentIntentId: paymentIntent.id,
        amount: paymentIntent.amount / 100,
        currency: paymentIntent.currency,
        status: 'succeeded',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      break;

    case 'payment_intent.payment_failed':
      const failedPayment = event.data.object;
      await admin.firestore().collection('transactions').add({
        paymentIntentId: failedPayment.id,
        status: 'failed',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      break;

    case 'invoice.payment_succeeded':
      // Renovación de suscripción exitosa
      const invoice = event.data.object;
      await admin.firestore().collection('subscription_renewals').add({
        subscriptionId: invoice.subscription,
        amount: invoice.amount_paid / 100,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      break;
  }

  res.json({ received: true });
});
```

#### Configurar las variables de entorno:

```bash
firebase functions:config:set stripe.secret_key="sk_test_YOUR_SECRET_KEY"
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"
```

### 5. Configurar Webhooks

1. En el Dashboard de Stripe, ve a **Developers** > **Webhooks**
2. Agrega un nuevo webhook:
   - URL: `https://YOUR_PROJECT.cloudfunctions.net/handleStripeWebhook`
   - Eventos a escuchar:
     - `payment_intent.succeeded`
     - `payment_intent.payment_failed`
     - `invoice.payment_succeeded`
     - `customer.subscription.deleted`
3. Copia el webhook secret y configúralo en las funciones

### 6. Actualizar el Código del Cliente

En `lib/services/stripe_payment_service.dart`, actualiza las keys:

```dart
static const String _publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY';
```

**IMPORTANTE**: La Secret Key debe eliminarse del código del cliente y usarse solo en Cloud Functions.

### 7. Configurar Apple Pay (iOS)

1. En el Dashboard de Stripe, ve a **Settings** > **Payment Methods** > **Apple Pay**
2. Agrega tu Merchant ID
3. Configura el Merchant ID en Xcode:
   - Ve a **Signing & Capabilities**
   - Agrega **Apple Pay**
   - Selecciona tu Merchant ID

### 8. Configurar Google Pay (Android)

1. En el Dashboard de Stripe, ve a **Settings** > **Payment Methods** > **Google Pay**
2. Agrega tu Merchant ID
3. Configura el Merchant ID en Android:
   - Agrega el Merchant ID en `AndroidManifest.xml`
   - Configura en Google Pay Console

## Flujo de Pago

### 1. Pago con Tarjeta
1. Usuario ingresa datos de tarjeta
2. App crea Payment Intent (via Cloud Function)
3. Stripe procesa el pago
4. Fondos transferidos a ES5101829726210202180050
5. Webhook confirma el pago
6. Suscripción activada en Firestore

### 2. Pago con Apple Pay/Google Pay
1. Usuario selecciona Apple Pay/Google Pay
2. App presenta sheet de pago
3. Usuario autoriza con biometría
4. Stripe procesa el pago
5. Fondos transferidos a ES5101829726210202180050
6. Webhook confirma el pago
7. Suscripción activada en Firestore

## Transferencia de Fondos

Los fondos se transferirán automáticamente a tu cuenta bancaria:

- **Cuenta de destino**: ES5101829726210202180050
- **Frecuencia de transferencia**: Diaria (configurable en Stripe)
- **Tiempo de llegada**: 1-2 días hábiles

Para cambiar la frecuencia:
1. Ve a **Settings** > **Payouts**
2. Configura el schedule de payouts

## Testing

### Modo Test
- Usa las keys de test (pk_test_..., sk_test_...)
- Usa tarjetas de prueba: https://stripe.com/docs/testing

### Tarjetas de Prueba Comunes
- **Éxito**: 4242 4242 4242 4242
- **Fallo**: 4000 0000 0000 0002
- **Requiere 3D Secure**: 4000 0025 0000 3155

## Seguridad

### ✅ Prácticas Recomendadas
- Usa Cloud Functions para todas las operaciones con Secret Key
- Valida todos los inputs en el cliente y servidor
- Implementa rate limiting para prevenir abuso
- Usa webhooks para confirmar pagos
- Encripta datos sensibles en Firestore

### ❌ Nunca Hacer
- Exponer Secret Key en el cliente
- Guardar datos de tarjeta en tu base de datos
- Omitir validación de inputs
- Confiar solo en notificaciones del cliente

## Monitoreo

Monitorea tus pagos en el Dashboard de Stripe:
- **Balance**: Ver fondos disponibles y pendientes
- **Payments**: Historial de transacciones
- **Payouts**: Transferencias a tu cuenta bancaria
- **Disputes**: Reclamaciones de clientes

## Soporte

- **Documentación de Stripe**: https://stripe.com/docs
- **Documentación de Flutter Stripe**: https://pub.dev/packages/flutter_stripe
- **Soporte de Stripe**: https://support.stripe.com

## Notas Importantes

1. **Comisiones de Stripe**: ~2.9% + €0.25 por transacción en Europa
2. **Retención de fondos**: Stripe puede retener fondos por 7 días inicialmente
3. **Verificación**: Completa la verificación de cuenta para evitar límites
4. **Compliance**: Asegúrate de cumplir con GDPR y otras regulaciones

## Pasos Siguientes

1. [ ] Crear cuenta de Stripe
2. [ ] Verificar cuenta bancaria ES5101829726210202180050
3. [ ] Obtener API keys
4. [ ] Crear productos y precios
5. [ ] Configurar Cloud Functions
6. [ ] Configurar webhooks
7. [ ] Actualizar código del cliente
8. [ ] Configurar Apple Pay (iOS)
9. [ ] Configurar Google Pay (Android)
10. [ ] Probar en modo test
11. [ ] Desplegar a producción
