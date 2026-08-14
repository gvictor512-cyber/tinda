#!/usr/bin/env python3
"""
Script para crear feature graphic de Google Play (1024x500 px)
Basado en el icono existente de RoomMate Match
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_feature_graphic():
    # Crear imagen con gradiente
    width, height = 1024, 500
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Gradiente de fondo (azul a verde)
    for x in range(width):
        ratio = x / width
        r = int(74 + (80 - 74) * ratio)  # #4A90E2 to #50E3C2
        g = int(144 + (227 - 144) * ratio)
        b = int(226 + (194 - 226) * ratio)
        draw.rectangle([(x, 0), (x+1, height)], fill=(r, g, b))
    
    # Añadir overlay más claro
    overlay = Image.new('RGBA', (width, height), (74, 144, 226, 50))
    img.paste(overlay, (0, 0), overlay)
    
    # Crear icono simplificado basado en el diseño SVG
    icon = Image.new('RGBA', (300, 300), (74, 144, 226, 255))
    draw_icon = ImageDraw.Draw(icon)
    
    # Fondo del icono con gradiente
    for x in range(300):
        ratio = x / 300
        r = int(74 + (80 - 74) * ratio)
        g = int(144 + (227 - 144) * ratio)
        b = int(226 + (194 - 226) * ratio)
        draw_icon.rectangle([(x, 0), (x+1, 300)], fill=(r, g, b))
    
    # Casa simplificada
    draw_icon.polygon([150, 30, 30, 120, 270, 120], fill=(255, 255, 255, 230))
    draw_icon.rectangle([50, 120, 250, 270], fill=(255, 255, 255, 230))
    
    # Puerta
    draw_icon.rectangle([120, 180, 180, 270], fill=(74, 144, 226))
    
    # Ventanas
    draw_icon.rectangle([60, 140, 110, 180], fill=(80, 227, 194, 180))
    draw_icon.rectangle([190, 140, 240, 180], fill=(80, 227, 194, 180))
    
    # Personas simplificadas
    draw_icon.ellipse([100, 220, 130, 250], fill=(255, 255, 255, 200))
    draw_icon.ellipse([170, 220, 200, 250], fill=(255, 255, 255, 200))
    
    # Posicionar icono a la izquierda
    img.paste(icon, (50, 100), icon)
    
    # Añadir texto
    try:
        # Intentar usar una fuente del sistema
        font_large = ImageFont.truetype("arial.ttf", 60)
        font_medium = ImageFont.truetype("arial.ttf", 40)
    except:
        # Fallback a fuente default
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
    
    # Texto principal
    text = "RoomMate Match"
    text_bbox = draw.textbbox((0, 0), text, font=font_large)
    text_width = text_bbox[2] - text_bbox[0]
    text_x = 400 + (width - 400 - text_width) // 2
    draw.text((text_x, 150), text, fill=(255, 255, 255), font=font_large)
    
    # Texto secundario
    tagline = "Encuentra tu compañero de piso ideal"
    tagline_bbox = draw.textbbox((0, 0), tagline, font=font_medium)
    tagline_width = tagline_bbox[2] - tagline_bbox[0]
    tagline_x = 400 + (width - 400 - tagline_width) // 2
    draw.text((tagline_x, 230), tagline, fill=(255, 255, 255, 200), font=font_medium)
    
    # Añadir elementos decorativos
    draw.ellipse([900, 50, 1000, 150], fill=(80, 227, 194, 100))
    draw.ellipse([850, 350, 950, 450], fill=(80, 227, 194, 80))
    
    # Guardar imagen
    output_dir = 'assets/store/google-play'
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, 'feature-graphic-1024x500.png')
    img.save(output_path, 'PNG')
    print(f"Feature graphic creado: {output_path}")
    
    return output_path

if __name__ == '__main__':
    create_feature_graphic()
