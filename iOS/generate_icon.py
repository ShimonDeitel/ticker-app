from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), "#0B252A")
draw = ImageDraw.Draw(img)

cx, cy = SIZE // 2, SIZE // 2

# Flat circular dial backdrop.
draw.ellipse([cx - 440, cy - 440, cx + 440, cy + 440], fill="#123338")
draw.ellipse([cx - 380, cy - 380, cx + 380, cy + 380], fill="#19464D")

# Dollar-sign glyph, bold, filling ~65% of tile, coral colored.
# Draw as a thick vertical bar plus an "S" shape approximation using two arcs.
bar_w = 46
draw.rectangle([cx - bar_w // 2, cy - 320, cx + bar_w // 2, cy + 320], fill="#FA5F66")

# Top curve of S (open right).
draw.arc([cx - 210, cy - 300, cx + 210, cy - 20], start=280, end=200, fill="#FA5F66", width=70)
# Bottom curve of S (open left).
draw.arc([cx - 210, cy + 20, cx + 210, cy + 300], start=100, end=20, fill="#FA5F66", width=70)

# Clock tick marks around the rim to reinforce "live ticking counter" idea.
import math
for i in range(12):
    angle = math.radians(i * 30)
    r1, r2 = 400, 430
    x1 = cx + r1 * math.sin(angle)
    y1 = cy - r1 * math.cos(angle)
    x2 = cx + r2 * math.sin(angle)
    y2 = cy - r2 * math.cos(angle)
    draw.line([(x1, y1), (x2, y2)], fill="#6BE0BD", width=14)

img.save("/tmp/ticker_icon.png")
print("saved")
