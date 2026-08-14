#!/usr/bin/env python3
"""
Script para crear templates de Instagram Stories
Genera imágenes verticales 9:16 para stories
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_poll_story(question, option1, option2):
    """Crea template de poll para story"""
    width, height = 1080, 1920
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
        question_font = ImageFont.truetype("arial.ttf", 50)
        option_font = ImageFont.truetype("arial.ttf", 40)
    except:
        question_font = ImageFont.load_default()
        option_font = ImageFont.load_default()
    
    # Pregunta
    question_bbox = draw.textbbox((0, 0), question, font=question_font)
    question_width = question_bbox[2] - question_bbox[0]
    question_x = (width - question_width) // 2
    draw.text((question_x, 400), question, fill=(255, 255, 255), font=question_font)
    
    # Opción 1
    draw.rectangle([100, 800, 980, 950], fill=(255, 255, 255, 200))
    option1_bbox = draw.textbbox((0, 0), option1, font=option_font)
    option1_width = option1_bbox[2] - option1_bbox[0]
    option1_x = (width - option1_width) // 2
    draw.text((option1_x, 850), option1, fill=(74, 144, 226), font=option_font)
    
    # Opción 2
    draw.rectangle([100, 1000, 980, 1150], fill=(255, 255, 255, 200))
    option2_bbox = draw.textbbox((0, 0), option2, font=option_font)
    option2_width = option2_bbox[2] - option2_bbox[0]
    option2_x = (width - option2_width) // 2
    draw.text((option2_x, 1050), option2, fill=(74, 144, 226), font=option_font)
    
    # Logo placeholder
    draw.ellipse([width-200, height-200, width-50, height-50], fill=(255, 255, 255, 100))
    
    return img

def create_quiz_story(question, answer_a, answer_b, answer_c, answer_d):
    """Crea template de quiz para story"""
    width, height = 1080, 1920
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
        question_font = ImageFont.truetype("arial.ttf", 45)
        answer_font = ImageFont.truetype("arial.ttf", 35)
    except:
        question_font = ImageFont.load_default()
        answer_font = ImageFont.load_default()
    
    # Pregunta
    question_bbox = draw.textbbox((0, 0), question, font=question_font)
    question_width = question_bbox[2] - question_bbox[0]
    question_x = (width - question_width) // 2
    draw.text((question_x, 300), question, fill=(255, 255, 255), font=question_font)
    
    # Respuestas
    answers = [answer_a, answer_b, answer_c, answer_d]
    y_positions = [700, 900, 1100, 1300]
    
    for i, (answer, y_pos) in enumerate(zip(answers, y_positions)):
        draw.rectangle([100, y_pos, 980, y_pos + 120], fill=(255, 255, 255, 200))
        answer_bbox = draw.textbbox((0, 0), f"{chr(65+i)}. {answer}", font=answer_font)
        answer_width = answer_bbox[2] - answer_bbox[0]
        answer_x = (width - answer_width) // 2
        draw.text((answer_x, y_pos + 40), f"{chr(65+i)}. {answer}", fill=(74, 144, 226), font=answer_font)
    
    return img

def create_countdown_story(title, date):
    """Crea template de countdown para story"""
    width, height = 1080, 1920
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Fondo sólido
    draw.rectangle([(0, 0), (width, height)], fill=(155, 89, 182))
    
    try:
        title_font = ImageFont.truetype("arial.ttf", 60)
        date_font = ImageFont.truetype("arial.ttf", 40)
    except:
        title_font = ImageFont.load_default()
        date_font = ImageFont.load_default()
    
    # Título
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    draw.text((title_x, 600), title, fill=(255, 255, 255), font=title_font)
    
    # Fecha
    date_bbox = draw.textbbox((0, 0), date, font=date_font)
    date_width = date_bbox[2] - date_bbox[0]
    date_x = (width - date_width) // 2
    draw.text((date_x, 800), date, fill=(255, 255, 255, 200), font=date_font)
    
    # Círculo decorativo
    draw.ellipse([width//2 - 200, 400, width//2 + 200, 800], outline=(255, 255, 255, 100), width=5)
    
    return img

def create_qa_story(question):
    """Crea template de Q&A para story"""
    width, height = 1080, 1920
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Gradiente
    for y in range(height):
        ratio = y / height
        r = int(74 + (155 - 74) * ratio)
        g = int(144 + (89 - 144) * ratio)
        b = int(226 + (182 - 226) * ratio)
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))
    
    try:
        question_font = ImageFont.truetype("arial.ttf", 45)
    except:
        question_font = ImageFont.load_default()
    
    # Icono de pregunta
    draw.ellipse([width//2 - 100, 400, width//2 + 100, 600], fill=(255, 255, 255, 150))
    
    # Pregunta
    lines = question.split('\n')
    y_offset = 800
    for line in lines:
        line_bbox = draw.textbbox((0, 0), line, font=question_font)
        line_width = line_bbox[2] - line_bbox[0]
        line_x = (width - line_width) // 2
        draw.text((line_x, y_offset), line, fill=(255, 255, 255), font=question_font)
        y_offset += 70
    
    # Sticker placeholder
    draw.rectangle([100, height-300, 300, height-100], fill=(255, 255, 255, 100))
    
    return img

def create_tip_story(tip_number, tip_text):
    """Crea template de tip para story"""
    width, height = 1080, 1920
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Gradiente
    for y in range(height):
        ratio = y / height
        r = int(80 + (74 - 80) * ratio)
        g = int(227 + (144 - 227) * ratio)
        b = int(194 + (226 - 194) * ratio)
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))
    
    try:
        number_font = ImageFont.truetype("arial.ttf", 120)
        tip_font = ImageFont.truetype("arial.ttf", 45)
    except:
        number_font = ImageFont.load_default()
        tip_font = ImageFont.load_default()
    
    # Número grande
    draw.text((100, 200), f"#{tip_number}", fill=(255, 255, 255, 80), font=number_font)
    
    # Tip
    lines = tip_text.split('\n')
    y_offset = 600
    for line in lines:
        line_bbox = draw.textbbox((0, 0), line, font=tip_font)
        line_width = line_bbox[2] - line_bbox[0]
        line_x = (width - line_width) // 2
        draw.text((line_x, y_offset), line, fill=(255, 255, 255), font=tip_font)
        y_offset += 70
    
    return img

def create_announcement_story(title, subtitle):
    """Crea template de anuncio para story"""
    width, height = 1080, 1920
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # Gradiente
    for y in range(height):
        ratio = y / height
        r = int(74 + (80 - 74) * ratio)
        g = int(144 + (227 - 144) * ratio)
        b = int(226 + (194 - 226) * ratio)
        draw.rectangle([(0, y), (width, y+1)], fill=(r, g, b))
    
    try:
        title_font = ImageFont.truetype("arial.ttf", 60)
        subtitle_font = ImageFont.truetype("arial.ttf", 40)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
    
    # Título
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    draw.text((title_x, 500), title, fill=(255, 255, 255), font=title_font)
    
    # Subtítulo
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    subtitle_x = (width - subtitle_width) // 2
    draw.text((subtitle_x, 700), subtitle, fill=(255, 255, 255, 200), font=subtitle_font)
    
    # CTA button placeholder
    draw.rectangle([200, 1000, 880, 1150], fill=(255, 255, 255, 200))
    
    return img

def generate_all_story_templates():
    """Genera todos los templates de stories"""
    output_dir = 'marketing_content/story_templates'
    os.makedirs(output_dir, exist_ok=True)
    
    # Polls
    polls = [
        ("¿Buscas compañero de piso?", "Sí", "No"),
        ("¿Prefieres limpieza o diversión?", "Limpieza", "Diversión"),
        ("¿Horario de sueño?", "Temprano", "Tarde"),
        ("¿Música en casa?", "Siempre", "Silencio"),
        ("¿Presupuesto mensual?", "<500€", ">500€")
    ]
    
    for i, (question, opt1, opt2) in enumerate(polls, 1):
        img = create_poll_story(question, opt1, opt2)
        img.save(f'{output_dir}/poll_{i}.png')
        print(f"Created: poll_{i}.png")
    
    # Quizzes
    quizzes = [
        ("¿Qué es más importante?", "Limpieza", "Ubicación", "Precio", "Personalidad"),
        ("¿Horario ideal?", "6am-10pm", "8am-12am", "10am-2am", "Flexible"),
        ("¿Mascotas?", "Sí me gustan", "No gracias", "Depende"),
    ]
    
    for i, quiz in enumerate(quizzes, 1):
        if len(quiz) == 4:
            img = create_quiz_story(quiz[0], quiz[1], quiz[2], quiz[3], "")
        else:
            img = create_quiz_story(quiz[0], quiz[1], quiz[2], quiz[3], quiz[4])
        img.save(f'{output_dir}/quiz_{i}.png')
        print(f"Created: quiz_{i}.png")
    
    # Countdowns
    countdowns = [
        ("Lanzamiento", "Mañana"),
        ("Live Q&A", "Hoy 8pm"),
        ("Oferta termina", "48 horas"),
    ]
    
    for i, (title, date) in enumerate(countdowns, 1):
        img = create_countdown_story(title, date)
        img.save(f'{output_dir}/countdown_{i}.png')
        print(f"Created: countdown_{i}.png")
    
    # Q&A
    questions = [
        "¿Cómo funciona\nel algoritmo?",
        "¿Es seguro\nusar la app?",
        "¿Cuánto cuesta\nel Premium?",
    ]
    
    for i, question in enumerate(questions, 1):
        img = create_qa_story(question)
        img.save(f'{output_dir}/qa_{i}.png')
        print(f"Created: qa_{i}.png")
    
    # Tips
    tips = [
        (1, "Sé específico con tus\npreferencias desde el inicio"),
        (2, "Verifica siempre la identidad\nde tus potenciales compañeros"),
        (3, "Establece reglas de convivencia\nclaras desde el principio"),
        (4, "Comunícate abiertamente sobre\nexpectativas y límites"),
        (5, "Sé flexible y dispuesto a\ncomprometer"),
    ]
    
    for num, tip in tips:
        img = create_tip_story(num, tip)
        img.save(f'{output_dir}/tip_{num}.png')
        print(f"Created: tip_{num}.png")
    
    # Announcements
    announcements = [
        ("¡Nueva Feature!", "Chat seguro ahora disponible"),
        ("¡Oferta Especial!", "50% descuento en Premium"),
        ("¡Challenge!", "Tag a tu compañero ideal"),
    ]
    
    for i, (title, subtitle) in enumerate(announcements, 1):
        img = create_announcement_story(title, subtitle)
        img.save(f'{output_dir}/announcement_{i}.png')
        print(f"Created: announcement_{i}.png")
    
    print(f"\nAll story templates generated in {output_dir}")

if __name__ == '__main__':
    generate_all_story_templates()
