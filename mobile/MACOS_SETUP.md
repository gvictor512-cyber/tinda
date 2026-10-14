# Preparar el proyecto para macOS / iOS

Esta guía describe cómo mover el proyecto a una Mac y dejarlo listo para compilar y ejecutar en iOS.

## Requisitos en la Mac

- macOS 13 (Ventura) o superior
- Xcode 15 o superior (desde la Mac App Store)
- Command Line Tools: `xcode-select --install`
- [Homebrew](https://brew.sh)
- [CocoaPods](https://cocoapods.org): `sudo gem install cocoapods`
- [Flutter](https://docs.flutter.dev/get-started/install/macos) estable, canal `stable`
- Una cuenta de Apple Developer (gratuita o de pago) para firmar la app

## 1. Copiar el proyecto

Transferí la carpeta `mobile/` completa a la Mac, por ejemplo:

```bash
/Users/tu-usuario/Projects/roommatematch/mobile
```

> **Importante:** Los archivos sensibles de Firebase están en `.gitignore`, por lo que no viajan con `git`. Tenés que copiarlos a mano desde esta PC:
>
> - `mobile/ios/Runner/GoogleService-Info.plist`
> - `mobile/android/app/google-services.json`

## 2. Instalar dependencias de Flutter

```bash
cd /Users/tu-usuario/Projects/roommatematch/mobile
flutter clean
flutter pub get
```

## 3. Generar Podfile.lock e instalar Pods

El `ios/Podfile` ya está incluido en el proyecto. En la Mac solo falta instalar los pods con CocoaPods.

Con el script incluido:

```bash
bash setup_macos.sh
```

O manualmente:

```bash
flutter pub get
cd ios
pod install --repo-update
cd ..
flutter build ios --no-codesign
```

Eso creará:

- `ios/Podfile.lock`
- `ios/Pods/`

## 4. Configurar firma (signing) en Xcode

1. Abrí `ios/Runner.xcworkspace` con Xcode.
2. Seleccioná el proyecto `Runner` → Target `Runner` → tab **Signing & Capabilities**.
3. Asigná un **Bundle Identifier** único. El proyecto ya usa `com.roommatematchapp.ios`.
4. Seleccioná tu **Team** de Apple Developer.
5. Verificá que las capabilities incluyan:
   - **In-App Purchase** (si vas a usar pagos)
   - **Push Notifications**
   - **Background Modes** → `fetch`, `remote notifications`
6. Si cambiás el Bundle ID, actualizá el `merchant.com.roommatematch` en `ios/Runner/Runner.entitlements` para que coincida con tu merchant ID de Apple.

## 5. Ejecutar la app

Con un simulador:

```bash
flutter run
```

Con un dispositivo físico, primero conectalo y confía en el certificado, luego:

```bash
flutter run -d <device-id>
```

## 6. Construir un release

```bash
flutter build ios --release
```

Luego, en Xcode: **Product → Archive** para subir a App Store Connect.

## Notas importantes

- El archivo `ios/Runner/Info.plist` ya incluye los permisos para cámara, fotos, ubicación y notificaciones.
- El `AppDelegate.swift` ya inicializa `FirebaseApp.configure()`.
- Los modos de fondo y el esquema de deep link `roommatematch://` ya están configurados.
- Si vas a publicar, recordá configurar el `PRODUCT_BUNDLE_IDENTIFIER` y el `Team` correspondiente.
