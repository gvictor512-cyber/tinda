# Instrucciones para Publicar RoomMate Match en Tiendas

## 📱 Google Play Store (Android)

### Paso 1: Generar Keystore para Firma

**IMPORTANTE:** El APK actual está firmado con debug keys. Para publicar necesitas tu propio keystore.

**REQUISITO:** Necesitas Java JDK instalado. Descárgalo de: https://www.oracle.com/java/technologies/downloads/

Ejec este comando en tu terminal (en la carpeta `mobile/android/`):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Guarda este archivo en una ubicación segura. **NUNCA lo compartas ni lo subas a GitHub.**

### Paso 2: Crear archivo key.properties

Ya he creado `android/key.properties.example` con instrucciones detalladas.

Copia ese archivo a `android/key.properties` y completa los valores:

```properties
storePassword=tu_contraseña_keystore
keyPassword=tu_contraseña_key
keyAlias=upload
storeFile=/ruta/absoluta/a/upload-keystore.jks
```

**IMPORTANTE:** Este archivo ya está en .gitignore, así que no se subirá al repositorio.

### Paso 3: Construir APK o AAB

El APK actual está en: `mobile/build/app/outputs/flutter-apk/app-release.apk`

Para reconstruir con tu keystore:

```bash
cd mobile
flutter clean
flutter build apk --release
```

O para AAB (recomendado para Play Store):

```bash
flutter build appbundle --release
```

### Paso 4: Publicar en Google Play Console

1. Crear cuenta de desarrollador ($25 one-time): https://play.google.com/console
2. Crear nueva app
3. Subir el APK/AAB
4. Completar el listing:
   - Nombre: RoomMate Match
   - Descripción corta y larga
   - Screenshots (mínimo 2)
   - Icono de la app (512x512px)
   - Banner de la tienda (1024x500px)
   - Política de privacidad
   - Clasificación de contenido

## 🍎 Apple App Store (iOS)

### Requisitos Previos

**IMPORTANTE:** Para publicar en iOS necesitas:
- Una Mac con Xcode instalado
- Cuenta de desarrollador Apple ($99/año): https://developer.apple.com
- Certificados de desarrollo y distribución
- Provisioning Profiles

### Paso 1: Configurar en Mac

1. Abre el proyecto en Xcode:
   ```bash
   cd mobile/ios
   open Runner.xcworkspace
   ```

2. Configura el signing:
   - Selecciona el target "Runner"
   - En "Signing & Capabilities", selecciona tu equipo de desarrollo
   - Asegúrate de que "Automatically manage signing" esté activado

3. Actualiza el Bundle Identifier:
   - Cambia `com.roommatematch.app` por uno único (ej: `com.tuempresa.roommatematch`)

### Paso 2: Construir y Archivar

1. En Xcode: Product > Archive
2. Cuando termine, aparecerá la ventana Organizer
3. Selecciona Distribute App > App Store Connect
4. Sube a App Store Connect

### Paso 3: Configurar en App Store Connect

1. Crea el listing de la app
2. Agrega:
   - Screenshots (requeridos para cada tamaño de dispositivo)
   - Descripciones
   - Iconos
   - Información de la app
   - Política de privacidad

### Paso 4: Enviar para Revisión

Apple revisará tu app (tarda 1-3 días). Asegúrate de:
- Seguir las Human Interface Guidelines
- No tener bugs
- Incluir todas las funcionalidades descritas

## 📦 Archivos Generados

### Android
- **APK Release:** `mobile/build/app/outputs/flutter-apk/app-release.apk` (43.4MB)
- **AAB (si se construye):** `mobile/build/app/outputs/bundle/release/app-release.aab`

### iOS
- Se genera automáticamente en Xcode durante el proceso de archivado

## 🔧 Configuración Ya Realizada

✅ `android/app/build.gradle.kts` configurado para usar keystore
✅ Estructura de firma configurada con importaciones Kotlin DSL
✅ APK de release construido: `mobile/build/app/outputs/flutter-apk/app-release.apk` (43.4MB)
✅ Archivo `android/key.properties.example` creado con instrucciones detalladas
✅ Guía de assets necesarios creada: `ASSETS_TIENDAS.md`

## ⚠️ Pasos Requeridos por el Usuario

### 1. Instalar Java JDK
- Descargar de: https://www.oracle.com/java/technologies/downloads/
- Instalar JDK 11 o superior
- Reiniciar terminal

### 2. Generar Keystore
- Navegar a `mobile/android/`
- Ejecutar: `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- Guardar las contraseñas en lugar seguro

### 3. Crear key.properties
- Copiar `android/key.properties.example` a `android/key.properties`
- Completar con las credenciales del keystore

### 4. Reconstruir APK con Firma de Producción
```bash
cd mobile
flutter clean
flutter build apk --release
```

### 5. Preparar Assets (ver ASSETS_TIENDAS.md)
- Iconos para ambas tiendas
- Screenshots de la app
- Descripciones y textos

### 6. Crear Cuentas de Desarrollador
- Google Play Console: $25 (one-time)
- Apple Developer: $99/año (requiere Mac)

## ⚠️ Notas Importantes

1. **Keystore:** Guarda tu keystore en un lugar seguro. Si lo pierdes, no podrás actualizar la app.
2. **Versionamiento:** Actualiza `version` en `pubspec.yaml` para cada release (formato: `x.y.z+buildNumber`)
3. **Testing:** Prueba la app en dispositivos reales antes de publicar
4. **Política de Privacidad:** Google y Apple requieren una política de privacidad

## 🚀 Siguientes Pasos

1. Generar keystore de producción
2. Crear cuenta de desarrollador Google Play ($25)
3. Crear cuenta de desarrollador Apple ($99) - requiere Mac
4. Preparar assets (iconos, screenshots)
5. Subir y publicar

## 📞 Recursos

- [Flutter Android Release](https://docs.flutter.dev/deployment/android)
- [Flutter iOS Release](https://docs.flutter.dev/deployment/ios)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)
