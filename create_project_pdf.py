# -*- coding: utf-8 -*-
"""Genera un PDF explicativo del proyecto RoomMate Match."""

import os
import textwrap
from datetime import date
from pathlib import Path

from PIL import Image as PILImage, ImageDraw, ImageFont, ImageFilter
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    Image,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT

PROJECT_ROOT = Path(__file__).parent.resolve()
ASSETS_DIR = PROJECT_ROOT / "assets"
PDF_ASSETS = PROJECT_ROOT / "docs" / "pdf_assets"
OUTPUT_PDF = PROJECT_ROOT / "docs" / "RoomMate_Match_Proyecto.pdf"

# Marca
PRIMARY_BLUE = (74, 144, 226)
PRIMARY_GREEN = (80, 227, 194)
DARK_BG = (26, 26, 46)
TEXT_DARK = (44, 62, 80)
WHITE = (255, 255, 255)


def hex_to_color(hex_code: str) -> colors.Color:
    h = hex_code.lstrip("#")
    return colors.Color(int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255)


def ensure_dirs():
    PDF_ASSETS.mkdir(parents=True, exist_ok=True)


def create_gradient_background(width: int, height: int, c1, c2, horizontal=False):
    img = PILImage.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    for i in range(width if horizontal else height):
        ratio = i / (width if horizontal else height)
        r = int(c1[0] + (c2[0] - c1[0]) * ratio)
        g = int(c1[1] + (c2[1] - c1[1]) * ratio)
        b = int(c1[2] + (c2[2] - c1[2]) * ratio)
        if horizontal:
            draw.line((i, 0, i, height), fill=(r, g, b))
        else:
            draw.line((0, i, width, i), fill=(r, g, b))
    return img


def make_app_icon_image(output_path: Path, size: int = 512):
    """Genera un icono de app tipo muestra basado en SVG/app icon."""
    img = create_gradient_background(size, size, PRIMARY_BLUE, PRIMARY_GREEN)
    draw = ImageDraw.Draw(img, "RGBA")
    # Casa simplificada
    margin = size // 4
    house_top = margin
    house_left = margin
    house_right = size - margin
    house_bottom = size - margin
    # Cuerpo casa
    draw.rectangle([house_left, house_top + size // 10, house_right, house_bottom],
                   fill=(255, 255, 255, 230), outline=(255, 255, 255), width=3)
    # Techo triángulo
    roof_y = house_top
    draw.polygon([(house_left, house_top + size // 10), (size // 2, roof_y), (house_right, house_top + size // 10)],
                 fill=(255, 255, 255, 230), outline=(255, 255, 255), width=3)
    # Puerta
    door_w = size // 7
    door_h = size // 5
    door_x = size // 2 - door_w // 2
    door_y = house_bottom - door_h
    draw.rounded_rectangle([door_x, door_y, door_x + door_w, door_y + door_h], radius=8, fill=PRIMARY_BLUE)
    # Ventanas
    win_s = size // 9
    win_y = house_top + size // 7
    draw.rounded_rectangle([house_left + size // 12, win_y, house_left + size // 12 + win_s, win_y + win_s],
                           radius=5, fill=PRIMARY_GREEN)
    draw.rounded_rectangle([house_right - size // 12 - win_s, win_y, house_right - size // 12, win_y + win_s],
                           radius=5, fill=PRIMARY_GREEN)
    # Personas
    p1 = (size // 2 - size // 9, size - margin - size // 18)
    p2 = (size // 2 + size // 9, size - margin - size // 18)
    for x, y in [p1, p2]:
        r = size // 22
        draw.ellipse([x - r, y - r * 2, x + r, y], fill=WHITE)
        draw.polygon([(x - size // 18, y), (x, y - size // 18), (x + size // 18, y),
                      (x + size // 18, y + size // 12), (x - size // 18, y + size // 12)], fill=WHITE)
    # Corazón
    hx, hy = size // 2, size - margin - size // 6
    draw.polygon([(hx, hy - size // 25), (hx - size // 20, hy), (hx - size // 40, hy + size // 30),
                  (hx, hy + size // 18), (hx + size // 40, hy + size // 30), (hx + size // 20, hy)],
                 fill=PRIMARY_GREEN)
    img.save(output_path, "PNG")


def make_screenshot_mockup(output_path: Path, title: str, labels: list, variant: int = 0):
    """Genera un mockup estilo screenshot de la app."""
    w, h = 540, 960
    img = PILImage.new("RGB", (w, h), (245, 245, 245))
    draw = ImageDraw.Draw(img, "RGBA")
    try:
        font = ImageFont.truetype("arial.ttf", 24)
        font_b = ImageFont.truetype("arial.ttf", 28)
        font_s = ImageFont.truetype("arial.ttf", 16)
    except Exception:
        font = ImageFont.load_default()
        font_b = font
        font_s = font

    # Header gradient
    header_h = 140
    for y in range(header_h):
        ratio = y / header_h
        c = tuple(int(PRIMARY_BLUE[i] + (PRIMARY_GREEN[i] - PRIMARY_BLUE[i]) * ratio) for i in range(3))
        draw.line((0, y, w, y), fill=c)
    # Título header
    draw.text((w // 2, 60), title, fill=WHITE, font=font_b, anchor="mm")

    # Card / content
    card_margin = 30
    card_top = header_h + 30
    card_w = w - 2 * card_margin
    card_h = h - card_top - 150
    # Sombra suave
    shadow = PILImage.new("RGBA", (w, h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle([card_margin + 4, card_top + 4, card_margin + card_w, card_top + card_h + 4],
                            radius=20, fill=(0, 0, 0, 40))
    img = PILImage.alpha_composite(img.convert("RGBA"), shadow)
    draw = ImageDraw.Draw(img, "RGBA")
    draw.rounded_rectangle([card_margin, card_top, card_margin + card_w, card_top + card_h], radius=20, fill=WHITE)

    # Perfil / contenido visual
    avatar_y = card_top + 40
    r = 70
    draw.ellipse([w // 2 - r, avatar_y - r, w // 2 + r, avatar_y + r],
                 fill=tuple(PRIMARY_BLUE if variant % 2 == 0 else PRIMARY_GREEN))
    draw.text((w // 2, avatar_y + 12), "👤", fill=WHITE, font=font_b, anchor="mm")

    # Nombre y score
    draw.text((w // 2, avatar_y + r + 25), "Usuario ejemplo", fill=TEXT_DARK, font=font_b, anchor="mm")
    draw.text((w // 2, avatar_y + r + 55), f"Compatibilidad: {80 + variant * 3}%", fill=PRIMARY_BLUE, font=font, anchor="mm")

    # Barras / factores
    y = avatar_y + r + 100
    bar_w = card_w - 60
    for i, label in enumerate(labels):
        draw.text((card_margin + 30, y), label, fill=TEXT_DARK, font=font_s)
        bar_fill = int(bar_w * (0.5 + 0.4 * ((i + variant) % 3) / 2))
        draw.rounded_rectangle([card_margin + 30, y + 22, card_margin + 30 + bar_w, y + 36], radius=8,
                               outline=(200, 200, 200), fill=(230, 230, 230), width=1)
        draw.rounded_rectangle([card_margin + 30, y + 22, card_margin + 30 + bar_fill, y + 36], radius=8,
                               fill=tuple(PRIMARY_BLUE if i % 2 == 0 else PRIMARY_GREEN))
        y += 55

    # Botones inferiores
    btn_y = h - 100
    # dislike
    draw.ellipse([80, btn_y, 80 + 80, btn_y + 80], fill=(236, 240, 241), outline=(231, 76, 60), width=3)
    draw.text((120, btn_y + 40), "✕", fill=(231, 76, 60), font=font_b, anchor="mm")
    # like
    draw.ellipse([w - 160, btn_y, w - 80, btn_y + 80], fill=(236, 240, 241), outline=(39, 174, 96), width=3)
    draw.text((w - 120, btn_y + 40), "♥", fill=(39, 174, 96), font=font_b, anchor="mm")

    img.convert("RGB").save(output_path, "PNG")


def make_color_palette_image(output_path: Path):
    w, h = 600, 100
    img = PILImage.new("RGB", (w, h), WHITE)
    draw = ImageDraw.Draw(img)
    swatches = [
        ("#4A90E2", "Azul primario"),
        ("#50E3C2", "Verde primario"),
        ("#9B59B6", "Púrpura secundario"),
        ("#1A1A2E", "Fondo oscuro"),
        ("#FFFFFF", "Fondo claro"),
    ]
    sw_w = w // len(swatches)
    try:
        font = ImageFont.truetype("arial.ttf", 18)
    except Exception:
        font = ImageFont.load_default()
    for i, (hex_code, name) in enumerate(swatches):
        x1 = i * sw_w
        x2 = x1 + sw_w - 5
        c = tuple(int(hex_code.lstrip("#")[j:j + 2], 16) for j in (0, 2, 4))
        draw.rectangle([x1, 0, x2, h - 30], fill=c, outline=(200, 200, 200), width=1)
        text_color = WHITE if c[0] * 0.299 + c[1] * 0.587 + c[2] * 0.114 < 128 else TEXT_DARK
        draw.text((x1 + sw_w // 2, h - 15), name, fill=text_color, font=font, anchor="mm")
    img.save(output_path, "PNG")


def make_architecture_diagram(output_path: Path):
    w, h = 700, 500
    img = PILImage.new("RGB", (w, h), (250, 250, 250))
    draw = ImageDraw.Draw(img, "RGBA")
    try:
        font = ImageFont.truetype("arial.ttf", 20)
        font_b = ImageFont.truetype("arial.ttf", 22)
    except Exception:
        font = ImageFont.load_default()
        font_b = font

    # Capas
    layers = [
        ("Cliente Flutter", ["iOS", "Android", "Web"], PRIMARY_BLUE, 30),
        ("Backend NestJS", ["API REST", "Socket.io", "Auth JWT"], PRIMARY_GREEN, 190),
        ("Base de datos", ["PostgreSQL", "Cloud Firestore", "Firebase Storage"], (155, 89, 182), 350),
    ]
    for title, items, color, y in layers:
        box = (100, y, w - 100, y + 110)
        draw.rounded_rectangle(box, radius=15, fill=color, outline=(255, 255, 255), width=2)
        draw.text((w // 2, y + 25), title, fill=WHITE, font=font_b, anchor="mm")
        txt = "  |  ".join(items)
        draw.text((w // 2, y + 70), txt, fill=WHITE, font=font, anchor="mm")

    # Flechas
    for y in [140, 300]:
        draw.polygon([(w // 2, y + 115), (w // 2 - 10, y + 100), (w // 2 + 10, y + 100)], fill=DARK_BG)
        draw.rectangle([w // 2 - 3, y + 110, w // 2 + 3, y + 130], fill=DARK_BG)

    # Pie
    draw.text((w // 2, h - 30), "Arquitectura RoomMate Match", fill=TEXT_DARK, font=font_b, anchor="mm")
    img.save(output_path, "PNG")


def page_header(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 9)
    canvas.setFillColor(colors.Color(0.5, 0.5, 0.5))
    canvas.drawRightString(A4[0] - 1.5 * cm, A4[1] - 1 * cm, "RoomMate Match - Documentación del Proyecto")
    canvas.restoreState()


def page_footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 9)
    canvas.setFillColor(colors.Color(0.5, 0.5, 0.5))
    canvas.drawString(1.5 * cm, 1 * cm, f"Página {doc.page}")
    canvas.restoreState()


def build_pdf():
    ensure_dirs()

    # Generar imágenes
    icon_path = PDF_ASSETS / "app_icon_512.png"
    make_app_icon_image(icon_path, 512)

    palette_path = PDF_ASSETS / "color_palette.png"
    make_color_palette_image(palette_path)

    arch_path = PDF_ASSETS / "architecture.png"
    make_architecture_diagram(arch_path)

    screen_titles = ["Descubrir", "Compatibilidad", "Chat", "Perfil", "Búsqueda de piso", "Premium"]
    screen_labels = [
        ["Horarios", "Limpieza", "Mascotas", "Tabaco"],
        ["Personalidad", "Visitas", "Cocina", "Música"],
        ["Mensajes", "Fotos", "Ubicación", "Notificaciones"],
        ["Fotos", "Preferencias", "Verificación", "Privacidad"],
        ["Presupuesto", "Zona", "Habitaciones", "Favoritos"],
        ["Likes", "Boost", "Invisible", "Sin anuncios"],
    ]
    screen_paths = []
    for i, (title, labels) in enumerate(zip(screen_titles, screen_labels)):
        p = PDF_ASSETS / f"screen_{i + 1}.png"
        make_screenshot_mockup(p, title, labels, variant=i)
        screen_paths.append(p)

    # Plantilla de documento
    doc = BaseDocTemplate(
        str(OUTPUT_PDF),
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=2.5 * cm,
        bottomMargin=2 * cm,
        title="RoomMate Match - Documento del Proyecto",
        author="RoomMate Match Team",
    )
    frame = Frame(2 * cm, 2 * cm, A4[0] - 4 * cm, A4[1] - 4.5 * cm)
    doc.addPageTemplates([
        PageTemplate(id="main", frames=frame, onPage=lambda c, d: (page_header(c, d), page_footer(c, d)))
    ])

    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle(
        name="TitleCenter", fontName="Helvetica-Bold", fontSize=28, leading=34,
        alignment=TA_CENTER, textColor=hex_to_color("#1A1A2E"), spaceAfter=20
    ))
    styles.add(ParagraphStyle(
        name="Heading", fontName="Helvetica-Bold", fontSize=18, leading=24,
        textColor=hex_to_color("#4A90E2"), spaceBefore=16, spaceAfter=10
    ))
    styles.add(ParagraphStyle(
        name="SubHeading", fontName="Helvetica-Bold", fontSize=14, leading=18,
        textColor=hex_to_color("#50E3C2"), spaceBefore=12, spaceAfter=6
    ))
    styles.add(ParagraphStyle(
        name="Body", fontName="Helvetica", fontSize=11, leading=14,
        alignment=TA_JUSTIFY, textColor=hex_to_color("#2C3E50"), spaceAfter=10
    ))
    styles.add(ParagraphStyle(
        name="Caption", fontName="Helvetica-Oblique", fontSize=10, leading=12,
        alignment=TA_CENTER, textColor=colors.Color(0.4, 0.4, 0.4), spaceAfter=12
    ))

    story = []

    # PORTADA
    story.append(Spacer(1, 2 * cm))
    story.append(Image(str(icon_path), width=8 * cm, height=8 * cm))
    story.append(Spacer(1, 1 * cm))
    story.append(Paragraph("RoomMate Match", styles["TitleCenter"]))
    story.append(Paragraph("Documentación técnica y de marca del proyecto", styles["TitleCenter"]))
    story.append(Spacer(1, 0.5 * cm))
    story.append(Paragraph(f"Fecha: {date.today().strftime('%d/%m/%Y')}", styles["Caption"]))
    story.append(PageBreak())

    # ÍNDICE
    story.append(Paragraph("Índice", styles["Heading"]))
    sections = [
        "1. Introducción al proyecto",
        "2. Identidad de marca y simbología",
        "3. Arquitectura y stack tecnológico",
        "4. Funcionalidades principales",
        "5. Mockups de la aplicación",
        "6. Modelo de negocio y premium",
        "7. Seguridad y privacidad",
        "8. Conclusión y próximos pasos",
    ]
    for s in sections:
        story.append(Paragraph(s, styles["Body"]))
    story.append(PageBreak())

    # 1. Introducción
    story.append(Paragraph("1. Introducción al proyecto", styles["Heading"]))
    story.append(Paragraph(
        "RoomMate Match es una aplicación móvil nativa multiplataforma (iOS y Android) concebida como un 'Tinder para compañeros de piso'. "
        "A diferencia de las plataformas tradicionales de alquiler, la app pone el foco en la <b>compatibilidad humana</b>: ayuda a las personas a encontrar a alguien con quien convivir de forma armónica antes de buscar la vivienda en sí.",
        styles["Body"]
    ))
    story.append(Paragraph(
        "El proyecto nace para resolver uno de los mayores dolores de cabeza del alquiler compartido: los conflictos de convivencia. "
        "Mediante un algoritmo de matching de nueve factores, perfiles verificados, chat en tiempo real e integración con portales inmobiliarios, "
        "RoomMate Match ofrece una experiencia segura, intuitiva y centrada en las personas.",
        styles["Body"]
    ))
    story.append(Paragraph(
        "El lema de la marca es <i>\"Encuentra tu compañero de piso ideal\"</i>, reflejando la promesa de valor principal: compatibilidad, confianza y comunidad.",
        styles["Body"]
    ))
    story.append(PageBreak())

    # 2. Identidad de marca
    story.append(Paragraph("2. Identidad de marca y simbología", styles["Heading"]))
    story.append(Paragraph(
        "La identidad visual de RoomMate Match transmite confianza, modernidad y cercanía. El icono principal combina una silueta de casa, "
        "dos figuras humanas y un corazón, simbolizando hogar, compañía y buenas relaciones.",
        styles["Body"]
    ))
    story.append(Image(str(icon_path), width=5 * cm, height=5 * cm))
    story.append(Paragraph("Icono principal generado para la documentación", styles["Caption"]))

    story.append(Paragraph("Paleta de colores", styles["SubHeading"]))
    story.append(Image(str(palette_path), width=14 * cm, height=2.3 * cm))
    story.append(Paragraph("Códigos hexadecimales de la paleta corporativa", styles["Caption"]))

    story.append(Paragraph("Tipografía", styles["SubHeading"]))
    story.append(Paragraph(
        "Se utiliza <b>SF Pro Display</b> en iOS y <b>Roboto</b> en Android. Los títulos se muestran en peso Bold (700), "
        "el cuerpo en Regular (400) y los subtítulos/leyendas en Light (300).",
        styles["Body"]
    ))
    story.append(Paragraph(
        "Los valores de marca son: <b>Compatibility First</b> (prioridad a las personas), <b>Trust</b> (perfiles verificados), "
        "<b>Community</b> (mejorar la convivencia) y <b>Simplicity</b> (experiencia intuitiva).",
        styles["Body"]
    ))
    story.append(PageBreak())

    # 3. Arquitectura
    story.append(Paragraph("3. Arquitectura y stack tecnológico", styles["Heading"]))
    story.append(Image(str(arch_path), width=14 * cm, height=10 * cm))
    story.append(Paragraph("Diagrama de arquitectura de alto nivel", styles["Caption"]))

    story.append(Paragraph("Frontend (móvil)", styles["SubHeading"]))
    story.append(Paragraph(
        "La app móvil está desarrollada con <b>Flutter 3.x</b>, usando <b>Provider</b> para la gestión de estado y <b>Material Design 3</b> como base visual. "
        "La autenticación corre sobre <b>Firebase Auth</b>, mientras que <b>Cloud Firestore</b>, <b>Firebase Storage</b> y <b>Firebase Cloud Messaging</b> "
        "cubren datos, almacenamiento de archivos y notificaciones push. El chat utiliza el cliente de <b>Socket.io</b>.",
        styles["Body"]
    ))
    story.append(Paragraph("Backend", styles["SubHeading"]))
    story.append(Paragraph(
        "El servidor está construido con <b>NestJS 10.x</b> en <b>TypeScript</b>, conectado a una base de datos <b>PostgreSQL 15</b> mediante <b>TypeORM</b>. "
        "Ofrece autenticación con <b>Firebase Admin SDK</b>, comunicación en tiempo real con <b>Socket.io</b>, validación de DTOs con <b>class-validator</b> "
        "y documentación automática de API con <b>Swagger</b>.",
        styles["Body"]
    ))
    story.append(Paragraph("Infraestructura", styles["SubHeading"]))
    story.append(Paragraph(
        "La infraestructura se despliega en <b>Google Cloud Platform</b> o <b>AWS</b>, usando <b>Cloud SQL / RDS</b> para PostgreSQL, "
        "<b>Firebase Storage</b> para archivos y <b>GitHub Actions</b> para CI/CD.",
        styles["Body"]
    ))
    story.append(PageBreak())

    # 4. Funcionalidades
    story.append(Paragraph("4. Funcionalidades principales", styles["Heading"]))
    features = [
        ("Swipe de perfiles", "Interfaz tipo tarjeta para dar like o pasar, con notificación de match mutuo."),
        ("Algoritmo de compatibilidad", "Puntúa 9 dimensiones: horarios, limpieza, tabaco, mascotas, personalidad, visitas, cocina, ruido y teletrabajo."),
        ("Chat en tiempo real", "Mensajería instantánea con Socket.io, envío de fotos y ubicación."),
        ("Filtros avanzados", "Edad, ciudad, presupuesto, hábitos y preferencias."),
        ("Grupos de convivencia", "Crea grupos con matches y calcula compatibilidad grupal."),
        ("Búsqueda de pisos", "Integración con Idealista y Fotocasa para buscar viviendas juntos."),
        ("Verificación de identidad", "Email, teléfono, selfie y documento opcional."),
        ("Sistema premium", "Likes ilimitados, ver quién dio like, boost, modo invisible y sin anuncios."),
    ]
    data = [[Paragraph(f"<b>{t}</b>", styles["Body"]), Paragraph(d, styles["Body"])] for t, d in features]
    table = Table(data, colWidths=[5 * cm, 9.5 * cm])
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.Color(0.97, 0.97, 0.97)),
        ("ROWBACKGROUNDS", (0, 0), (-1, -1), [colors.Color(1, 1, 1), colors.Color(0.97, 0.97, 0.97)]),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.Color(0.85, 0.85, 0.85)),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
    ]))
    story.append(table)
    story.append(PageBreak())

    # 5. Mockups
    story.append(Paragraph("5. Mockups de la aplicación", styles["Heading"]))
    story.append(Paragraph(
        "A continuación se presentan representaciones conceptuales de las principales pantallas de RoomMate Match. "
        "Los diseños finales deben seguir las guías de marca y los tamaños de captura definidos para Google Play y App Store.",
        styles["Body"]
    ))
    for i in range(0, len(screen_paths), 2):
        row = []
        for p in screen_paths[i:i + 2]:
            img = Image(str(p), width=5.5 * cm, height=9.78 * cm)
            row.append(img)
        if len(row) == 1:
            row.append(Spacer(1, 1))
        table = Table([row], colWidths=[7.5 * cm, 7.5 * cm])
        table.setStyle(TableStyle([
            ("ALIGN", (0, 0), (-1, -1), "CENTER"),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("LEFTPADDING", (0, 0), (-1, -1), 5),
            ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ]))
        story.append(table)
        story.append(Spacer(1, 0.4 * cm))

    # 6. Modelo de negocio
    story.append(PageBreak())
    story.append(Paragraph("6. Modelo de negocio y premium", styles["Heading"]))
    story.append(Paragraph(
        "RoomMate Match sigue un modelo <b>freemium</b>. La capa gratuita permite 10 likes diarios, chat básico y filtros estándar. "
        "La suscripción premium desbloquea likes ilimitados, la lista de perfiles que dieron like, filtros avanzados, boost del perfil y modo invisible.",
        styles["Body"]
    ))
    story.append(Paragraph(
        "Además, la integración con portales de alquiler abre oportunidades de monetización por referidos y publicidad inmobiliaria contextual.",
        styles["Body"]
    ))

    # 7. Seguridad
    story.append(Paragraph("7. Seguridad y privacidad", styles["Heading"]))
    story.append(Paragraph(
        "La seguridad es un pilar del proyecto. Se implementa autenticación con <b>Firebase Auth + JWT</b>, comunicación <b>HTTPS + WSS</b>, "
        "encriptación en la base de datos, validación estricta de datos en el backend y limitación de tasa de peticiones (<b>@nestjs/throttler</b>). "
        "El cumplimiento con <b>GDPR</b> y <b>CCPA</b> se contempla en las políticas de privacidad y en las opciones de gestión de datos del usuario.",
        styles["Body"]
    ))

    # 8. Conclusión
    story.append(Paragraph("8. Conclusión y próximos pasos", styles["Heading"]))
    story.append(Paragraph(
        "RoomMate Match es un proyecto completo que abarca diseño de marca, desarrollo móvil, backend escalable, bases de datos relacionales "
        "y servicios en la nube. El siguiente paso prioritario es capturar screenshots reales del emulador y completar los assets de tienda "
        "(iconos finales, feature graphic y descripciones) para preparar el lanzamiento en App Store y Google Play.",
        styles["Body"]
    ))
    story.append(Paragraph(
        "Este documento sirve como referencia interna para el equipo y como base para presentaciones a inversores, diseñadores o revisores de las tiendas de aplicaciones.",
        styles["Body"]
    ))

    doc.build(story)
    print(f"PDF generado correctamente en: {OUTPUT_PDF}")


if __name__ == "__main__":
    build_pdf()
