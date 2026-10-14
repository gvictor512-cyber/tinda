#!/bin/bash

# setup_macos.sh
# Ejecutar en macOS para preparar el proyecto iOS.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Limpiando y descargando dependencias Flutter..."
flutter clean
flutter pub get

echo "==> Instalando pods..."
cd ios
pod install --repo-update
cd "$SCRIPT_DIR"

echo "==> Compilando iOS..."
flutter build ios --no-codesign

echo "==> Listo. Abrí ios/Runner.xcworkspace en Xcode y configurá el Signing & Capabilities."
echo "==> Luego corré: flutter run"
