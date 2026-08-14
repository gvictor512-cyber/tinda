# Guía de Creación de Assets Visuales - RoomMate Match

## Icono de la App

### Icono SVG Base
He creado un archivo SVG base en `assets/app_icon.svg` con:
- Diseño de casa con personas (representando compañeros de piso)
- Colores de la marca: #4A90E2 (azul) y #50E3C2 (verde)
- Gradiente sutil para modernidad
- Elementos de matching (corazón, líneas de conexión)

### Pasos para crear los iconos finales

#### 1. Convertir SVG a PNG
**Herramientas recomendadas:**
- **Figma:** Importa el SVG y exporta como PNG
- **Adobe Illustrator:** Abre SVG y exporta
- **Inkscape:** (Gratis) Abre SVG y exporta
- **Online:** cloudconvert.com, svgtopng.com

**Tamaños requeridos:**
- **Android:** 512x512 px (Google Play)
- **iOS:** 1024x1024 px (App Store)
- **Android app icons:** Varios tamaños (ver abajo)

#### 2. Generar iconos de Android
Usa Android Studio o herramienta online:
```bash
# En Android Studio: Tools > Image Asset
# Selecciona el SVG o PNG de 1024x1024
# Generará todos los tamaños automáticamente
```

**Tamaños de iconos Android:**
- mipmap-mdpi: 48x48 px
- mipmap-hdpi: 72x72 px
- mipmap-xhdpi: 96x96 px
- mipmap-xxhdpi: 144x144 px
- mipmap-xxxhdpi: 192x192 px

#### 3. Generar iconos de iOS
Usa Xcode o herramienta online:
```bash
# En Xcode: Arrastra el icono de 1024x1024 al App Icon asset catalog
# Xcode generará todos los tamaños automáticamente
```

**Tamaños de iconos iOS:**
- iPhone: 60x60, 120x120, 180x180 px
- iPad: 76x76, 152x152 px
- App Store: 1024x1024 px

---

## Screenshots de la App

### Screenshots Requeridos

#### 1. Onboarding - Selección de Tipo de Usuario
**Contenido:**
- Pantalla de selección: "Busca piso" vs "Tienes piso"
- Diseño limpio con dos opciones grandes
- Colores de marca
- Texto claro y legible

**Instrucciones:**
1. Ejecuta la app en un emulador o dispositivo
2. Navega a la pantalla de UserTypeSelectionScreen
3. Toma screenshot nativo del dispositivo
4. Recorta a 1080x1920 px (Android) o 1290x2796 px (iOS)

#### 2. Swipe Interface - Matching
**Contenido:**
- Pantalla de perfiles con tarjetas
- Botones de like/dislike
- Indicador de compatibilidad
- Foto de perfil de ejemplo

**Instrucciones:**
1. Crea un perfil de prueba con fotos
2. Navega a la pantalla de SwipeScreen
3. Muestra una tarjeta de perfil con score de compatibilidad
4. Toma screenshot

#### 3. Compatibility Score
**Contenido:**
- Detalle del algoritmo de matching
- Score de compatibilidad (ej: 85%)
- Factores de compatibilidad listados
- Gráfico visual del score

**Instrucciones:**
1. Muestra el detalle de compatibilidad
2. Destaca el score principal
3. Muestra los factores (horarios, limpieza, etc.)
4. Toma screenshot

#### 4. Chat en Tiempo Real
**Contenido:**
- Conversación de ejemplo
- Burbujas de chat (enviados/recibidos)
- Indicador de "escribiendo..."
- Timestamps en mensajes

**Instrucciones:**
1. Haz match con un usuario de prueba
2. Envía algunos mensajes de ejemplo
3. Muestra diferentes tipos de mensajes
4. Toma screenshot

#### 5. Búsqueda de Pisos
**Contenido:**
- Lista de pisos de Idealista/Fotocasa
- Filtros de búsqueda aplicados
- Fotos de pisos
- Precios y ubicaciones

**Instrucciones:**
1. Integra con APIs de Idealista/Fotocasa
2. Muestra resultados de búsqueda
3. Aplica algunos filtros
4. Toma screenshot

#### 6. Perfil de Usuario
**Contenido:**
- Fotos de perfil (hasta 6)
- Información personal
- Preferencias de convivencia
- Score de compatibilidad promedio

**Instrucciones:**
1. Crea un perfil completo de prueba
2. Añade varias fotos
3. Completa todas las preferencias
4. Toma screenshot

#### 7. Features Premium
**Contenido:**
- Lista de beneficios premium
- Precio de suscripción
- Botón de suscripción
- Comparación gratis vs premium

**Instrucciones:**
1. Navega a pantalla de premium
2. Muestra todos los beneficios
3. Destaca el call-to-action
4. Toma screenshot

#### 8. Configuración de Privacidad
**Contenido:**
- Opciones de privacidad
- Acceso a datos
- Eliminación de cuenta
- Contacto de privacidad

**Instrucciones:**
1. Navega a PrivacySettingsScreen
2. Muestra las opciones principales
3. Destaca el contacto de privacidad
4. Toma screenshot

### Herramientas para Capturar Screenshots

#### Android
```bash
# ADB command line
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png

# Android Studio: Tools > Layout Inspector
# Emulator: Screenshot button in emulator toolbar
```

#### iOS
```bash
# Simulator: Cmd + S or File > Take Screenshot
# Device: Power + Volume Up buttons
# Xcode: Window > Devices and Simulators > Take Screenshot
```

### Edición de Screenshots

**Herramientas recomendadas:**
- **Figma:** Edición profesional (gratis)
- **Sketch:** Mac-only
- **Canva:** Plantillas de screenshots
- **Adobe XD:** Diseño y prototipado
- **GIMP:** Edición gratuita

**Mejores prácticas:**
- Añade marcos de dispositivo (opcional)
- Incluye barra de estado con hora realista
- Muestra notch en dispositivos modernos
- Añade texto descriptivo breve (opcional)
- Mantén consistencia en estilo y colores

---

## Feature Graphic (Google Play)

### Especificaciones
- **Tamaño:** 1024x500 px
- **Formato:** JPG o PNG
- **Sin transparencia**

### Diseño Sugerido
1. **Fondo:** Gradiente de marca (#4A90E2 a #50E3C2)
2. **Elementos:**
   - Icono de la app grande
   - Texto principal: "Encuentra tu compañero ideal"
   - Subtítulo: "Matching inteligente por compatibilidad"
   - Ilustración de personas conectadas
3. **Safe zone:** Mantén contenido importante 50px de los bordes

### Herramientas
- **Canva:** Plantillas de feature graphic
- **Figma:** Diseño desde cero
- **Adobe Photoshop:** Edición profesional

---

## App Preview Video (Opcional)

### Especificaciones

#### Google Play
- **Duración:** 30 segundos máximo
- **Formato:** YouTube video
- **Resolución:** 1080p o superior
- **Orientación:** Vertical o horizontal

#### App Store
- **Duración:** 15-30 segundos
- **Formato:** M4V, MP4, o MOV
- **Codec:** H.264 o ProRes
- **Resolución:** 
  - iPhone: 1080p (1920x1080)
  - iPad: 2160p (4096x3072)
- **Aspect ratio:** 16:9

### Guion Sugerido (30 segundos)

**0-5s:** Logo animado + nombre de app
**5-10s:** Onboarding - selección de tipo de usuario
**10-15s:** Swipe interface con matching
**15-20s:** Chat en tiempo real
**20-25s:** Búsqueda de pisos integrada
**25-30s:** Call-to-action + logo

### Herramientas de Grabación
- **Android:** AZ Screen Recorder, DU Recorder
- **iOS:** Built-in screen recorder (iOS 11+)
- **Profesional:** Camtasia, Adobe Premiere Pro

---

## Checklist de Assets

### Iconos
- [ ] SVG base creado
- [ ] PNG 512x512 px (Google Play)
- [ ] PNG 1024x1024 px (App Store)
- [ ] Iconos Android generados (todos los tamaños)
- [ ] Iconos iOS generados (todos los tamaños)

### Screenshots Android
- [ ] Onboarding (1080x1920 px)
- [ ] Swipe Interface (1080x1920 px)
- [ ] Compatibility Score (1080x1920 px)
- [ ] Chat (1080x1920 px)
- [ ] Apartment Search (1080x1920 px)
- [ ] Profile (1080x1920 px)
- [ ] Premium (1080x1920 px)
- [ ] Settings (1080x1920 px)

### Screenshots iOS
- [ ] Onboarding (1290x2796 px)
- [ ] Swipe Interface (1290x2796 px)
- [ ] Compatibility Score (1290x2796 px)
- [ ] Chat (1290x2796 px)
- [ ] Apartment Search (1290x2796 px)
- [ ] Profile (1290x2796 px)
- [ ] Premium (1290x2796 px)
- [ ] Settings (1290x2796 px)

### Otros Assets
- [ ] Feature Graphic (1024x500 px)
- [ ] App Preview Video (opcional)
- [ ] Promotional text (170 caracteres)
- [ ] Short description (80 caracteres)
- [ ] Full description (4000 caracteres)

---

## Estructura de Directorios

```
tinder piso1/
├── assets/
│   ├── app_icon.svg
│   ├── store/
│   │   ├── google-play/
│   │   │   ├── icon-512x512.png
│   │   │   ├── feature-graphic-1024x500.png
│   │   │   ├── screenshots/
│   │   │   │   ├── screenshot-1.png
│   │   │   │   └── ...
│   │   │   └── video/
│   │   │       └── promo-video.mp4
│   │   └── app-store/
│   │       ├── app-icon-1024x1024.png
│   │       ├── screenshots/
│   │       │   ├── screenshot-1.png
│   │       │   └── ...
│   │       └── video/
│   │           └── app-preview.mp4
│   └── app-icons/
│       ├── android/
│       │   ├── mipmap-mdpi/
│       │   ├── mipmap-hdpi/
│       │   └── ...
│       └── ios/
│           └── Assets.xcassets/
│               └── AppIcon.appiconset/
```

---

## Recursos Adicionales

### Herramientas de Diseño
- **Figma:** figma.com (gratis)
- **Canva:** canva.com (gratis con plantillas)
- **Sketch:** sketch.com (Mac, pago)
- **Adobe XD:** adobe.com/products/xd (gratis)

### Plantillas
- **Google Play:** Material Design guidelines
- **App Store:** Human Interface Guidelines
- **Dribbble:** Inspiración de diseño
- **Behance:** Portfolios de diseño

### Tutoriales
- **Android Asset Studio:** android.arrowsapps.com
- **App Icon Generator:** appicon.co
- **MakeAppIcon:** makeappicon.com

---

## Notas Importantes

1. **Calidad:** Usa siempre imágenes de alta resolución
2. **Consistencia:** Mantén el mismo estilo en todos los assets
3. **Branding:** Usa siempre los colores de marca (#4A90E2, #50E3C2)
4. **Legibilidad:** Asegúrate de que el texto sea legible
5. **Tamaño:** Optimiza los archivos para carga rápida
6. **Testing:** Prueba los assets en diferentes dispositivos
