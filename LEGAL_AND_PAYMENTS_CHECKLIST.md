# RoomMate Match - Checklist Legal, Empresarial y Pagos

## Acciones que requieren gestión fuera del código (tú o tu abogado/gestor)

### 1. Constitución de la empresa/startup
- [ ] Elegir forma jurídica (autónomo, SL, SAS, etc.).
- [ ] Registrar el CIF/NIF en el país de residencia fiscal.
- [ ] Abrir cuenta bancaria empresarial separada de la personal.
- [ ] Domiciliar el negocio (calle o coworking real, no ficticio).
- [ ] Alta en Hacienda y, si aplica, en el registro mercantil.
- [ ] Contratar asesoría fiscal para IVA/impuestos de venta digital y retenciones.

### 2. Términos de Uso y Política de Privacidad
- [ ] Revisar `TERMS_OF_SERVICE.md` y `PRIVACY_POLICY.md` con un abogado.
- [ ] Sustituir los datos de contacto de ejemplo por los reales:
  - Email legal: legal@roommatematch.com
  - Email privacidad: privacy@roommatematch.com
  - Dirección postal real
  - Teléfono real
- [ ] Publicar los documentos en URLs accesibles públicamente:
  - `https://roommatematch.com/terms`
  - `https://roommatematch.com/privacy`
  - `https://roommatematch.com/cookies`
- [ ] Actualizar las URLs hardcodeadas en la app:
  - `mobile/lib/features/auth/register_screen.dart`
  - `mobile/lib/features/settings/privacy_settings_screen.dart`

### 3. Cumplimiento GDPR (usuarios en Europa/España)
- [ ] Base legal del tratamiento: consentimiento explícito al registrarse (checkbox implementado).
- [ ] Finalidad, legitimación y plazo de conservación por cada dato recopilado.
- [ ] Derecho de acceso, rectificación, supresión, oposición, limitación y portabilidad.
- [ ] Derecho a retirar el consentimiento sin afectar a la licitud del tratamiento previo.
- [ ] Posibilidad de reclamar ante la AEPD (autoridad de control).
- [ ] Registro de actividades de tratamiento (RAT) interno.
- [ ] Encargado de tratamiento con Google/Firebase: firmar cláusulas SCC y mantener actualizado el DPA de Firebase.
- [ ] Política de cookies y banner/consentimiento en web (si aplica).
- [ ] Notificación de brechas de seguridad en 72 horas.
- [ ] Designar un DPO si el volumen o sensibilidad de datos lo requiere.

### 4. Cumplimiento LATAM
- [ ] México: Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP).
- [ ] Argentina: Ley 25.326 de Protección de Datos Personales.
- [ ] Colombia: Ley 1581 de 2012.
- [ ] Brasil: LGPD (Lei 13.709/2018).
- [ ] Chile: Ley 19.628.
- [ ] Adaptar consentimientos y notificaciones al texto local si se lanza en cada país.

### 5. Protección de marca
- [ ] Búsqueda de antecedentes en OEPM/EUIPO (Europa) y USPTO (EE.UU.) o equivalente local.
- [ ] Registrar nombre "RoomMate Match" y logo como marca.
- [ ] Registrar dominio `roommatematch.com` y variantes relevantes.
- [ ] Registrar perfiles sociales (IG, TikTok, X, Facebook, LinkedIn).

### 6. Configuración de pagos y facturación
- [ ] Crear cuenta de Stripe y completar KYB (verificación de empresa).
- [ ] Sustituir `pk_test_YOUR_PUBLISHABLE_KEY` y `sk_test_YOUR_SECRET_KEY` en `mobile/lib/services/stripe_payment_service.dart`.
- [ ] Nunca exponer `sk_` en el cliente: mover la creación de `PaymentIntent` y `Subscription` a backend/Cloud Functions.
- [ ] Configurar Apple Developer y Google Play Console para pagos in-app.
- [ ] Crear productos/suscripciones en App Store Connect y Google Play Console:
  - Premium Mensual
  - Premium Anual
  - Boost, Super Like, Verificación Premium, Destacar anuncio
- [ ] Evaluar RevenueCat para unificar suscripciones iOS/Android con Stripe.
- [ ] Configurar impuestos (IVA en UE, impuestos digitales locales) o habilitar Stripe Tax.
- [ ] Preparar sistema de facturación (Stripe invoicing o integración con gestor).
- [ ] Definir política de reembolsos y cancelaciones.

## Cambios técnicos ya realizados

- Enlaces a Términos de Uso y Política de Privacidad añadidos en la pantalla de registro.
- Enlaces a documentos legales añadidos en `PrivacySettingsScreen`.
- URLs placeholder puestas en: `https://roommatematch.com/terms`, `/privacy`, `/cookies`.
- `privacy_settings_screen.dart` ya incluye opciones GDPR: acceso, rectificación, eliminación, portabilidad y retirada de consentimiento.

## Próximos pasos técnicos recomendados

1. Sustituir las URLs placeholder por las URLs reales una vez publicados los documentos.
2. Mover toda la lógica de pagos de `stripe_payment_service.dart` a un backend seguro.
3. Implementar banners de cookies/consentimiento si abres versión web.
4. Añadir flujo de "eliminar cuenta" que borre datos en Firestore/Auth en 30 días.
5. Configurar Firebase App Check para proteger endpoints de pagos y datos.
