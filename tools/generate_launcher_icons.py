"""Генерация растровых иконок лаунчера «Дыши» из векторной геометрии.

Источник дизайна — assets/icon/icon.svg (точка-«я» + три дуги дыхания на
сине-бирюзовом градиенте). Скрипт детерминированно перерисовывает ту же
геометрию через Pillow (никакого ручного растра — правило RESOURCES_ICONS):

* Android legacy-мипмапы (API < 26): mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png
  (48/72/96/144/192 px, скруглённые углы как в SVG);
* iOS AppIcon.appiconset: все размеры из Contents.json (полный квадрат без
  скругления и без альфы — маску накладывает iOS).

Запуск: python tools/generate_launcher_icons.py
Adaptive icon (API 26+) — отдельно, вектором: res/mipmap-anydpi-v26 + drawable.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent

# --- Геометрия дизайна в базовой системе 512×512 (см. icon.svg) --------------
BASE = 512.0
CORNER_R = 90.0          # скругление фона
CENTER = (256.0, 256.0)  # центр точки и колец
DOT_R = 26.0
# Кольца-рябь: (радиус центральной линии, альфа штриха, толщина штриха) —
# наружу тоньше и бледнее, как затухающая волна (иначе читается «мишенью»).
RINGS = ((66.0, 255, 17.0), (106.0, 150, 14.0), (146.0, 90, 11.0))
GRAD_TOP = (0x08, 0x91, 0xB2)     # #0891B2
GRAD_BOTTOM = (0x16, 0x4E, 0x63)  # #164E63

SUPERSAMPLE = 4


def _gradient(size: int) -> Image.Image:
    """Вертикальный линейный градиент top→bottom."""
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        t = y / max(size - 1, 1)
        color = tuple(
            round(GRAD_TOP[i] + (GRAD_BOTTOM[i] - GRAD_TOP[i]) * t)
            for i in range(3)
        )
        for x in range(size):
            px[x, y] = color
    return img


def _draw_motif(draw: ImageDraw.ImageDraw, size: float) -> None:
    """Кольца-рябь и точка в масштабе size (канва уже с суперсэмплом)."""
    k = size / BASE
    cx, cy = CENTER[0] * k, CENTER[1] * k

    for r_base, alpha, stroke_base in RINGS:
        stroke = max(round(stroke_base * k), 1)
        # PIL рисует полосу шириной width ВНУТРЬ от радиуса bbox, поэтому
        # для штриха с центральной линией r берём внешний радиус r + stroke/2.
        r_outer = r_base * k + stroke / 2
        bbox = (cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer)
        draw.arc(bbox, 0, 360, fill=(255, 255, 255, alpha), width=stroke)

    dot = DOT_R * k
    draw.ellipse((cx - dot, cy - dot, cx + dot, cy + dot),
                 fill=(255, 255, 255, 255))


def render(size: int, *, rounded: bool) -> Image.Image:
    """Иконка size×size; rounded — скруглённые углы (Android legacy)."""
    big = size * SUPERSAMPLE
    img = _gradient(big).convert("RGBA")
    # Режим 'RGBA' — полупрозрачные кольца СМЕШИВАЮТСЯ с градиентом
    # (иначе PIL записал бы альфу в пиксели, продырявив непрозрачный фон).
    draw = ImageDraw.Draw(img, "RGBA")
    _draw_motif(draw, float(big))

    if rounded:
        mask = Image.new("L", (big, big), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            (0, 0, big - 1, big - 1), radius=CORNER_R / BASE * big, fill=255
        )
        img.putalpha(mask)

    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    android_res = ROOT / "android" / "app" / "src" / "main" / "res"
    for dpi, size in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                      ("xxhdpi", 144), ("xxxhdpi", 192)):
        out = android_res / f"mipmap-{dpi}" / "ic_launcher.png"
        render(size, rounded=True).save(out)
        print(f"android {dpi:8} {size:4}px -> {out.relative_to(ROOT)}")

    ios_set = (ROOT / "ios" / "Runner" / "Assets.xcassets"
               / "AppIcon.appiconset")
    ios_icons = [
        ("Icon-App-20x20@1x.png", 20), ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60), ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58), ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40), ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120), ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180), ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152), ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    for name, size in ios_icons:
        # iOS: без альфы (требование App Store для 1024) и без скругления.
        render(size, rounded=False).convert("RGB").save(ios_set / name)
        print(f"ios {size:4}px -> {name}")


if __name__ == "__main__":
    main()
