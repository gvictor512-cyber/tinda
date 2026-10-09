#!/bin/sh
set -e

# Xcode Cloud no trae Flutter preinstalado. Este script corre tras clonar el
# repo y antes de xcodebuild: instala el SDK (misma versión que local),
# resuelve dependencias y genera los paquetes efímeros
# (FlutterGeneratedPluginSwiftPackage), cuya ausencia hacía fallar el build
# con "Could not resolve package dependencies".

FLUTTER_VERSION="3.47.2"

# Repo root → el proyecto Flutter vive en mobile/
APP_DIR="$CI_PRIMARY_REPOSITORY_PATH/mobile"

echo "==> Installing Flutter $FLUTTER_VERSION"
git clone https://github.com/flutter/flutter.git \
  --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

flutter precache --ios

cd "$APP_DIR"
flutter pub get

# --config-only regenera ios/Flutter/ephemeral y el plugin swift package sin
# compilar la app entera (xcodebuild la compila después).
flutter build ios --config-only --release --no-codesign

# CocoaPods viene preinstalado en las imágenes de Xcode Cloud; brew como
# fallback por si la imagen cambia.
if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi
cd "$APP_DIR/ios"
pod install --repo-update
