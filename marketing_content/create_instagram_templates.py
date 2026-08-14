#!/usr/bin/env python3
"""
Script para crear templates de posts para Instagram
Genera imágenes con texto para carruseles y posts individuales
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_template(width, height, title, subtitle, color_scheme):
    """Crea un template básico para Instagram"""
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Gradiente de fondo
    for y in range(height):
        ratio = y / height
        r = int(color_scheme['r1'] + (color_scheme['r2'] - color_scheme['r1']) * ratio)
        g = int(color_scheme['g1'] + (color_scheme['g2'] - color_scheme['g1']) * ratio)
        b = int(color_scheme['b1'] + (color_scheme['b2'] - color_scheme['b1']) * ratio)
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))
    
    # Añadir overlay
    overlay = Image.new('RGBA', (width, height), (255, 255, 255, 30))
    img.paste(overlay, (0, 0), overlay)
    
    # Intentar cargar fuente
    try:
        title_font = ImageFont.truetype("arial.ttf", 60)
        subtitle_font = ImageFont.truetype("arial.ttf", 40)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
    
    # Añadir título
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    title_y = height // 3
    draw.text((title_x, title_y), title, fill=(255, 255, 255), font=title_font)
    
    # Añadir subtítulo
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    subtitle_x = (width - subtitle_width) // 2
    subtitle_y = title_y + 100
    draw.text((subtitle_x, subtitle_y), subtitle, fill=(255, 255, 255, 200), font=subtitle_font)
    
    return img

def create_carousel_slide(slide_number, total_slides, title, content):
    """Crea una slide para carrusel"""
    width, height = 1080, 1080
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Fondo con gradiente azul
    for y in range(height):
        ratio = y / height
        r = int(74 + (80 - 74) * ratio)
        g = int(144 + (227 - 144) * ratio)
        b = int(226 + (194 - 226) * ratio)
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))
    
    # Número de slide
    try:
        number_font = ImageFont.truetype("arial.ttf", 30)
        title_font = ImageFont.truetype("arial.ttf", 50)
        content_font = ImageFont.truetype("arial.ttf", 35)
    except:
        number_font = ImageFont.load_default()
        title_font = ImageFont.load_default()
        content_font = ImageFont.load_default()
    
    # Número de slide en esquina
    draw.text((50, 50), f"{slide_number}/{total_slides}", fill=(255, 255, 255, 150), font=number_font)
    
    # Título
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    draw.text((title_x, 200), title, fill=(255, 255, 255), font=title_font)
    
    # Contenido (multilinea)
    lines = content.split('\n')
    y_offset = 350
    for line in lines:
        line_bbox = draw.textbbox((0, 0), line, font=content_font)
        line_width = line_bbox[2] - line_bbox[0]
        line_x = (width - line_width) // 2
        draw.text((line_x, y_offset), line, fill=(255, 255, 255, 220), font=content_font)
        y_offset += 60
    
    # Logo placeholder
    draw.ellipse([width-150, height-150, width-50, height-50], fill=(255, 255, 255, 100))
    
    return img

def create_quote_post(quote, author):
    """Crea un post de cita/quote"""
    width, height = 1080, 1080
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Fondo sólido
    draw.rectangle([(0, 0), (width, height)], fill=(74, 144, 226))
    
    try:
        quote_font = ImageFont.truetype("arial.ttf", 45)
        author_font = ImageFont.truetype("arial.ttf", 30)
    except:
        quote_font = ImageFont.load_default()
        author_font = ImageFont.load_default()
    
    # Quote
    lines = quote.split('\n')
    y_offset = 300
    for line in lines:
        line_bbox = draw.textbbox((0, 0), line, font=quote_font)
        line_width = line_bbox[2] - line_bbox[0]
        line_x = (width - line_width) // 2
        draw.text((line_x, y_offset), line, fill=(255, 255, 255), font=quote_font)
        y_offset += 70
    
    # Autor
    author_bbox = draw.textbbox((0, 0), f"- {author}", font=author_font)
    author_width = author_bbox[2] - author_bbox[0]
    author_x = (width - author_width) // 2
    draw.text((author_x, y_offset + 50), f"- {author}", fill=(255, 255, 255, 180), font=author_font)
    
    return img

def create_tip_post(tip_number, tip_title, tip_content):
    """Crea un post de tip"""
    width, height = 1080, 1080
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Gradiente verde-azul
    for y in range(height):
        ratio = y / height
        r = int(80 + (74 - 80) * ratio)
        g = int(227 + (144 - 227) * ratio)
        b = int(194 + (226 - 194) * ratio)
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))
    
    try:
        number_font = ImageFont.truetype("arial.ttf", 80)
        title_font = ImageFont.truetype("arial.ttf", 50)
        content_font = ImageFont.truetype("arial.ttf", 35)
    except:
        number_font = ImageFont.load_default()
        title_font = ImageFont.load_default()
        content_font = ImageFont.load_default()
    
    # Número grande
    draw.text((100, 100), f"#{tip_number}", fill=(255, 255, 255, 100), font=number_font)
    
    # Título
    title_bbox = draw.textbbox((0, 0), tip_title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    draw.text((title_x, 250), tip_title, fill=(255, 255, 255), font=title_font)
    
    # Contenido
    lines = tip_content.split('\n')
    y_offset = 400
    for line in lines:
        line_bbox = draw.textbbox((0, 0), line, font=content_font)
        line_width = line_bbox[2] - line_bbox[0]
        line_x = (width - line_width) // 2
        draw.text((line_x, y_offset), line, fill=(255, 255, 255, 220), font=content_font)
        y_offset += 60
    
    return img

def generate_all_templates():
    """Genera todos los templates"""
    output_dir = 'marketing_content/instagram_templates'
    os.makedirs(output_dir, exist_ok=True)
    
    color_scheme = {
        'r1': 74, 'g1': 144, 'b1': 226,
        'r2': 80, 'g2': 227, 'b2': 194
    }
    
    # Template 1: Anuncio
    img = create_template(1080, 1080, "RoomMate Match", "Encuentra tu compañero ideal", color_scheme)
    img.save(f'{output_dir}/template_announcement.png')
    print(f"Created: template_announcement.png")
    
    # Carrusel: 5 tips para encontrar compañero ideal
    carousel_content = [
        ("Tip #1", "Sé específico con tus\npreferencias de horarios"),
        ("Tip #2", "Sé honesto con tu\npresupuesto desde el principio"),
        ("Tip #3", "Muestra tu personalidad\nen tu perfil"),
        ("Tip #4", "Responde rápidamente\na los matches"),
        ("Tip #5", "Verifica la identidad\nde tus potenciales compañeros")
    ]
    
    for i, (title, content) in enumerate(carousel_content, 1):
        img = create_carousel_slide(i, 5, title, content)
        img.save(f'{output_dir}/carousel_tip_{i}.png')
        print(f"Created: carousel_tip_{i}.png")
    
    # Posts de tips individuales
    tips = [
        (1, "Establece reglas", "Define reglas de limpieza\ny convivencia desde el inicio"),
        (2, "Comunícate", "Habla abiertamente sobre\nexpectativas y límites"),
        (3, "Respeta espacios", "Cada uno necesita su\nespacio personal"),
        (4, "Comparte gastos", "Lleva un registro claro\nde gastos compartidos"),
        (5, "Sé flexible", "La adaptación es clave\npara una buena convivencia")
    ]
    
    for num, title, content in tips:
        img = create_tip_post(num, title, content)
        img.save(f'{output_dir}/tip_{num}.png')
        print(f"Created: tip_{num}.png")
    
    # Quotes
    quotes = [
        ("Un buen compañero de piso\nvale más que un piso de lujo", "RoomMate Match"),
        ("La convivencia es un arte\nque se practica día a día", "Sabiduría compartida"),
        ("Mejor solo que mal acompañado,\npero mejor acompañado que solo", "Dicho popular")
    ]
    
    for i, (quote, author) in enumerate(quotes, 1):
        img = create_quote_post(quote, author)
        img.save(f'{output_dir}/quote_{i}.png')
        print(f"Created: quote_{i}.png")
    
    print(f"\n✅ All templates generated in {output_dir}")

if __name__ == '__main__':
    generate_all_templates()
