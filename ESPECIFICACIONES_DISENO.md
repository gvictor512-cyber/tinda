# Especificaciones Técnicas de Diseño - RoomMate Match

## 🎨 Logo Principal

### Google Play Store (512x512px)

**Dimensiones exactas:**
- Ancho: 512px
- Alto: 512px
- Formato: PNG
- Sin transparencia
- Sin esquinas redondeadas (Google las añade automáticamente)

**Especificaciones de diseño:**
- Margen de seguridad: 64px desde cada borde (12.5%)
- Área de contenido: 384x384px en el centro
- Fondo: Gradiente de #4A90E2 (azul) a #50E3C2 (verde)
- Icono centrado en el área de contenido

**Elementos del icono:**
1. Silueta de casa (outline)
   - Línea continua de 4px de grosor
   - Color: #FFFFFF (blanco)
   - Proporciones: base 200px, altura 180px

2. Dos piezas de rompecabezas interconectadas
   - Ubicadas dentro de la silueta de casa
   - Grosor de línea: 3px
   - Color: #FFFFFF (blanco)
   - Una pieza azul (#4A90E2), otra verde (#50E3C2)

3. Corazón sutil
   - Integrado en la unión de las piezas
   - Tamaño: 40x40px
   - Color: #FFFFFF con opacidad 80%

### Apple App Store (1024x1024px)

**Dimensiones exactas:**
- Ancho: 1024px
- Alto: 1024px
- Formato: PNG
- Sin transparencia
- Sin esquinas redondeadas (Apple las añade automáticamente)

**Especificaciones de diseño:**
- Escala 2x del diseño de Google Play
- Mantener las mismas proporciones
- Margen de seguridad: 128px desde cada borde
- Área de contenido: 768x768px en el centro

**Elementos del icono:**
- Mismos elementos que Google Play pero escalados 2x
- Grosor de líneas: 8px (casa), 6px (rompecabezas)
- Corazón: 80x80px

---

## 🖼️ Feature Graphic (Google Play - 1024x500px)

**Dimensiones exactas:**
- Ancho: 1024px
- Alto: 500px
- Formato: PNG o JPG
- Relación de aspecto: 2:1

**Especificaciones de diseño:**
- Fondo: Gradiente diagonal de #4A90E2 a #50E3C2
- Ángulo del gradiente: 45 grados

**Elementos:**
1. Logo principal
   - Ubicación: Centrado verticalmente, 150px desde el borde izquierdo
   - Tamaño: 300x300px
   - Con sombra suave (drop-shadow)

2. Texto principal
   - Ubicación: A la derecha del logo
   - Texto: "Encuentra tu compañero ideal"
   - Fuente: Roboto Bold, tamaño 48px
   - Color: #FFFFFF
   - Sombra de texto para legibilidad

3. Ilustración
   - Ubicación: Parte inferior derecha
   - Dos figuras estilizadas en ambiente hogareño
   - Estilo: Flat design, minimalista
   - Colores: Tonos de la paleta de marca

4. Call-to-action
   - Ubicación: Esquina inferior derecha
   - Texto: "Descarga ahora"
   - Botón con borde redondeado
   - Color: #FFFFFF con texto #4A90E2

---

## 📱 Banner Promocional (Google Play - 180x120px)

**Dimensiones exactas:**
- Ancho: 180px
- Alto: 120px
- Formato: PNG o JPG
- Relación de aspecto: 3:2

**Especificaciones de diseño:**
- Fondo: Gradiente de #4A90E2 a #50E3C2
- Margen: 10px desde cada borde

**Elementos:**
1. Logo pequeño
   - Ubicación: 10px desde el borde izquierdo, centrado verticalmente
   - Tamaño: 40x40px
   - Versión simplificada del logo principal

2. Texto
   - Ubicación: A la derecha del logo
   - Texto: "RoomMate Match"
   - Fuente: Roboto Bold, tamaño 14px
   - Color: #FFFFFF

---

## 📸 Screenshots

### Google Play Store - Teléfono (320-384px de ancho)

**Dimensiones recomendadas:**
- Ancho: 384px
- Alto: 853px (relación 9:19.5)
- Formato: PNG o JPG

**Captura 1 - Perfil de Usuario:**
- Mostrar pantalla de perfil completo
- Incluir foto de perfil, nombre, edad
- Mostrar sección de preferencias
- Texto overlay: "Crea tu perfil detallado"
- Posición del texto: Parte superior, fondo semitransparente

**Captura 2 - Sistema de Swipe:**
- Mostrar tarjeta de perfil centrada
- Incluir botones de like/dislike
- Mostrar indicador de swipe
- Texto overlay: "Desliza para encontrar matches"

**Captura 3 - Match Exitoso:**
- Mostrar notificación de match
- Incluir foto de ambos usuarios
- Mostrar mensaje de celebración
- Texto overlay: "¡Match! Tienen intereses compatibles"

**Captura 4 - Chat:**
- Mostrar conversación activa
- Incluir burbujas de chat
- Mostrar campo de texto de entrada
- Texto overlay: "Chatea con tus matches"

**Captura 5 - Filtros Avanzados:**
- Mostrar pantalla de filtros
- Incluir sliders y checkboxes
- Mostrar categorías de filtrado
- Texto overlay: "Filtra por tus preferencias"

**Captura 6 - Mapa:**
- Mostrar mapa con pines de ubicación
- Incluir interfaz de usuario del mapa
- Mostrar filtros de distancia
- Texto overlay: "Encuentra roommates cerca"

**Captura 7 - Verificación:**
- Mostrar proceso de verificación
- Incluir indicadores de progreso
- Mostrar badges de verificación
- Texto overlay: "Perfiles verificados para mayor seguridad"

**Captura 8 - Éxito:**
- Mostrar estadística o testimonio
- Incluir número de matches exitosos
- Mostrar calificación de usuarios
- Texto overlay: "Miles de matches exitosos"

### Apple App Store - iPhone 6.7" (1290x2796px)

**Dimensiones exactas:**
- Ancho: 1290px
- Alto: 2796px
- Formato: PNG
- Sin marco de dispositivo

**Capturas requeridas:**
- Mismas 8 capturas que Android pero adaptadas al tamaño
- Escalar proporcionalmente manteniendo calidad
- Ajustar tamaño de texto para legibilidad

### Apple App Store - iPad Pro 12.9" (2048x2732px)

**Dimensiones exactas:**
- Ancho: 2048px
- Alto: 2732px
- Formato: PNG

**Capturas requeridas:**
- Adaptar diseño para formato horizontal
- Mostrar más contenido por pantalla
- Incluir elementos de interfaz de iPad

---

## 🎨 Paleta de Colores Detallada

### Colores Primarios
```css
--primary-blue: #4A90E2;
--primary-green: #50E3C2;
--secondary-purple: #9B59B6;
```

### Colores de Fondo
```css
--background-dark: #1A1A2E;
--background-light: #FFFFFF;
--background-gray: #F5F5F5;
```

### Colores de Texto
```css
--text-dark: #2C3E50;
--text-light: #FFFFFF;
--text-gray: #7F8C8D;
```

### Colores Funcionales
```css
--success: #27AE60;
--error: #E74C3C;
--warning: #F39C12;
--info: #3498DB;
```

### Gradientes
```css
--gradient-primary: linear-gradient(135deg, #4A90E2 0%, #50E3C2 100%);
--gradient-secondary: linear-gradient(135deg, #9B59B6 0%, #4A90E2 100%);
--gradient-dark: linear-gradient(135deg, #1A1A2E 0%, #2C3E50 100%);
```

---

## ✍️ Tipografía Detallada

### Google Play Store - Roboto

**Pesos disponibles:**
- Light (300): Para captions y texto secundario
- Regular (400): Para cuerpo de texto
- Medium (500): Para subtítulos
- Bold (700): Para títulos y encabezados

**Tamaños recomendados:**
- Títulos grandes: 48px
- Títulos medianos: 32px
- Subtítulos: 24px
- Cuerpo: 16px
- Captiones: 12px

### Apple App Store - SF Pro Display

**Pesos disponibles:**
- Light (300): Para captions y texto secundario
- Regular (400): Para cuerpo de texto
- Medium (500): Para subtítulos
- Semibold (600): Para énfasis
- Bold (700): Para títulos y encabezados

**Tamaños recomendados:**
- Títulos grandes: 48pt
- Títulos medianos: 32pt
- Subtítulos: 24pt
- Cuerpo: 16pt
- Captiones: 12pt

---

## 📐 Guías de Diseño

### Espaciado
- Espacio mínimo entre elementos: 8px
- Espacio estándar: 16px
- Espacio grande: 32px
- Espacio extra grande: 64px

### Bordes y Esquinas
- Radio de bordes pequeños: 4px
- Radio de bordes medianos: 8px
- Radio de bordes grandes: 16px
- Radio de bordes extra grandes: 24px

### Sombras
- Sombra suave: 0 2px 8px rgba(0,0,0,0.1)
- Sombra media: 0 4px 16px rgba(0,0,0,0.15)
- Sombra fuerte: 0 8px 32px rgba(0,0,0,0.2)

---

## 🔧 Formatos de Archivo

### Para Producción
- **Iconos**: PNG-24 con transparencia (cuando se permita)
- **Screenshots**: PNG o JPG (calidad 90%+)
- **Banners**: PNG o JPG (calidad 90%+)

### Para Trabajo
- **Fuentes de diseño**: SVG, AI, PSD, Figma
- **Versiones intermedias**: PNG con capas

### Compresión
- PNG: Usar TinyPNG o similar para optimización
- JPG: Calidad 85-90% para balance tamaño/calidad

---

## 📱 Adaptaciones Responsive

### Teléfonos Pequeños (< 5")
- Reducir tamaño de texto 10%
- Aumentar espaciado entre elementos
- Simplificar elementos visuales

### Teléfonos Medianos (5" - 6")
- Diseño estándar
- Tamaños de texto base

### Teléfonos Grandes (> 6")
- Aumentar tamaño de texto 5%
- Más espacio para contenido
- Elementos más grandes para touch

### Tablets
- Diseño de dos columnas cuando sea posible
- Aumentar tamaño de texto 15%
- Más elementos visuales por pantalla

---

## ✅ Checklist de Diseño

### Logo
- [ ] Versión Google Play (512x512px)
- [ ] Versión Apple (1024x1024px)
- [ ] Versión favicon (32x32px)
- [ ] Versión icono de notificación (96x96px)
- [ ] PNG sin transparencia
- [ ] Colores de marca correctos
- [ ] Legible en diferentes fondos

### Banners
- [ ] Feature graphic (1024x500px)
- [ ] Banner promocional (180x120px)
- [ ] Formato PNG o JPG
- [ ] Texto legible
- [ ] Colores de marca consistentes

### Screenshots
- [ ] 8 capturas para Android
- [ ] Capturas para todos los tamaños iOS
- [ ] Texto overlay en cada captura
- [ ] Alta calidad (sin pixelación)
- [ ] Sin elementos de interfaz del sistema

### Colores
- [ ] Paleta de colores definida
- [ ] Códigos hexadecimales documentados
- [ ] Gradientes especificados
- [ ] Contraste suficiente para accesibilidad

### Tipografía
- [ ] Fuentes seleccionadas
- [ ] Pesos y tamaños definidos
- [ ] Licencias de fuentes verificadas
- [ ] Web fonts si aplica

---

## 🚀 Herramientas Recomendadas

### Diseño
- **Figma**: Diseño colaborativo (gratis)
- **Canva**: Plantillas y assets (freemium)
- **Adobe XD**: Diseño de interfaces (gratis)
- **Sketch**: Diseño UI (Mac, pago)

### Iconos
- **IconJar**: Gestión de iconos (Mac)
- **Noun Project**: Iconos gratuitos
- **Flaticon**: Iconos premium

### Screenshots
- **CleanShot X**: Capturas profesionales (Mac)
- **Snagit**: Capturas y edición (Windows/Mac)
- **Device Mockups**: Mockups de dispositivos

### Optimización
- **TinyPNG**: Compresión de PNG
- **ImageOptim**: Optimización de imágenes (Mac)
- **Squoosh**: Compresión web (Google)

---

## 📞 Contacto para Diseñadores

Si contratas a un diseñador, comparte este documento junto con:
- CONTENIDO_TIENDAS.md (textos y descripciones)
- BRANDING.md (identidad de marca)
- ASSETS_TIENDAS.md (especificaciones de tiendas)
- Capturas de pantalla actuales de la app

Esto proporcionará todo el contexto necesario para crear assets consistentes y profesionales.
