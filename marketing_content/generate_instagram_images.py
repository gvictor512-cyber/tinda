#!/usr/bin/env python3
"""
Generador de imágenes para Instagram - RoomMate Match
Crea imágenes variadas con diferentes temáticas y estilos
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_promotional_image():
    """Crea imagen promocional principal"""
    width, height = 1080, 1080
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Gradiente de fondo
    for y in range(height):
        ratio = y / height
        r = int(74 + (80 - 74) * ratio)
        g = int(144 + (227 - 144) * ratio)
        b = int(226 + (194 - 226) * ratio)
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))
    
    try:
        title_font = ImageFont.truetype("arial.ttf", 70)
        subtitle_font = ImageFont.truetype("arial.ttf", 45)
        cta_font = ImageFont.truetype("arial.ttf", 35)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
        cta_font = ImageFont.load_default()
    
    # Título principal
    title = "RoomMate Match"
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    draw.text((title_x, 250), title, fill=(255, 255, 255), font=title_font)
    
    # Subtítulo
    subtitle = "Encuentra tu compañero ideal"
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    subtitle_x = (width - subtitle_width) // 2
    draw.text((subtitle_x, 380), subtitle, fill=(255, 255, 255, 220), font=subtitle_font)
    
    # Icono de casa simplificado
    draw.polygon([540, 480, 340, 630, 740, 630], fill=(255, 255, 255, 180))
    draw.rectangle([390, 630, 690, 850], fill=(255, 255, 255, 180))
    
    # CTA
    cta = "Descarga gratis - Link en bio"
    cta_bbox = draw.textbbox((0, 0), cta, font=cta_font)
    cta_width = cta_bbox[2] - cta_bbox[0]
    cta_x = (width - cta_width) // 2
    draw.text((cta_x, 750), cta, fill=(255, 255, 255), font=cta_font)
    
    return img

def create_tip_image(tip_number, tip_title, tip_content):
    """Crea imagen de tip"""
    width, height = 1080, 1080
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Gradiente verde
    for y in range(height):
        ratio = y / height
        r = int(80 + (74 - 80) * ratio)
        g = int(227 + (144 - 227) * ratio)
        b = int(194 + (226 - 194) * ratio)
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))
    
    try:
        number_font = ImageFont.truetype("arial.ttf", 120)
        title_font = ImageFont.truetype("arial.ttf", 50)
        content_font = ImageFont.truetype("arial.ttf", 35)
    except:
        number_font = ImageFont.load_default()
        title_font = ImageFont.load_default()
        content_font = ImageFont.load_default()
    
    # Número grande
    draw.text((80, 100), f"#{tip_number}", fill=(255, 255, 255, 60), font=number_font)
    
    # Título
    title_bbox = draw.textbbox((0, 0), tip_title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    draw.text((title_x, 300), tip_title, fill=(255, 255, 255), font=title_font)
    
    # Contenido
    lines = tip_content.split('\n')
    y_offset = 450
    for line in lines:
        line_bbox = draw.textbbox((0, 0), line, font=content_font)
        line_width = line_bbox[2] - line_bbox[0]
        line_x = (width - line_width) // 2
        draw.text((line_x, y_offset), line, fill=(255, 255, 255, 220), font=content_font)
        y_offset += 60
    
    # Icono de bombilla
    draw.ellipse([width-200, height-200, width-50, height-50], fill=(255, 255, 255, 100))
    
    return img

def create_feature_image(feature_title, feature_description):
    """Crea imagen de feature"""
    width, height = 1080, 1080
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Gradiente púrpura
    for y in range(height):
        ratio = y / height
        r = int(155 + (74 - 155) * ratio)
        g = int(89 + (144 - 89) * ratio)
        b = int(182 + (226 - 182) * ratio)
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))
    
    try:
        title_font = ImageFont.truetype("arial.ttf", 55)
        desc_font = ImageFont.truetype("arial.ttf", 35)
    except:
        title_font = ImageFont.load_default()
        desc_font = ImageFont.load_default()
    
    # Icono de feature
    draw.rectangle([440, 150, 640, 350], fill=(255, 255, 255, 150))
    draw.text((510, 220), "🚀", fill=(255, 255, 255), font=title_font)
    
    # Título
    title_bbox = draw.textbbox((0, 0), feature_title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    draw.text((title_x, 400), feature_title, fill=(255, 255, 255), font=title_font)
    
    # Descripción
    lines = feature_description.split('\n')
    y_offset = 500
    for line in lines:
        line_bbox = draw.textbbox((0, 0), line, font=desc_font)
        line_width = line_bbox[2] - line_bbox[0]
        line_x = (width - line_width) // 2
        draw.text((line_x, y_offset), line, fill=(255, 255, 255, 220), font=desc_font)
        y_offset += 60
    
    return img

def create_testimonial_image(user_name, testimonial):
    """Crea imagen de testimonio"""
    width, height = 1080, 1080
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Fondo sólido
    draw.rectangle([(0, 0), (width, height)], fill=(74, 144, 226))
    
    try:
        quote_font = ImageFont.truetype("arial.ttf", 40)
        name_font = ImageFont.truetype("arial.ttf", 35)
    except:
        quote_font = ImageFont.load_default()
        name_font = ImageFont.load_default()
    
    # Comillas
    draw.text((100, 200), '"', fill=(255, 255, 255, 100), font=ImageFont.truetype("arial.ttf", 150) if os.name != 'nt' else ImageFont.load_default())
    
    # Testimonio
    lines = testimonial.split('\n')
    y_offset = 350
    for line in lines:
        line_bbox = draw.textbbox((0, 0), line, font=quote_font)
        line_width = line_bbox[2] - line_bbox[0]
        line_x = (width - line_width) // 2
        draw.text((line_x, y_offset), line, fill=(255, 255, 255), font=quote_font)
        y_offset += 70
    
    # Nombre
    name_bbox = draw.textbbox((0, 0), f"- {user_name}", font=name_font)
    name_width = name_bbox[2] - name_bbox[0]
    name_x = (width - name_width) // 2
    draw.text((name_x, y_offset + 50), f"- {user_name}", fill=(255, 255, 255, 180), font=name_font)
    
    # Estrellas
    draw.text((width//2 - 100, height - 200), "⭐⭐⭐⭐⭐", fill=(255, 255, 255), font=name_font)
    
    return img

def create_stat_image(stat_number, stat_label, stat_description):
    """Crea imagen de estadística"""
    width, height = 1080, 1080
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Gradiente oscuro
    for y in range(height):
        ratio = y / height
        r = int(26 + (74 - 26) * ratio)
        g = int(26 + (144 - 26) * ratio)
        b = int(46 + (226 - 46) * ratio)
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))
    
    try:
        number_font = ImageFont.truetype("arial.ttf", 100)
        label_font = ImageFont.truetype("arial.ttf", 45)
        desc_font = ImageFont.truetype("arial.ttf", 30)
    except:
        number_font = ImageFont.load_default()
        label_font = ImageFont.load_default()
        desc_font = ImageFont.load_default()
    
    # Número grande
    number_bbox = draw.textbbox((0, 0), stat_number, font=number_font)
    number_width = number_bbox[2] - number_bbox[0]
    number_x = (width - number_width) // 2
    draw.text((number_x, 250), stat_number, fill=(80, 227, 194), font=number_font)
    
    # Etiqueta
    label_bbox = draw.textbbox((0, 0), stat_label, font=label_font)
    label_width = label_bbox[2] - label_bbox[0]
    label_x = (width - label_width) // 2
    draw.text((label_x, 450), stat_label, fill=(255, 255, 255), font=label_font)
    
    # Descripción
    lines = stat_description.split('\n')
    y_offset = 550
    for line in lines:
        line_bbox = draw.textbbox((0, 0), line, font=desc_font)
        line_width = line_bbox[2] - line_bbox[0]
        line_x = (width - line_width) // 2
        draw.text((line_x, y_offset), line, fill=(255, 255, 255, 180), font=desc_font)
        y_offset += 50
    
    return img

def create_motivational_image(quote, author):
    """Crea imagen motivacional"""
    width, height = 1080, 1080
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Gradiente cálido
    for y in range(height):
        ratio = y / height
        r = int(243 + (74 - 243) * ratio)
        g = int(156 + (144 - 156) * ratio)
        b = int(18 + (226 - 18) * ratio)
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))
    
    try:
        quote_font = ImageFont.truetype("arial.ttf", 45)
        author_font = ImageFont.truetype("arial.ttf", 35)
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

def create_humor_image(situation_text):
    """Crea imagen humorística"""
    width, height = 1080, 1080
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Gradiente divertido
    for y in range(height):
        ratio = y / height
        r = int(255 + (74 - 255) * ratio)
        g = int(107 + (144 - 107) * ratio)
        b = int(107 + (226 - 107) * ratio)
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))
    
    try:
        text_font = ImageFont.truetype("arial.ttf", 50)
        emoji_font = ImageFont.truetype("arial.ttf", 80)
    except:
        text_font = ImageFont.load_default()
        emoji_font = ImageFont.load_default()
    
    # Emoji grande
    draw.text((width//2 - 50, 200), "😅", fill=(255, 255, 255), font=emoji_font)
    
    # Texto
    lines = situation_text.split('\n')
    y_offset = 400
    for line in lines:
        line_bbox = draw.textbbox((0, 0), line, font=text_font)
        line_width = line_bbox[2] - line_bbox[0]
        line_x = (width - line_width) // 2
        draw.text((line_x, y_offset), line, fill=(255, 255, 255), font=text_font)
        y_offset += 70
    
    # Hashtag
    hashtag = "#roommateproblems"
    hashtag_bbox = draw.textbbox((0, 0), hashtag, font=text_font)
    hashtag_width = hashtag_bbox[2] - hashtag_bbox[0]
    hashtag_x = (width - hashtag_width) // 2
    draw.text((hashtag_x, height - 200), hashtag, fill=(255, 255, 255, 150), font=text_font)
    
    return img

def generate_all_images():
    """Genera todas las imágenes"""
    output_dir = 'marketing_content/instagram_images'
    os.makedirs(output_dir, exist_ok=True)
    
    # Imagen promocional
    img = create_promotional_image()
    img.save(f'{output_dir}/promotional_main.png')
    print(f"Created: promotional_main.png")
    
    # Tips
    tips = [
        (1, "Sé Específico", "Define claramente tus\npreferencias desde el inicio"),
        (2, "Verifica Siempre", "Confirma la identidad de\npotenciales compañeros"),
        (3, "Establece Reglas", "Las reglas claras hacen\nmejor la convivencia"),
        (4, "Comunícate", "Habla abiertamente sobre\nexpectativas y límites"),
        (5, "Sé Flexible", "La adaptación es clave\npara una buena convivencia")
    ]
    
    for num, title, content in tips:
        img = create_tip_image(num, title, content)
        img.save(f'{output_dir}/tip_{num}.png')
        print(f"Created: tip_{num}.png")
    
    # Features
    features = [
        ("Algoritmo Inteligente", "Compatibilidad basada en\nIA y preferencias reales"),
        ("Chat Seguro", "Mensajes encriptados de\nextremo a extremo"),
        ("Verificación", "Identidad verificada\npara mayor seguridad")
    ]
    
    for i, (title, desc) in enumerate(features, 1):
        img = create_feature_image(title, desc)
        img.save(f'{output_dir}/feature_{i}.png')
        print(f"Created: feature_{i}.png")
    
    # Testimonios
    testimonials = [
        ("María, 24 años", "Encontré a mi compañero ideal\nen 2 semanas con RoomMate Match"),
        ("Juan, 27 años", "Llevaba 4 meses buscando,\nlo encontré en 10 días"),
        ("Carla, 22 años", "95% de compatibilidad con\nmi nueva compañera")
    ]
    
    for i, (name, text) in enumerate(testimonials, 1):
        img = create_testimonial_image(name, text)
        img.save(f'{output_dir}/testimonial_{i}.png')
        print(f"Created: testimonial_{i}.png")
    
    # Estadísticas
    stats = [
        ("1,500+", "Usuarios Activos", "Personas usando RoomMate Match\npara encontrar compañeros"),
        ("800+", "Matches Realizados", "Conexiones exitosas entre\ncompatibles"),
        ("95%", "Satisfacción", "Usuarios satisfechos con sus\ncompanjeros encontrados")
    ]
    
    for i, (number, label, desc) in enumerate(stats, 1):
        img = create_stat_image(number, label, desc)
        img.save(f'{output_dir}/stat_{i}.png')
        print(f"Created: stat_{i}.png")
    
    # Motivacionales
    quotes = [
        ("Un buen compañero de piso\nvale más que un piso de lujo", "RoomMate Match"),
        ("La convivencia es un arte\nque se practica día a día", "Sabiduría"),
        ("Mejor acompañado que solo,\nmejor solo que mal acompañado", "Dicho Popular")
    ]
    
    for i, (quote, author) in enumerate(quotes, 1):
        img = create_motivational_image(quote, author)
        img.save(f'{output_dir}/motivational_{i}.png')
        print(f"Created: motivational_{i}.png")
    
    # Humor
    humor_situations = [
        "Cuando tu compañero usa\ntu shampoo sin pedir",
        "Cuando tu compañero llega\na las 3am con música",
        "Cuando tu compañero no lava\nlos platos por tercera vez"
    ]
    
    for i, situation in enumerate(humor_situations, 1):
        img = create_humor_image(situation)
        img.save(f'{output_dir}/humor_{i}.png')
        print(f"Created: humor_{i}.png")
    
    print(f"\nAll images generated in {output_dir}")
    print(f"Total images: 1 + 5 tips + 3 features + 3 testimonials + 3 stats + 3 motivational + 3 humor = 21 images")

if __name__ == '__main__':
    generate_all_images()
