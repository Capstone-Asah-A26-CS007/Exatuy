from PIL import Image, ImageDraw
import os

# Create directory if needed
os.chdir('/home/labuser/documents/tools/website/Examora/src/main/webapp/assets/img')

# Create 32x32 favicon
img_size = 32
img = Image.new('RGBA', (img_size, img_size), (102, 126, 234, 255))
draw = ImageDraw.Draw(img)

# Draw rounded rectangle
radius = 7
draw.rounded_rectangle([(0, 0), (img_size, img_size)], radius=radius, fill=(102, 126, 234, 255))

# Draw E shape
e_coords = [
    (8, 7), (19, 7), (19, 11), (12, 11),  # Top bar
    (12, 14), (18, 14), (18, 18), (12, 18),  # Middle bar
    (12, 21), (20, 21), (20, 25), (8, 25),   # Bottom bar
    (8, 7)  # Close
]
draw.polygon(e_coords, fill=(255, 255, 255, 242))

# Draw checkmark
checkmark = [(18, 20), (20, 23), (25, 16)]
draw.line(checkmark, fill=(251, 191, 36, 255), width=2)

# Save as 32x32
img.save('favicon-32x32.png')

# Create 16x16 favicon
img_small = img.resize((16, 16), Image.Resampling.LANCZOS)
img_small.save('favicon-16x16.png')

# Create 180x180 apple touch icon
apple_size = 180
apple_img = Image.new('RGBA', (apple_size, apple_size), (255, 255, 255, 255))
apple_draw = ImageDraw.Draw(apple_img)

# Draw rounded square background
apple_draw.rounded_rectangle([(10, 10), (170, 170)], radius=35, fill=(102, 126, 234, 255))

# Draw E shape (scaled)
scale = 7
e_coords_scaled = [(c[0] * scale + 15, c[1] * scale + 15) for c in e_coords]
apple_draw.polygon(e_coords_scaled, fill=(255, 255, 255, 255))

# Draw checkmark (scaled)
checkmark_scaled = [(c[0] * scale + 15, c[1] * scale + 15) for c in checkmark]
apple_draw.line(checkmark_scaled, fill=(251, 191, 36, 255), width=12)

apple_img.save('apple-touch-icon.png')

print("Created new PNG favicons with E logo!")
