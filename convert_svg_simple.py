# Simple SVG to PNG conversion using PIL
# This script creates basic PNG icons from the SVG concept

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon(size, output_path):
    """Create a simple app icon with RoomMate Match branding"""
    # Create image with gradient background
    img = Image.new('RGB', (size, size), color=(74, 144, 226))  # #4A90E2
    draw = ImageDraw.Draw(img)
    
    # Draw gradient effect (simple)
    for i in range(size):
        alpha = int(255 * (i / size))
        color = (74, 144, 226)  # Blue
        draw.line([(0, i), (size, i)], fill=color)
    
    # Draw house icon (simplified)
    margin = size // 8
    house_width = size - 2 * margin
    house_height = int(house_width * 0.8)
    
    # House body
    house_top = margin + int(house_height * 0.3)
    draw.rectangle([margin, house_top, margin + house_width, house_top + house_height], 
                   fill=(255, 255, 255), outline=(255, 255, 255))
    
    # Roof
    roof_points = [
        (margin, house_top),
        (size // 2, margin),
        (size - margin, house_top)
    ]
    draw.polygon(roof_points, fill=(255, 255, 255), outline=(255, 255, 255))
    
    # Door
    door_width = house_width // 4
    door_height = house_height // 2
    door_x = size // 2 - door_width // 2
    door_y = house_top + house_height - door_height
    draw.rectangle([door_x, door_y, door_x + door_width, door_y + door_height],
                   fill=(74, 144, 226), outline=(74, 144, 226))
    
    # Windows
    window_size = house_width // 5
    window_y = house_top + house_height // 4
    
    # Left window
    draw.rectangle([margin + house_width // 4, window_y, 
                    margin + house_width // 4 + window_size, window_y + window_size],
                   fill=(80, 227, 194), outline=(80, 227, 194))  # #50E3C2
    
    # Right window
    draw.rectangle([size - margin - house_width // 4 - window_size, window_y,
                    size - margin - house_width // 4, window_y + window_size],
                   fill=(80, 227, 194), outline=(80, 227, 194))
    
    # Add text for larger icons
    if size >= 512:
        try:
            # Try to use a default font
            font = ImageFont.truetype("arial.ttf", size // 10)
        except:
            font = ImageFont.load_default()
        
        text = "RM"
        text_width = font.getlength(text)
        text_x = (size - text_width) // 2
        text_y = size - margin - size // 8
        draw.text((text_x, text_y), text, fill=(255, 255, 255), font=font)
    
    # Save the image
    img.save(output_path, 'PNG')
    print(f"Created: {output_path} ({size}x{size})")

def main():
    base_path = r"C:\Users\User\IdeaProjects\tinder piso1\assets"
    
    # Google Play icon
    google_play_path = os.path.join(base_path, "store", "google-play", "icon-512x512.png")
    create_app_icon(512, google_play_path)
    
    # App Store icon
    app_store_path = os.path.join(base_path, "store", "app-store", "app-icon-1024x1024.png")
    create_app_icon(1024, app_store_path)
    
    # Android icons
    android_sizes = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192
    }
    
    for density, size in android_sizes.items():
        android_path = os.path.join(base_path, "app-icons", "android", f"mipmap-{density}", "ic_launcher.png")
        create_app_icon(size, android_path)
    
    print("\nAll app icons created successfully!")

if __name__ == "__main__":
    main()
