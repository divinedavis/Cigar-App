"""Generate Maduro's Grove-style M mark.

Outputs:
  Maduro/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png  (opaque green gradient + white M)
  Maduro/Assets.xcassets/MaduroLogo.imageset/MaduroLogo.png   (transparent, white M for splash)
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SIZE = 1024

# Grove-like bottle-green gradient.
GRAD_TOP = (8, 92, 52)       # deep forest green
GRAD_MID = (18, 140, 78)     # mid emerald
GRAD_BOT = (6, 70, 38)       # dark base

def vertical_gradient(w: int, h: int) -> Image.Image:
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        if t < 0.5:
            k = t * 2
            r = int(GRAD_TOP[0] + (GRAD_MID[0] - GRAD_TOP[0]) * k)
            g = int(GRAD_TOP[1] + (GRAD_MID[1] - GRAD_TOP[1]) * k)
            b = int(GRAD_TOP[2] + (GRAD_MID[2] - GRAD_TOP[2]) * k)
        else:
            k = (t - 0.5) * 2
            r = int(GRAD_MID[0] + (GRAD_BOT[0] - GRAD_MID[0]) * k)
            g = int(GRAD_MID[1] + (GRAD_BOT[1] - GRAD_MID[1]) * k)
            b = int(GRAD_MID[2] + (GRAD_BOT[2] - GRAD_MID[2]) * k)
        for x in range(w):
            px[x, y] = (r, g, b)
    return img


def add_sheen(img: Image.Image) -> Image.Image:
    """Diagonal bright streak to mimic Grove's metallic highlight."""
    w, h = img.size
    sheen = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(sheen)
    # Broad soft diagonal band, top-right to bottom-left.
    band_w = int(w * 0.55)
    for i in range(-band_w, w + band_w, 2):
        alpha = max(0, 90 - abs(i - w * 0.6) * 0.18)
        d.line([(i + band_w, 0), (i - band_w, h)], fill=int(alpha), width=3)
    sheen = sheen.filter(ImageFilter.GaussianBlur(radius=80))
    overlay = Image.new("RGB", (w, h), (255, 255, 255))
    return Image.composite(overlay, img, sheen).convert("RGB")


def load_bold_font(size: int) -> ImageFont.FreeTypeFont:
    # Heavy, rounded, geometric — closest built-in macOS match to Grove.
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial Black.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def draw_m(img: Image.Image, color=(255, 255, 255, 255), *, scale: float = 1.0) -> None:
    """Render a bold, geometric uppercase M centered on img."""
    w, h = img.size
    draw = ImageDraw.Draw(img)
    font_size = int(min(w, h) * 0.78 * scale)
    font = load_bold_font(font_size)
    bbox = draw.textbbox((0, 0), "M", font=font, anchor="lt")
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (w - tw) / 2 - bbox[0]
    y = (h - th) / 2 - bbox[1] - int(h * 0.02)
    draw.text((x, y), "M", font=font, fill=color)


def build_app_icon(path: Path) -> None:
    # App Store wants opaque 1024x1024 — no transparency, no rounded corners (iOS masks it).
    img = vertical_gradient(SIZE, SIZE)
    img = add_sheen(img)
    canvas = img.convert("RGBA")
    draw_m(canvas, color=(255, 255, 255, 255), scale=0.92)
    canvas.convert("RGB").save(path, "PNG", optimize=True)
    print(f"wrote {path}")


def build_splash_logo(path: Path) -> None:
    # Transparent PNG, just a white M — splash renders it over the animated background.
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_m(canvas, color=(255, 255, 255, 255), scale=1.0)
    canvas.save(path, "PNG", optimize=True)
    print(f"wrote {path}")


def main() -> None:
    build_app_icon(ROOT / "Maduro" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png")
    build_splash_logo(ROOT / "Maduro" / "Assets.xcassets" / "MaduroLogo.imageset" / "MaduroLogo.png")


if __name__ == "__main__":
    main()
