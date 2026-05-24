"""Generate UangApp launcher icon: white bg + green U (#5B8266)."""
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    raise SystemExit("Install Pillow: pip install pillow")

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "branding"
OUT_DIR.mkdir(parents=True, exist_ok=True)

FOREST = (91, 130, 102, 255)
WHITE = (255, 255, 255, 255)
SIZE = 1024


def draw_u(draw, box, color):
    """Draw letter U in bounding box using arcs + lines."""
    x0, y0, x1, y1 = box
    w = x1 - x0
    h = y1 - y0
    t = int(w * 0.22)
    # Left stem
    draw.rectangle([x0, y0, x0 + t, y1 - t], fill=color)
    # Right stem
    draw.rectangle([x1 - t, y0, x1, y1 - t], fill=color)
    # Bottom arc (filled rectangle + ellipse cap)
    draw.rectangle([x0, y1 - t * 2, x1, y1], fill=color)
    draw.ellipse([x0, y1 - t * 3, x1, y1 + t], fill=color)


def main():
    # Full icon (white background + U)
    img = Image.new("RGBA", (SIZE, SIZE), WHITE)
    draw = ImageDraw.Draw(img)
    margin = int(SIZE * 0.18)
    draw_u(draw, (margin, margin, SIZE - margin, SIZE - margin), FOREST)
    img.convert("RGB").save(OUT_DIR / "app_icon.png", "PNG")

    # Foreground only (transparent) for adaptive Android
    fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_fg = ImageDraw.Draw(fg)
    draw_u(
        draw_fg,
        (margin, margin, SIZE - margin, SIZE - margin),
        FOREST,
    )
    fg.save(OUT_DIR / "app_icon_foreground.png", "PNG")

    print(f"Saved icons to {OUT_DIR}")


if __name__ == "__main__":
    main()
