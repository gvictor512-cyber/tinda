# -*- coding: utf-8 -*-
"""Genera el PDF de documentación del proyecto RoomMate Match.

Usa las capturas reales de tienda (assets/store/app-store/screenshots)
y la paleta real definida en mobile/lib/config/theme.dart.

Uso:  python3 create_project_pdf.py
"""

from datetime import date
from pathlib import Path

from PIL import Image as PILImage, ImageDraw, ImageFont
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
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

PROJECT_ROOT = Path(__file__).parent.resolve()
MOBILE_DIR = PROJECT_ROOT / "mobile"
ICON_PATH = PROJECT_ROOT / "assets" / "app-icons" / "android" / "mipmap-xxxhdpi" / "ic_launcher.png"
PDF_ASSETS = PROJECT_ROOT / "docs" / "pdf_assets"
OUTPUT_PDF = PROJECT_ROOT / "docs" / "RoomMate_Match_Proyecto.pdf"

# Capturas reales del dispositivo (1080x2400)
REAL_SHOTS = {
    "welcome": MOBILE_DIR / "flutter_14.png",
    "login": MOBILE_DIR / "screenshot_playstore.png",
    "discover": MOBILE_DIR / "flutter_01.png",
    "profile": MOBILE_DIR / "flutter_09.png",
    "help": MOBILE_DIR / "flutter_05.png",
}

# Paleta real (mobile/lib/config/theme.dart)
C_BLUE = "#1FA5F0"
C_GREEN = "#50E3C2"
C_GREEN_DARK = "#059669"
C_DARK = "#1A1A2E"
C_SLATE = "#334155"
C_GRAY = "#64748B"
C_LIGHT = "#F1F5F9"
C_PURPLE = "#9B59B6"
C_RED = "#EF4444"


def hc(hex_code: str) -> colors.Color:
    h = hex_code.lstrip("#")
    return colors.Color(
        int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255
    )


def rgb(hex_code: str):
    h = hex_code.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def gradient_image(path: Path, w: int, h: int, c1: str, c2: str):
    img = PILImage.new("RGB", (w, h))
    draw = ImageDraw.Draw(img)
    a, b = rgb(c1), rgb(c2)
    for x in range(w):
        r = x / w
        draw.line(
            (x, 0, x, h),
            fill=tuple(int(a[i] + (b[i] - a[i]) * r) for i in range(3)),
        )
    img.save(path, "PNG")


def architecture_diagram(path: Path):
    w, h = 1200, 780
    img = PILImage.new("RGB", (w, h), rgb(C_LIGHT))
    draw = ImageDraw.Draw(img, "RGBA")
    try:
        f_title = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 34)
        f_box = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 30)
        f_small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 24)
    except OSError:
        f_title = f_box = f_small = ImageFont.load_default()

    draw.text((w // 2, 40), "ARQUITECTURA DE TRES CAPAS",
              fill=rgb(C_DARK), font=f_title, anchor="mm")

    layers = [
        ("APP MÓVIL — FLUTTER",
         "iOS · Android · Web   |   Provider · Material 3", C_BLUE, 90),
        ("BACKEND — NESTJS 10",
         "API REST · Socket.io · Firebase Admin · TypeORM", C_GREEN_DARK, 320),
        ("DATOS Y SERVICIOS",
         "PostgreSQL · Cloud Firestore · Firebase Storage · FCM", C_PURPLE, 550),
    ]
    for title, subtitle, color, y in layers:
        draw.rounded_rectangle([90, y, w - 90, y + 130], radius=24,
                               fill=rgb(color))
        draw.text((w // 2, y + 45), title, fill="white", font=f_box, anchor="mm")
        draw.text((w // 2, y + 92), subtitle, fill="white", font=f_small,
                  anchor="mm")

    # Flechas bidireccionales entre capas
    for y in (220, 450):
        draw.rectangle([w // 2 - 30, y, w // 2 - 22, y + 100],
                       fill=rgb(C_DARK))
        draw.rectangle([w // 2 + 22, y, w // 2 + 30, y + 100],
                       fill=rgb(C_DARK))
        draw.polygon([(w // 2 - 42, y + 100), (w // 2 - 10, y + 100),
                      (w // 2 - 26, y + 122)], fill=rgb(C_DARK))
        draw.polygon([(w // 2 + 42, y), (w // 2 + 10, y),
                      (w // 2 + 26, y - 22)], fill=rgb(C_DARK))

    draw.text(
        (w // 2, h - 45),
        "Comunicación HTTPS + WSS autenticada con Firebase ID Token",
        fill=rgb(C_GRAY), font=f_small, anchor="mm",
    )
    img.save(path, "PNG")


# ---------- Wireframes ilustrativos (1080x2400, estilo de la app) ----------

MW, MH = 1080, 2400


def _load_font(size, bold=False):
    name = "Helvetica-Bold" if bold else "Helvetica"
    try:
        return ImageFont.truetype(f"/System/Library/Fonts/{name}.ttf", size)
    except OSError:
        try:
            return ImageFont.truetype(
                "/System/Library/Fonts/Helvetica.ttc", size)
        except OSError:
            return ImageFont.load_default()


def _phone_canvas(title=""):
    img = PILImage.new("RGB", (MW, MH), rgb(C_DARK))
    d = ImageDraw.Draw(img)
    f_title = _load_font(56, bold=True)
    if title:
        d.text((MW // 2, 180), title, fill="white", font=f_title, anchor="mm")
    # Barra de navegación inferior
    d.rounded_rectangle([0, MH - 170, MW, MH], radius=0, fill=rgb("#141428"))
    labels = ["Descubrir", "Likes", "Mensajes", "Perfil", "Más"]
    f_nav = _load_font(28)
    for i, lab in enumerate(labels):
        cx = int(MW * (i + 0.5) / 5)
        d.ellipse([cx - 22, MH - 140, cx + 22, MH - 96],
                  outline=rgb(C_BLUE), width=4)
        d.text((cx, MH - 62), lab, fill=rgb(C_GRAY), font=f_nav, anchor="mm")
    return img, d


def _card(d, box, fill="#25253D", radius=32, outline=None):
    d.rounded_rectangle(box, radius=radius, fill=rgb(fill),
                        outline=outline and rgb(outline))


def _check(d, x, y, s, color):
    d.line([(x, y + s * 0.55), (x + s * 0.35, y + s)], fill=rgb(color),
           width=int(s * 0.18))
    d.line([(x + s * 0.35, y + s), (x + s, y)], fill=rgb(color),
           width=int(s * 0.18))


def _x_mark(d, cx, cy, r, color):
    d.line([(cx - r, cy - r), (cx + r, cy + r)], fill=rgb(color),
           width=int(r * 0.3))
    d.line([(cx - r, cy + r), (cx + r, cy - r)], fill=rgb(color),
           width=int(r * 0.3))


def _star(d, cx, cy, r, color):
    import math
    pts = []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        rad = r if i % 2 == 0 else r * 0.42
        pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
    d.polygon(pts, fill=rgb(color))


def _heart(d, cx, cy, r, color):
    d.ellipse([cx - r, cy - r * 0.9, cx, cy + r * 0.15], fill=rgb(color))
    d.ellipse([cx, cy - r * 0.9, cx + r, cy + r * 0.15], fill=rgb(color))
    d.polygon([(cx - r * 0.93, cy - r * 0.2), (cx + r * 0.93, cy - r * 0.2),
               (cx, cy + r)], fill=rgb(color))


def _person(d, cx, cy, r, color):
    d.ellipse([cx - r * 0.42, cy - r, cx + r * 0.42, cy - r * 0.16],
              fill=rgb(color))
    d.pieslice([cx - r, cy - r * 0.1, cx + r, cy + r * 1.9], 180, 360,
               fill=rgb(color))


def _house(d, cx, cy, s, color):
    d.rectangle([cx - s * 0.7, cy - s * 0.1, cx + s * 0.7, cy + s * 0.9],
                fill=rgb(color))
    d.polygon([(cx - s * 0.85, cy - s * 0.1), (cx + s * 0.85, cy - s * 0.1),
               (cx, cy - s * 0.8)], fill=rgb(color))


def _crown(d, cx, cy, s, color):
    pts = [(cx - s, cy + s * 0.5), (cx - s, cy - s * 0.4),
           (cx - s * 0.5, cy), (cx, cy - s * 0.7), (cx + s * 0.5, cy),
           (cx + s, cy - s * 0.4), (cx + s, cy + s * 0.5)]
    d.polygon(pts, fill=rgb(color))
    d.rectangle([cx - s, cy + s * 0.55, cx + s, cy + s * 0.8],
                fill=rgb(color))


def _icon_chip(d, cx, cy, label, color):
    d.rounded_rectangle([cx - 55, cy - 55, cx + 55, cy + 55], radius=26,
                        fill=rgb(color))
    d.text((cx, cy), label, fill="white",
           font=_load_font(52, bold=True), anchor="mm")


def mockup_swipe(path):
    img, d = _phone_canvas("Descubrir")
    # Tarjeta de perfil
    _card(d, [80, 280, MW - 80, 1650], fill="#25253D", radius=48)
    d.rounded_rectangle([80, 280, MW - 80, 1180], radius=48, fill=rgb(C_BLUE))
    # "Foto"
    d.ellipse([MW // 2 - 150, 540, MW // 2 + 150, 840], fill=rgb("#0D47A1"))
    _person(d, MW // 2, 690, 110, "#BBDEFB")
    f_name = _load_font(72, bold=True)
    d.text((140, 1290), "Laura, 26", fill="white", font=f_name)
    f_sub = _load_font(40)
    d.text((140, 1380), "Madrid · Estudiante", fill=rgb("#94A3B8"), font=f_sub)
    # Badge compatibilidad
    _card(d, [140, 1480, 560, 1590], fill=C_GREEN_DARK, radius=56)
    d.text((350, 1535), "92% compatible", fill="white",
           font=_load_font(44, bold=True), anchor="mm")
    # Botones de acción
    for cx, col, sym in ((260, C_RED, "x"), (540, "#F59E0B", "star"),
                         (820, C_GREEN, "heart")):
        d.ellipse([cx - 90, 1780, cx + 90, 1960], fill=rgb("#1E293B"),
                  outline=rgb(col), width=6)
        if sym == "x":
            _x_mark(d, cx, 1870, 45, col)
        elif sym == "star":
            _star(d, cx, 1870, 55, col)
        else:
            _heart(d, cx, 1870, 55, col)
    img.save(path, "PNG")


def mockup_compatibility(path):
    img, d = _phone_canvas("Compatibilidad")
    d.ellipse([MW // 2 - 200, 300, MW // 2 + 200, 700],
              outline=rgb(C_GREEN), width=26)
    d.text((MW // 2, 500), "92%", font=_load_font(140, bold=True),
           fill="white", anchor="mm")
    d.text((MW // 2, 640), "Muy compatible", font=_load_font(40),
           fill=rgb(C_GREEN), anchor="mm")
    factors = [("Horarios", 95), ("Limpieza", 88), ("Tabaco", 100),
               ("Mascotas", 90), ("Visitas", 75), ("Ruido", 85),
               ("Cocina", 92), ("Teletrabajo", 80)]
    f_lab = _load_font(44)
    y = 830
    for name, pct in factors:
        d.text((90, y), name, fill="white", font=f_lab)
        d.rounded_rectangle([90, y + 70, MW - 260, y + 110], radius=20,
                            fill=rgb("#1E293B"))
        w = int((MW - 350) * pct / 100)
        color = C_GREEN if pct >= 80 else "#F59E0B"
        d.rounded_rectangle([90, y + 70, 90 + w, y + 110], radius=20,
                            fill=rgb(color))
        d.text((MW - 90, y + 90), f"{pct}%", fill=rgb(color),
               font=_load_font(40, bold=True), anchor="rm")
        y += 185
    img.save(path, "PNG")


def mockup_chat(path):
    img, d = _phone_canvas("Laura")
    f_txt = _load_font(42)
    f_time = _load_font(28)
    msgs = [
        ("left", "¡Hola! Vi que también buscas\npiso por Malasaña", "12:40"),
        ("right", "¡Sí! Tu perfil me pareció\nsúper compatible", "12:41"),
        ("left", "¿Quieres ver este piso que\nencontré? Tiene 2 habitaciones", "12:42"),
        ("right", "¡Perfecto! ¿Cuándo podemos\nvisitarlo?", "12:43"),
    ]
    y = 300
    for side, txt, t in msgs:
        lines = txt.split("\n")
        bw = 640
        bh = 60 * len(lines) + 70
        x0 = 90 if side == "left" else MW - 90 - bw
        fill = "#25253D" if side == "left" else C_BLUE
        _card(d, [x0, y, x0 + bw, y + bh], fill=fill, radius=36)
        for i, ln in enumerate(lines):
            d.text((x0 + 40, y + 45 + i * 58), ln, fill="white", font=f_txt)
        d.text((x0 + bw - 30, y + bh - 28), t, fill=rgb("#94A3B8"),
               font=f_time, anchor="rm")
        y += bh + 50
    # Barra de entrada
    _card(d, [60, MH - 330, MW - 220, MH - 220], fill="#25253D", radius=55)
    d.text((110, MH - 275), "Escribe un mensaje...", fill=rgb("#94A3B8"),
           font=f_txt, anchor="lm")
    d.ellipse([MW - 200, MH - 325, MW - 70, MH - 225], fill=rgb(C_GREEN))
    d.polygon([(MW - 165, MH - 300), (MW - 105, MH - 275),
               (MW - 165, MH - 250)], fill=rgb(C_DARK))
    img.save(path, "PNG")


def mockup_apartment(path):
    img, d = _phone_canvas("Buscar vivienda")
    # Chips de filtro
    x = 90
    for label in ("Madrid", "600-900€", "2 hab."):
        w = 90 + len(label) * 26
        _card(d, [x, 270, x + w, 350], fill="#25253D", radius=40,
              outline=C_BLUE)
        d.text((x + w // 2, 310), label, fill=rgb(C_BLUE),
               font=_load_font(36), anchor="mm")
        x += w + 30
    # Tarjeta de piso
    _card(d, [80, 430, MW - 80, 1500], fill="#25253D", radius=40)
    d.rounded_rectangle([80, 430, MW - 80, 1030], radius=40, fill=rgb("#334155"))
    _house(d, MW // 2, 720, 220, "#94A3B8")
    d.text((140, 1120), "Piso luminoso en Malasaña", fill="white",
           font=_load_font(52, bold=True))
    d.text((140, 1210), "750€/mes · 2 hab · 85 m²", fill=rgb(C_GREEN),
           font=_load_font(44, bold=True))
    d.text((140, 1290), "Idealista · hace 2 días", fill=rgb("#94A3B8"),
           font=_load_font(36))
    _card(d, [140, 1360, 460, 1450], fill=C_GREEN_DARK, radius=45)
    _heart(d, 195, 1405, 26, "#FFFFFF")
    d.text((330, 1405), "Favorito", fill="white",
           font=_load_font(38, bold=True), anchor="mm")
    # Segunda tarjeta parcial
    _card(d, [80, 1560, MW - 80, 1900], fill="#25253D", radius=40)
    d.rounded_rectangle([80, 1560, MW - 80, 1900], radius=40,
                        fill=rgb("#3B3B58"))
    img.save(path, "PNG")


def mockup_premium(path):
    img, d = _phone_canvas("RoomMate Premium")
    _crown(d, MW // 2, 330, 140, "#F59E0B")
    d.text((MW // 2, 480), "Desbloquea todo el potencial",
           font=_load_font(48, bold=True), fill="white", anchor="mm")
    feats = ["Likes ilimitados", "Ver quién te dio like", "Deshacer swipes",
             "Boosts mensuales", "Filtros avanzados", "Sin anuncios"]
    y = 580
    for f in feats:
        _check(d, 140, y - 10, 45, C_GREEN)
        d.text((230, y), f, fill="white", font=_load_font(44))
        y += 110
    # Planes
    _card(d, [80, 1290, MW // 2 - 25, 1650], fill="#25253D", radius=36,
          outline="#475569")
    d.text(((80 + MW // 2 - 25) // 2, 1370), "MENSUAL",
           font=_load_font(38, bold=True), fill=rgb("#94A3B8"), anchor="mm")
    d.text(((80 + MW // 2 - 25) // 2, 1470), "9,99€",
           font=_load_font(88, bold=True), fill="white", anchor="mm")
    d.text(((80 + MW // 2 - 25) // 2, 1560), "por mes", font=_load_font(34),
           fill=rgb("#94A3B8"), anchor="mm")
    _card(d, [MW // 2 + 25, 1290, MW - 80, 1650], fill=C_BLUE, radius=36)
    d.text(((MW // 2 + 25 + MW - 80) // 2, 1370), "ANUAL",
           font=_load_font(38, bold=True), fill="white", anchor="mm")
    d.text(((MW // 2 + 25 + MW - 80) // 2, 1470), "59,99€",
           font=_load_font(88, bold=True), fill="white", anchor="mm")
    d.text(((MW // 2 + 25 + MW - 80) // 2, 1560), "ahorra 50%",
           font=_load_font(34), fill=rgb(C_GREEN), anchor="mm")
    _card(d, [140, 1780, MW - 140, 1930], fill=C_GREEN, radius=75)
    d.text((MW // 2, 1855), "Empezar prueba gratuita",
           font=_load_font(48, bold=True), fill=rgb(C_DARK), anchor="mm")
    img.save(path, "PNG")


def mockup_privacy(path):
    img, d = _phone_canvas("Privacidad y datos")
    items = [
        ("D", "Descargar mis datos", "Copia de tu información", C_BLUE),
        ("R", "Rectificar datos", "Corrige información incorrecta", C_BLUE),
        ("E", "Exportar datos", "Portabilidad RGPD", C_BLUE),
        ("C", "Consentimientos", "Gestiona tus permisos", C_PURPLE),
        ("B", "Usuarios bloqueados", "3 usuarios", "#F59E0B"),
        ("X", "Eliminar cuenta", "Borrado permanente", C_RED),
    ]
    f_t = _load_font(46, bold=True)
    f_s = _load_font(34)
    y = 290
    for label, title, sub, color in items:
        _card(d, [80, y, MW - 80, y + 200], fill="#25253D", radius=32)
        _icon_chip(d, 160, y + 100, label, color)
        d.text((250, y + 70), title, fill="white", font=f_t)
        d.text((250, y + 135), sub, fill=rgb("#94A3B8"), font=f_s)
        d.text((MW - 140, y + 100), ">", fill=rgb(C_GRAY),
               font=_load_font(72, bold=True), anchor="mm")
        y += 250
    img.save(path, "PNG")


MOCKUP_GENERATORS = {
    "swipe": mockup_swipe,
    "compatibility": mockup_compatibility,
    "chat": mockup_chat,
    "apartment": mockup_apartment,
    "premium": mockup_premium,
    "privacy": mockup_privacy,
}


def on_page(canvas, doc):
    canvas.saveState()
    # Banda superior de marca
    canvas.setFillColor(hc(C_BLUE))
    canvas.rect(0, A4[1] - 0.5 * cm, A4[0], 0.5 * cm, stroke=0, fill=1)
    canvas.setFillColor(hc(C_GREEN))
    canvas.rect(0, A4[1] - 0.62 * cm, A4[0], 0.12 * cm, stroke=0, fill=1)
    # Cabecera
    canvas.setFont("Helvetica-Bold", 8.5)
    canvas.setFillColor(hc(C_GRAY))
    canvas.drawString(2 * cm, A4[1] - 1.1 * cm, "ROOMMATE MATCH")
    canvas.drawRightString(
        A4[0] - 2 * cm, A4[1] - 1.1 * cm, "Documentación del proyecto")
    # Pie
    canvas.setStrokeColor(hc(C_LIGHT))
    canvas.setLineWidth(0.6)
    canvas.line(2 * cm, 1.4 * cm, A4[0] - 2 * cm, 1.4 * cm)
    canvas.setFont("Helvetica", 8.5)
    canvas.setFillColor(hc(C_GRAY))
    canvas.drawString(2 * cm, 1 * cm, "Confidencial — uso interno")
    canvas.drawRightString(A4[0] - 2 * cm, 1 * cm, f"Página {doc.page}")
    canvas.restoreState()


def make_styles():
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle(
        name="CoverTitle", fontName="Helvetica-Bold", fontSize=34, leading=40,
        alignment=TA_CENTER, textColor=hc(C_DARK), spaceAfter=10))
    styles.add(ParagraphStyle(
        name="CoverSub", fontName="Helvetica", fontSize=15, leading=20,
        alignment=TA_CENTER, textColor=hc(C_GRAY), spaceAfter=6))
    styles.add(ParagraphStyle(
        name="H1", fontName="Helvetica-Bold", fontSize=19, leading=24,
        textColor=hc(C_DARK), spaceBefore=10, spaceAfter=8))
    styles.add(ParagraphStyle(
        name="H2", fontName="Helvetica-Bold", fontSize=13.5, leading=17,
        textColor=hc(C_BLUE), spaceBefore=12, spaceAfter=5))
    styles.add(ParagraphStyle(
        name="Body", fontName="Helvetica", fontSize=10.5, leading=15,
        alignment=TA_JUSTIFY, textColor=hc(C_SLATE), spaceAfter=8))
    styles.add(ParagraphStyle(
        name="Item", fontName="Helvetica", fontSize=10.5, leading=15,
        leftIndent=14, bulletIndent=4, textColor=hc(C_SLATE), spaceAfter=4))
    styles.add(ParagraphStyle(
        name="Caption", fontName="Helvetica-Oblique", fontSize=9, leading=12,
        alignment=TA_CENTER, textColor=hc(C_GRAY), spaceBefore=6, spaceAfter=10))
    styles.add(ParagraphStyle(
        name="TOCItem", fontName="Helvetica", fontSize=11.5, leading=24,
        leftIndent=16, textColor=hc(C_SLATE)))
    styles.add(ParagraphStyle(
        name="TableHead", fontName="Helvetica-Bold", fontSize=10, leading=13,
        textColor=colors.white, alignment=TA_LEFT))
    styles.add(ParagraphStyle(
        name="TableCell", fontName="Helvetica", fontSize=9.5, leading=13,
        textColor=hc(C_SLATE)))
    styles.add(ParagraphStyle(
        name="TableCellBold", fontName="Helvetica-Bold", fontSize=9.5,
        leading=13, textColor=hc(C_DARK)))
    return styles


S = None  # estilos globales


def bullets(items):
    return [
        Paragraph(f'<bullet>&bull;</bullet>{i}', S["Item"]) for i in items
    ]


def shot(path: Path, width_cm: float = 5.4) -> Image:
    """Imagen de pantalla 1080x2400 (ratio 0.45)."""
    return Image(str(path), width=width_cm * cm, height=width_cm / 0.45 * cm)


def section_with_shot(num, title, image_paths, blocks, caption):
    """Sección con texto a la izquierda y 1-2 capturas a la derecha."""
    story = [Paragraph(f"{num}. {title}", S["H1"]), accent_rule(),
             Spacer(1, 0.3 * cm)]
    if isinstance(image_paths, Path):
        image_paths = [image_paths]
    if len(image_paths) == 1:
        img_cell = shot(image_paths[0])
        text_w, img_w = 10.6, 6.0
    else:
        # Dos capturas lado a lado, más pequeñas
        inner = Table(
            [[shot(image_paths[0], 2.8), shot(image_paths[1], 2.8)]],
            colWidths=[3.0 * cm, 3.0 * cm],
        )
        inner.setStyle(TableStyle([
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("ALIGN", (0, 0), (-1, -1), "CENTER"),
            ("LEFTPADDING", (0, 0), (-1, -1), 0),
            ("RIGHTPADDING", (0, 0), (-1, -1), 0),
        ]))
        img_cell = inner
        text_w, img_w = 10.4, 6.2
    cell_text = blocks + [Paragraph(caption, S["Caption"])]
    table = Table(
        [[cell_text, img_cell]],
        colWidths=[text_w * cm, img_w * cm],
    )
    table.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("ALIGN", (1, 0), (1, 0), "CENTER"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (0, 0), 14),
    ]))
    story.append(table)
    story.append(PageBreak())
    return story


def data_table(headers, rows, widths):
    data = [[Paragraph(h, S["TableHead"]) for h in headers]]
    for row in rows:
        data.append([
            Paragraph(f"<b>{row[0]}</b>", S["TableCellBold"]),
            *[Paragraph(str(c), S["TableCell"]) for c in row[1:]],
        ])
    t = Table(data, colWidths=widths, repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), hc(C_DARK)),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, hc(C_LIGHT)]),
        ("GRID", (0, 0), (-1, -1), 0.5, hc("#CBD5E1")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    return t


def accent_rule():
    t = Table([[""]], colWidths=[4 * cm], rowHeights=[0.12 * cm])
    t.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), hc(C_GREEN))]))
    return t


def build_pdf():
    global S
    S = make_styles()
    PDF_ASSETS.mkdir(parents=True, exist_ok=True)

    banner_path = PDF_ASSETS / "cover_banner.png"
    gradient_image(banner_path, 1600, 420, C_BLUE, C_GREEN)
    arch_path = PDF_ASSETS / "architecture.png"
    architecture_diagram(arch_path)
    mockups = {}
    for key, gen in MOCKUP_GENERATORS.items():
        p = PDF_ASSETS / f"mockup_{key}.png"
        gen(p)
        mockups[key] = p

    doc = BaseDocTemplate(
        str(OUTPUT_PDF),
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
        title="RoomMate Match — Documentación del proyecto",
        author="RoomMate Match Team",
    )
    frame = Frame(2 * cm, 1.6 * cm, A4[0] - 4 * cm, A4[1] - 3.4 * cm)
    doc.addPageTemplates([PageTemplate(id="main", frames=frame, onPage=on_page)])

    story = []

    # ---------- PORTADA ----------
    story.append(Spacer(1, 0.6 * cm))
    story.append(Image(str(banner_path), width=17 * cm, height=4.4 * cm))
    story.append(Spacer(1, 1.4 * cm))
    story.append(Table(
        [[Image(str(ICON_PATH), width=3.6 * cm, height=3.6 * cm)]],
        colWidths=[17 * cm],
        style=TableStyle([("ALIGN", (0, 0), (-1, -1), "CENTER")]),
    ))
    story.append(Spacer(1, 0.5 * cm))
    story.append(Paragraph("RoomMate Match", S["CoverTitle"]))
    story.append(Paragraph(
        "Documentación funcional y técnica del proyecto", S["CoverSub"]))
    story.append(Spacer(1, 0.3 * cm))
    story.append(Paragraph(
        '<i>"Encuentra tu compañero de piso ideal"</i>', S["CoverSub"]))
    story.append(Spacer(1, 2.2 * cm))
    meta = Table(
        [
            ["Versión de la app", "1.0.0+9"],
            ["Plataformas", "iOS · Android · Web"],
            ["Documento", f"Generado el {date.today().strftime('%d/%m/%Y')}"],
            ["Estado", "En revisión para App Store y Google Play"],
        ],
        colWidths=[5.5 * cm, 9 * cm],
    )
    meta.setStyle(TableStyle([
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
        ("FONTNAME", (1, 0), (1, -1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), 10),
        ("TEXTCOLOR", (0, 0), (0, -1), hc(C_BLUE)),
        ("TEXTCOLOR", (1, 0), (1, -1), hc(C_SLATE)),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LINEBELOW", (0, 0), (-1, -2), 0.4, hc(C_LIGHT)),
    ]))
    story.append(meta)
    story.append(PageBreak())

    # ---------- ÍNDICE ----------
    story.append(Paragraph("Índice", S["H1"]))
    story.append(accent_rule())
    story.append(Spacer(1, 0.4 * cm))
    toc = [
        ("1.", "Visión general del producto"),
        ("2.", "Arquitectura técnica"),
        ("3.", "Onboarding y autenticación"),
        ("4.", "Descubrimiento: el swipe"),
        ("5.", "Algoritmo de compatibilidad"),
        ("6.", "Matches y chat en tiempo real"),
        ("7.", "Búsqueda de vivienda"),
        ("8.", "Perfil de usuario y verificación"),
        ("9.", "Premium y modelo de negocio"),
        ("10.", "Privacidad, ajustes y RGPD"),
        ("11.", "Backend: módulos del sistema"),
        ("12.", "Seguridad"),
        ("13.", "Calidad, pruebas y despliegue"),
        ("14.", "Estado del proyecto y roadmap"),
    ]
    for num, name in toc:
        story.append(Paragraph(
            f'<font color="{C_BLUE}"><b>{num}</b></font>&nbsp;&nbsp;{name}',
            S["TOCItem"]))
    story.append(PageBreak())

    # ---------- 1. VISIÓN ----------
    story.append(Paragraph("1. Visión general del producto", S["H1"]))
    story.append(accent_rule())
    story.append(Spacer(1, 0.3 * cm))
    story.append(Paragraph(
        "RoomMate Match es una aplicación móvil multiplataforma (iOS, Android y web) "
        "concebida como un <b>«Tinder para compañeros de piso»</b>. A diferencia de los "
        "portales tradicionales de alquiler, que se centran en el inmueble, RoomMate Match "
        "pone el foco en la <b>compatibilidad humana</b>: primero encuentras a la persona "
        "adecuada para convivir y después buscáis juntos la vivienda.",
        S["Body"]))
    story.append(Paragraph("El problema que resuelve", S["H2"]))
    story.append(Paragraph(
        "Compartir piso es la forma de vivienda más habitual entre estudiantes y jóvenes "
        "profesionales, pero la búsqueda de compañero se sigue haciendo mediante anuncios "
        "impersonales, grupos de mensajería o el boca a boca. El resultado son convivencias "
        "conflictivas, rotaciones constantes de inquilinos y una experiencia estresante "
        "para todas las partes.",
        S["Body"]))
    story.append(Paragraph("La solución", S["H2"]))
    story += bullets([
        "<b>Matching por afinidad</b> — un algoritmo puntúa la compatibilidad entre personas a partir de sus hábitos de convivencia.",
        "<b>Decisión rápida y visual</b> — interfaz de tarjetas (swipe) para valorar perfiles en segundos.",
        "<b>Confianza</b> — verificación de identidad en varios niveles y herramientas de reporte y bloqueo.",
        "<b>Del match a la vivienda</b> — chat en tiempo real y búsqueda integrada de pisos en portales inmobiliarios.",
        "<b>Seguridad y legalidad</b> — cumplimiento RGPD, moderación de contenido y límites anti-spam.",
    ])
    story.append(Paragraph("Propuesta de valor", S["H2"]))
    story.append(Paragraph(
        "Reducir el riesgo de una mala convivencia antes de firmar un alquiler. La app "
        "monetiza mediante un modelo <b>freemium</b>: la experiencia completa es gratuita "
        "con límites diarios, y una suscripción premium elimina esos límites y añade "
        "funciones avanzadas.",
        S["Body"]))
    story.append(PageBreak())

    # ---------- 2. ARQUITECTURA ----------
    story.append(Paragraph("2. Arquitectura técnica", S["H1"]))
    story.append(accent_rule())
    story.append(Spacer(1, 0.3 * cm))
    story.append(Image(str(arch_path), width=16.6 * cm, height=10.8 * cm))
    story.append(Paragraph("Vista de alto nivel del sistema", S["Caption"]))
    story.append(Paragraph(
        "El sistema sigue una arquitectura de <b>tres capas</b>. La app Flutter se "
        "comunica con el backend NestJS mediante API REST (acciones puntuales) y "
        "WebSockets con Socket.io (chat y eventos en tiempo real). Los datos de negocio "
        "viven en PostgreSQL; los contenidos sociales y archivos, en Firebase.",
        S["Body"]))
    story.append(data_table(
        ["Capa", "Tecnologías", "Responsabilidad"],
        [
            ["Cliente", "Flutter 3.x, Provider, Material 3, socket_io_client, in_app_purchase",
             "UI, estado local, notificaciones, pagos IAP"],
            ["Backend", "NestJS 10, TypeScript, Socket.io, Firebase Admin, class-validator, TypeORM",
             "Lógica de negocio, matching, chat, moderación, pagos"],
            ["Datos", "PostgreSQL 15 (TypeORM), Cloud Firestore, Firebase Storage",
             "Entidades relacionales, datos sociales, fotos y documentos"],
            ["Infra", "Render (API), Firebase (auth/push/storage), Stripe (web), App Store / Play (IAP)",
             "Despliegue, identidad, mensajería push y monetización"],
        ],
        [2.6 * cm, 7.6 * cm, 6.4 * cm],
    ))
    story.append(PageBreak())

    # ---------- 3. ONBOARDING ----------
    story += section_with_shot(
        3, "Onboarding y autenticación",
        [REAL_SHOTS["welcome"], REAL_SHOTS["login"]],
        [
            Paragraph(
                "El primer contacto con la app es un onboarding breve que explica la "
                "propuesta de valor antes de pedir el registro. El acceso puede hacerse "
                "con <b>correo y contraseña</b>, <b>Google</b> o <b>Sign in with Apple</b> "
                "(obligatorio en iOS).",
                S["Body"]),
            Paragraph("Flujo de alta", S["H2"]),
            *bullets([
                "Registro con validación en tiempo real: email (formato, dominios desechables, detección de erratas como <i>gmial.com</i>) y contraseña con medidor de fortaleza.",
                "Verificación de correo obligatoria para cuentas de email antes de entrar a la app.",
                "Consentimiento legal versionado: al aceptar los términos se guarda la versión; si cambia, la app exige re-consentimiento al entrar.",
                "Política de edad: la app está pensada para mayores de edad (rating 17+/18+ en las tiendas).",
            ]),
            Paragraph("Sesión y seguridad de acceso", S["H2"]),
            *bullets([
                "Firebase Auth gestiona la sesión; el backend valida el <b>ID token de Firebase</b> en cada petición.",
                "Firebase App Check protege la API contra clientes falsificados (Play Integrity / App Attest).",
                "Rate limiting local de intentos de login y OTP, con bloqueo temporal.",
                "Borrado de cuenta completo desde ajustes: elimina datos del backend, fotos de Storage, documentos de Firestore y la cuenta de Auth, con re-autenticación cuando es necesaria.",
            ]),
        ],
        "Capturas reales: bienvenida e inicio de sesión",
    )

    # ---------- 4. SWIPE ----------
    story += section_with_shot(
        4, "Descubrimiento: el swipe", mockups["swipe"],
        [
            Paragraph(
                "El corazón de la app es la pantalla de descubrimiento: una pila de "
                "tarjetas con foto, nombre, edad, ciudad y porcentaje de compatibilidad. "
                "El usuario decide con gestos o botones.",
                S["Body"]),
            Paragraph("Interacciones", S["H2"]),
            *bullets([
                "<b>Like</b> — si la otra persona también da like, se produce un match y se abre el chat.",
                "<b>Pass</b> — descarta el perfil.",
                "<b>Super like</b> — destaca el interés; 1 al día en plan gratuito.",
                "<b>Deshacer</b> — revierte el último swipe (premium); si había match, se eliminan match y chat.",
                "<b>Boost</b> — aumenta la visibilidad del perfil durante 30 minutos (premium).",
            ]),
            Paragraph("Límites diarios", S["H2"]),
            Paragraph(
                "Los límites se aplican <b>en el servidor</b> para evitar trampas: "
                "10 likes y 1 super like al día en el plan gratuito; uso ilimitado "
                "para usuarios premium. El estado se sincroniza al cargar la pantalla "
                "para no penalizar la experiencia con lecturas extra.",
                S["Body"]),
            Paragraph("Detalles de experiencia", S["H2"]),
            *bullets([
                "Precarga de fotos de los siguientes perfiles para swipes fluidos.",
                "Respuesta háptica en cada acción y overlay animado al producirse un match.",
                "Feedback inmediato con SnackBars ante errores de red.",
            ]),
        ],
        "Representación visual de la pila de tarjetas",
    )

    # ---------- 5. COMPATIBILIDAD ----------
    story += section_with_shot(
        5, "Algoritmo de compatibilidad", mockups["compatibility"],
        [
            Paragraph(
                "Cada tarjeta muestra un <b>porcentaje de compatibilidad</b> calculado "
                "por el backend a partir del cuestionario de convivencia que completa "
                "el usuario en su perfil.",
                S["Body"]),
            Paragraph("Factores evaluados", S["H2"]),
            *bullets([
                "Horarios (diurno / nocturno / mixto)",
                "Nivel de limpieza y orden",
                "Tabaco (fumador, tolerante, no)",
                "Mascotas (tiene, le gustan, alergias)",
                "Personalidad (introvertido / extrovertido)",
                "Frecuencia de visitas y fiestas en casa",
                "Hábitos de cocina y espacios compartidos",
                "Tolerancia al ruido",
                "Teletrabajo y uso del espacio",
            ]),
            Paragraph("Cómo se usa", S["H2"]),
            Paragraph(
                "El score orienta el orden de la pila de tarjetas y se desglosa en la "
                "vista de detalle del perfil, donde cada factor muestra su nivel de "
                "coincidencia. Esto convierte una decisión emocional en una decisión "
                "informada sin perder rapidez.",
                S["Body"]),
            Paragraph(
                "Además de personas, el mismo enfoque permite calcular la "
                "<b>compatibilidad grupal</b>: cuando varios matches forman un grupo "
                "para buscar piso juntos, el sistema promedia las afinidades entre "
                "todos sus miembros.",
                S["Body"]),
        ],
        "Representación visual del desglose de compatibilidad",
    )

    # ---------- 6. MATCHES Y CHAT ----------
    story += section_with_shot(
        6, "Matches y chat en tiempo real", mockups["chat"],
        [
            Paragraph(
                "Cuando dos usuarios se dan like mutuamente se crea un <b>match</b> y "
                "ambos pueden empezar a conversar. La bandeja de matches muestra las "
                "conversaciones ordenadas por actividad reciente.",
                S["Body"]),
            Paragraph("Mensajería", S["H2"]),
            *bullets([
                "Entrega instantánea mediante <b>Socket.io</b>: los mensajes llegan sin recargar la pantalla.",
                "Historial persistente de conversaciones.",
                "Indicadores de estado (enviado / recibido) y presencia en línea.",
                "Soporte para compartir fotos dentro de la conversación.",
            ]),
            Paragraph("Seguridad en el chat", S["H2"]),
            *bullets([
                "La conexión WebSocket exige un <b>token de Firebase válido</b>: nadie puede suplantar a otro usuario ni leer chats ajenos.",
                "Límite de mensajes por minuto para frenar el spam.",
                "Desde cualquier conversación se puede <b>reportar o bloquear</b> al otro usuario; los reportes alimentan la cola de moderación.",
            ]),
            Paragraph("Notificaciones", S["H2"]),
            Paragraph(
                "Los matches y mensajes nuevos generan notificaciones push mediante "
                "Firebase Cloud Messaging, con recordatorios de re-enganche "
                "programados localmente.",
                S["Body"]),
        ],
        "Representación visual del chat entre matches",
    )

    # ---------- 7. VIVIENDA ----------
    story += section_with_shot(
        7, "Búsqueda de vivienda", mockups["apartment"],
        [
            Paragraph(
                "Una vez encontrado el compañero ideal, la app acompaña en el siguiente "
                "paso: encontrar la casa. El módulo de vivienda permite explorar "
                "anuncios reales de portales inmobiliarios sin salir de la aplicación.",
                S["Body"]),
            Paragraph("Funciones", S["H2"]),
            *bullets([
                "Búsqueda por ciudad, zona y rango de presupuesto, con filtro por solapamiento de rangos entre buscador y anuncio.",
                "Fichas de piso con fotos, precio, habitaciones y características.",
                "<b>Favoritos compartidos</b>: los miembros de un grupo pueden marcar y comentar pisos candidatos.",
                "Enlaces directos al anuncio original en el portal (Idealista, Fotocasa, etc.).",
            ]),
            Paragraph("Valor diferencial", S["H2"]),
            Paragraph(
                "La mayoría de apps de roommates se quedan en el match; RoomMate Match "
                "cierra el ciclo completo <b>persona → grupo → vivienda</b>, lo que "
                "también abre una vía de monetización por referidos inmobiliarios.",
                S["Body"]),
        ],
        "Representación visual del explorador de vivienda",
    )

    # ---------- 8. PERFIL ----------
    story += section_with_shot(
        8, "Perfil de usuario y verificación", REAL_SHOTS["profile"],
        [
            Paragraph(
                "El perfil es la carta de presentación: fotos, descripción, hábitos de "
                "convivencia y preferencias de búsqueda. Un perfil completo y "
                "verificado obtiene más visibilidad y mejores matches.",
                S["Body"]),
            Paragraph("Contenido del perfil", S["H2"]),
            *bullets([
                "Galería de fotos subidas a Firebase Storage con precarga en caché.",
                "Bio y datos básicos: edad, ocupación, ciudad.",
                "Cuestionario de hábitos que alimenta el algoritmo de compatibilidad.",
                "Presupuesto, zona preferida y tipo de vivienda buscada.",
            ]),
            Paragraph("Sistema de verificación", S["H2"]),
            *bullets([
                "<b>Nivel 1 — Email</b>: verificación del correo de registro.",
                "<b>Nivel 2 — Teléfono</b>: código OTP por SMS.",
                "<b>Nivel 3 — Selfie</b>: comparación con la foto de perfil (revisión).",
                "<b>Nivel 4 — Documento</b>: verificación de identidad opcional; solo se aceptan documentos alojados en Firebase Storage por HTTPS.",
            ]),
            Paragraph(
                "Los niveles se muestran como insignias en el perfil y aumentan la "
                "confianza del resto de usuarios, además de desbloquear funciones "
                "como la visibilidad destacada.",
                S["Body"]),
        ],
        "Captura real de la pantalla de perfil",
    )

    # ---------- 9. PREMIUM ----------
    story += section_with_shot(
        9, "Premium y modelo de negocio", mockups["premium"],
        [
            Paragraph(
                "El modelo es <b>freemium</b>: la app es completamente funcional de "
                "forma gratuita y la suscripción premium elimina los límites y añade "
                "ventajas de visibilidad.",
                S["Body"]),
            Paragraph("Comparativa de planes", S["H2"]),
            data_table(
                ["Función", "Gratis", "Premium"],
                [
                    ["Likes diarios", "10", "Ilimitados"],
                    ["Super likes", "1 / día", "Ilimitados"],
                    ["Ver quién te dio like", "No", "Sí"],
                    ["Deshacer swipe", "No", "Sí"],
                    ["Filtros avanzados", "Básicos", "Completos"],
                    ["Boost de perfil", "No", "Sí"],
                    ["Modo invisible", "No", "Sí"],
                    ["Anuncios", "Sí", "Sin anuncios"],
                ],
                [5.0 * cm, 2.3 * cm, 2.7 * cm],
            ),
            Paragraph("Compras dentro de la app", S["H2"]),
            *bullets([
                "Suscripciones <b>mensual y anual</b>, más consumibles: boost, super like y destacado de anuncio.",
                "En iOS/Android se usan <b>In-App Purchases nativas</b>; Stripe solo se usa en la versión web.",
                "Las compras se verifican <b>en el servidor</b> (Apple / Google Play) antes de conceder el plan.",
                "Restauración de compras disponible desde la propia pantalla premium.",
            ]),
        ],
        "Representación visual del paywall premium",
    )

    # ---------- 10. PRIVACIDAD ----------
    story += section_with_shot(
        10, "Privacidad, ajustes y RGPD", REAL_SHOTS["help"],
        [
            Paragraph(
                "La app incluye un centro de privacidad completo, alineado con el "
                "RGPD europeo y los requisitos de App Store y Google Play.",
                S["Body"]),
            Paragraph("Derechos del usuario", S["H2"]),
            *bullets([
                "<b>Acceso</b>: solicitud de copia de sus datos por correo.",
                "<b>Rectificación</b>: corrección de datos incorrectos.",
                "<b>Portabilidad</b>: exportación de la información.",
                "<b>Supresión</b>: borrado completo de la cuenta (backend, fotos, Firestore y Auth).",
                "<b>Retirada de consentimiento</b>: gestión granular de consentimientos.",
            ]),
            Paragraph("Control y seguridad", S["H2"]),
            *bullets([
                "Bloqueo de usuarios y reportes con categorías que llegan a la cola de moderación.",
                "Documentos legales accesibles desde la app: términos, privacidad y cookies.",
                "Pantalla de ajustes con gestión de notificaciones, invitaciones con enlace de referido y buzón de sugerencias.",
                "Los datos sensibles viajan solo por HTTPS/WSS y las fotos y documentos de verificación se sirven con URL firmadas.",
            ]),
        ],
        "Captura real: centro de ayuda y soporte",
    )

    # ---------- 11. BACKEND ----------
    story.append(Paragraph("11. Backend: módulos del sistema", S["H1"]))
    story.append(accent_rule())
    story.append(Spacer(1, 0.3 * cm))
    story.append(Paragraph(
        "El backend NestJS está organizado en módulos por dominio. Cada uno expone "
        "controladores REST (o gateways WebSocket) y servicios con la lógica de "
        "negocio sobre entidades TypeORM en PostgreSQL.",
        S["Body"]))
    story.append(data_table(
        ["Módulo", "Responsabilidad"],
        [
            ["auth", "Estrategia Firebase (ID token), guards de autenticación y roles, middleware App Check"],
            ["users", "CRUD de usuario, borrado de cuenta, recompensas de referidos"],
            ["profiles", "Perfil detallado, fotos, cuestionario de hábitos"],
            ["compatibility", "Cálculo del score de compatibilidad por factores"],
            ["matches", "Registro de swipes, detección de match mutuo, deshacer"],
            ["chat", "Gateway Socket.io: salas por match, mensajes en tiempo real, auth por token"],
            ["groups", "Grupos de convivencia y compatibilidad grupal"],
            ["filters", "Preferencias de búsqueda: edad, ciudad, presupuesto, hábitos"],
            ["daily-limits", "Cuotas diarias de likes, super likes y boosts, aplicadas en servidor"],
            ["premium", "Suscripciones, estado del plan, consumo de cuotas premium"],
            ["payments", "Stripe (solo web): PaymentIntent, webhooks, historial de transacciones"],
            ["verification", "Verificación por email, teléfono, selfie y documento"],
            ["moderation", "Reportes, bloqueos y cola de revisión de contenido"],
            ["notifications", "Push (FCM), email transaccional y tipos permitidos"],
            ["mail", "Envío de correos transaccionales y plantillas"],
            ["admin", "Panel administrativo: métricas, gestión de reportes y usuarios"],
        ],
        [3.6 * cm, 13.0 * cm],
    ))
    story.append(Spacer(1, 0.4 * cm))
    story.append(Paragraph(
        "Todos los endpoints están protegidos por el guard de Firebase, un pipe global "
        "de validación (whitelist + rechazo de campos extra) y un filtro global de "
        "excepciones que devuelve siempre JSON consistente y registra los errores 5xx "
        "con su traza. El endpoint <b>/health</b> comprueba la base de datos para los "
        "chequeos de Render.",
        S["Body"]))
    story.append(PageBreak())

    # ---------- 12. SEGURIDAD ----------
    story.append(Paragraph("12. Seguridad", S["H1"]))
    story.append(accent_rule())
    story.append(Spacer(1, 0.3 * cm))
    story.append(data_table(
        ["Capa", "Medidas implementadas"],
        [
            ["Identidad", "Firebase Auth; el backend valida el ID token en cada petición. Sin token válido no hay acceso a API ni WebSockets."],
            ["Integridad del cliente", "Firebase App Check (Play Integrity / App Attest) para rechazar clientes falsificados."],
            ["API", "CORS restringido a orígenes configurados, Helmet, compresión, ValidationPipe con whitelist y límite de peticiones (throttler)."],
            ["Datos", "Reglas de seguridad de Firestore, Row-Level Security en PostgreSQL, listas blancas de tipos de notificación."],
            ["Pagos", "IAP verificado en servidor con recibos de Apple y Google; Stripe con webhooks firmados; endpoints de depuración solo fuera de producción."],
            ["Contenido", "Validación de URLs de documentos (solo Firebase Storage por HTTPS), sanitización de entradas en el cliente, límites anti-spam."],
            ["Privacidad", "Consentimientos versionados, borrado de cuenta en cascada, minimización de datos en logs."],
        ],
        [3.4 * cm, 13.2 * cm],
    ))
    story.append(Spacer(1, 0.4 * cm))
    story.append(Paragraph(
        "La superficie administrativa (seeding de demo, endpoints de debug, acciones "
        "de moderación) está bloqueada por defecto en producción mediante variables "
        "de entorno, y las acciones administrativas quedan limitadas en su alcance.",
        S["Body"]))
    story.append(PageBreak())

    # ---------- 13. CALIDAD ----------
    story.append(Paragraph("13. Calidad, pruebas y despliegue", S["H1"]))
    story.append(accent_rule())
    story.append(Spacer(1, 0.3 * cm))
    story.append(Paragraph(
        "El proyecto dispone de una red de seguridad que evita regresiones: ningún "
        "cambio puede romper funcionalidad existente sin que falle el pipeline.",
        S["Body"]))
    story.append(Paragraph("Pruebas automatizadas", S["H2"]))
    story += bullets([
        "<b>Backend</b>: 20 tests unitarios con Jest sobre los servicios críticos (límites diarios, premium, verificación de suscripciones).",
        "<b>Móvil</b>: 44 tests unitarios y de widgets con flutter_test (validadores, sanitización, modelo de suscripción, pantallas de acceso).",
        "<b>Análisis estático</b>: flutter analyze sin warnings y ESLint + Prettier en el backend con reglas anti-crash.",
    ])
    story.append(Paragraph("Integración y despliegue continuo", S["H2"]))
    story += bullets([
        "<b>GitHub Actions</b>: en cada push se ejecutan lint + build + tests del backend y analyze + tests del móvil.",
        "<b>Codemagic</b>: los tres workflows (iOS simulador, TestFlight y Play Store) ejecutan analyze + tests antes de compilar; un fallo bloquea el build.",
        "<b>Render</b>: despliegue del backend con health check en /health y graceful shutdown.",
    ])
    story.append(Paragraph("Observabilidad", S["H2"]))
    story += bullets([
        "<b>Firebase Crashlytics</b>: captura errores fatales de Flutter y excepciones async no controladas en producción.",
        "<b>Logs de servidor</b>: los errores 5xx se registran con traza completa; el cliente solo recibe un mensaje genérico.",
        "<b>Degradación elegante</b>: la inicialización de la app tolera timeouts y servicios caídos sin bloquear el arranque; en release, cualquier error de build muestra una pantalla de diagnóstico en lugar de pantalla en blanco.",
    ])
    story.append(PageBreak())

    # ---------- 14. ESTADO Y ROADMAP ----------
    story.append(Paragraph("14. Estado del proyecto y roadmap", S["H1"]))
    story.append(accent_rule())
    story.append(Spacer(1, 0.3 * cm))
    story.append(Paragraph("Situación actual", S["H2"]))
    story += bullets([
        "App funcional en iOS, Android y web; backend en producción en Render.",
        "Presentada a App Store: en revisión, con vídeo de demostración, cuenta demo y notas de revisión preparadas.",
        "Productos IAP configurados: premium mensual y anual, boost, super like y destacado de anuncio.",
        "Suite de pruebas y CI activos para proteger la estabilidad en cada cambio.",
    ])
    story.append(Paragraph("Próximos pasos", S["H2"]))
    story += bullets([
        "Completar la revisión de App Store y publicar en Google Play.",
        "Ampliar cobertura de tests a módulos de chat, matches y pagos.",
        "Activar strictNullChecks en el backend como siguiente paso de endurecimiento.",
        "Monitor de uptime externo sobre /health y alertas.",
        "Explorar monetización por referidos inmobiliarios.",
    ])
    story.append(Spacer(1, 0.6 * cm))
    story.append(Paragraph(
        '<i>Documento generado automáticamente a partir del estado real del proyecto. '
        'Para uso interno del equipo y material de presentación.</i>',
        S["Caption"]))

    doc.build(story)
    print(f"PDF generado: {OUTPUT_PDF}")


if __name__ == "__main__":
    build_pdf()
