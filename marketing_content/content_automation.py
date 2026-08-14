#!/usr/bin/env python3
"""
Herramienta de automatización de contenido para RoomMate Match
Genera automáticamente posts, captions y calendarios basados en templates
"""

import json
import random
from datetime import datetime, timedelta

class ContentGenerator:
    def __init__(self):
        self.tips = [
            "Sé específico con tus preferencias desde el principio",
            "Verifica siempre la identidad de tus potenciales compañeros",
            "Establece reglas de convivencia claras desde el inicio",
            "Comunícate abiertamente sobre expectativas y límites",
            "Sé flexible y dispuesto a comprometer",
            "Sé honesto con tu presupuesto desde el principio",
            "Muestra tu personalidad real en tu perfil",
            "Responde rápidamente a los matches",
            "Pide referencias si es posible",
            "Confía en tu instinto"
        ]
        
        self.humor_situations = [
            "Cuando tu compañero usa tu shampoo sin pedir",
            "Cuando tu compañero limpia por primera vez en meses",
            "Cuando tu compañero llega a las 3am con música",
            "Cuando tu compañero come tu comida",
            "Cuando tu compañero no lava los platos",
            "Cuando tu compañero tiene visitas sin avisar"
        ]
        
        self.success_stories = [
            "María encontró a su compañero ideal en 2 semanas",
            "Juan llevaba 4 meses buscando, lo encontró en 10 días",
            "Carla y su nueva compañera tienen 95% de compatibilidad",
            "Pedro encontró a alguien con sus mismos horarios de estudio",
            "Laura y su compañera son mejores amigas ahora"
        ]
        
        self.features = [
            "Algoritmo de compatibilidad inteligente",
            "Chat seguro y privado",
            "Verificación de identidad",
            "Filtros personalizados",
            "Matches ilimitados (Premium)",
            "Soporte exclusivo (Premium)"
        ]
        
        self.hashtags = [
            "#roommate #roommates #roommatematch #roommatefinder #flatmate",
            "#convivencia #compartirpiso #compañerodepiso #buscacompañero",
            "#app #startup #tech #innovation #launch",
            "#tips #advice #howto #tutorial #humor #relatable"
        ]
    
    def generate_instagram_caption(self, post_type):
        """Genera caption para Instagram basado en el tipo de post"""
        
        if post_type == "tip":
            tip = random.choice(self.tips)
            return f"""💡 Tip del día: {tip}

¿Quieres más tips como este? Síguenos para contenido diario sobre convivencia y roommates.

Link en bio para descargar RoomMate Match 👇

{random.choice(self.hashtags)} #tips #roommate #advice"""

        elif post_type == "humor":
            situation = random.choice(self.humor_situations)
            return f"""😅 {situation}

¿Te pasa esto? ¡No eres el único!

Con RoomMate Match encuentras compañeros compatibles desde el principio. Evita sorpresas desagradables.

Link en bio para descargar 📱

{random.choice(self.hashtags)} #roommateproblems #humor #relatable"""

        elif post_type == "success":
            story = random.choice(self.success_stories)
            return f"""🎉 Success story: {story}

¿Quieres tu historia de éxito? Descarga RoomMate Match y encuentra a tu compañero ideal.

Link en bio 👇

{random.choice(self.hashtags)} #success #roommategoals #testimonial"""

        elif post_type == "feature":
            feature = random.choice(self.features)
            return f"""🚀 Feature spotlight: {feature}

Descubre todas las features de RoomMate Match en el link de bio.

{random.choice(self.hashtags)} #feature #tech #roommatematch"""

        else:
            return f"""¡RoomMate Match te ayuda a encontrar tu compañero ideal! 🏠

Swipe, match, encuentra a tu compañero perfecto.

Link en bio para descargar 📱

{random.choice(self.hashtags)} #roommatematch #roommate #app"""

    def generate_tweet(self, tweet_type):
        """Genera tweet basado en el tipo"""
        
        if tweet_type == "tip":
            tip = random.choice(self.tips)
            return f"Tip del día: {tip} 🏠 #roommatematch #tips #roommate"
        
        elif tweet_type == "humor":
            situation = random.choice(self.humor_situations)
            return f"{situation} 😅 #roommateproblems #humor #relatable"
        
        elif tweet_type == "success":
            story = random.choice(self.success_stories)
            return f"🎉 {story}. ¿Serás el próximo? #success #roommategoals"
        
        elif tweet_type == "feature":
            feature = random.choice(self.features)
            return f"🚀 {feature} en RoomMate Match #feature #tech #app"
        
        else:
            return "📱 Descarga RoomMate Match y encuentra a tu compañero ideal [link] #roommatematch #roommate #app"

    def generate_tiktok_caption(self, video_type):
        """Genera caption para TikTok"""
        
        captions = {
            "pov": f"POV: {random.choice(self.humor_situations)} 😅 #POV #roommate #relatable",
            "tutorial": f"Tutorial: Cómo usar RoomMate Match ⏱️ #tutorial #howto #app",
            "success": f"Success story: {random.choice(self.success_stories)} 💕 #testimonial #success",
            "tip": f"Tip: {random.choice(self.tips)} 💡 #tips #advice #roommate"
        }
        
        return captions.get(video_type, "Descubre RoomMate Match 📱 #roommate #app")

    def generate_weekly_calendar(self, start_date):
        """Genera calendario semanal de contenido"""
        calendar = []
        current_date = start_date
        
        days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        post_types = ["tip", "humor", "success", "feature", "tip", "humor", "success"]
        
        for i in range(7):
            day_content = {
                "day": days[i],
                "date": current_date.strftime("%Y-%m-%d"),
                "instagram": {
                    "post_type": post_types[i],
                    "caption": self.generate_instagram_caption(post_types[i]),
                    "story": f"Poll: ¿Buscas compañero? (Sí/No)"
                },
                "tiktok": {
                    "caption": self.generate_tiktok_caption("pov" if i % 2 == 0 else "tutorial")
                },
                "twitter": {
                    "tweets": [
                        self.generate_tweet("tip"),
                        self.generate_tweet("humor")
                    ]
                }
            }
            calendar.append(day_content)
            current_date += timedelta(days=1)
        
        return calendar

    def generate_content_batch(self, platform, count):
        """Genera un batch de contenido para una plataforma"""
        content = []
        
        if platform == "instagram":
            for i in range(count):
                post_type = random.choice(["tip", "humor", "success", "feature"])
                content.append({
                    "type": post_type,
                    "caption": self.generate_instagram_caption(post_type)
                })
        
        elif platform == "twitter":
            for i in range(count):
                tweet_type = random.choice(["tip", "humor", "success", "feature"])
                content.append({
                    "type": tweet_type,
                    "tweet": self.generate_tweet(tweet_type)
                })
        
        elif platform == "tiktok":
            for i in range(count):
                video_type = random.choice(["pov", "tutorial", "success", "tip"])
                content.append({
                    "type": video_type,
                    "caption": self.generate_tiktok_caption(video_type)
                })
        
        return content

    def save_to_json(self, data, filename):
        """Guarda datos en archivo JSON"""
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Content saved to {filename}")

def main():
    generator = ContentGenerator()
    
    print("=== RoomMate Match Content Generator ===\n")
    
    # Generar calendario semanal
    print("1. Generating weekly calendar...")
    start_date = datetime.now()
    weekly_calendar = generator.generate_weekly_calendar(start_date)
    generator.save_to_json(weekly_calendar, "marketing_content/generated_weekly_calendar.json")
    
    # Generar batch de Instagram
    print("2. Generating Instagram content batch...")
    instagram_batch = generator.generate_content_batch("instagram", 10)
    generator.save_to_json(instagram_batch, "marketing_content/generated_instagram_batch.json")
    
    # Generar batch de Twitter
    print("3. Generating Twitter content batch...")
    twitter_batch = generator.generate_content_batch("twitter", 15)
    generator.save_to_json(twitter_batch, "marketing_content/generated_twitter_batch.json")
    
    # Generar batch de TikTok
    print("4. Generating TikTok content batch...")
    tiktok_batch = generator.generate_content_batch("tiktok", 10)
    generator.save_to_json(tiktok_batch, "marketing_content/generated_tiktok_batch.json")
    
    print("\n=== Content Generation Complete ===")
    print("Generated files:")
    print("- generated_weekly_calendar.json")
    print("- generated_instagram_batch.json")
    print("- generated_twitter_batch.json")
    print("- generated_tiktok_batch.json")

if __name__ == '__main__':
    main()
