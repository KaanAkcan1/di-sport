"""Formality marka varlıklarını üretir (ikonlar + açılış görseli).

Kaynak geometri tek yerde durur: V2a "nabız onayı" işareti, 460'lık
ızgarada tanımlı bir çoklu çizgi. Bu betik ondan türetir:

- Android adaptif ikon katmanları (``mipmap-*/ic_launcher_foreground.png``)
- Eski tip başlatıcı ikonları (``mipmap-*/ic_launcher.png``)
- Yerel açılış ekranı işareti (``drawable-*/splash_mark.png``)
- Play Store 512 ikonu ve pazarlama splash'i (``docs/brand/assets/``)

Çıktı deterministtir: aynı betik aynı dosyaları üretir. İkon
değiştirilecekse elle PNG düzenleme — geometriyi burada değiştir ve
yeniden çalıştır. Flutter tarafındaki animasyonlu eş:
``app/lib/core/widgets/formality_mark.dart`` (aynı geometri).

Kullanım:  python tools/build_brand_assets.py
"""

from __future__ import annotations

import os

from PIL import Image, ImageDraw

GREEN = "#42B883"  # marka sabiti — tek dokunulmaz renk
DARK = "#0F1B16"  # Palet A "Gece Grafiti" zemini

# V2a geometrisi: 460'lık ızgara, çizgi kalınlığı 30.
# Düz hat → küçük vuruş → derin iniş → uzun yükseliş (onay işareti).
MARK = [(66, 252), (138, 252), (162, 218), (196, 252), (238, 342), (372, 148)]
GRID = 460
STROKE = 30
CONTENT = (66, 148, 372, 342)  # işaretin sınır kutusu

APP_RES = os.path.join(os.path.dirname(__file__), "..", "app", "android",
                       "app", "src", "main", "res")
BRAND_OUT = os.path.join(os.path.dirname(__file__), "..", "docs", "brand",
                         "assets")

SS = 4  # süperörnekleme çarpanı


def _draw_mark(draw: ImageDraw.ImageDraw, scale: float, dx: float, dy: float,
               stroke: float) -> None:
    pts = [((x * scale + dx) * SS, (y * scale + dy) * SS) for x, y in MARK]
    width = max(2, round(stroke * SS))
    draw.line(pts, fill=GREEN, width=width, joint="curve")
    radius = width / 2
    for px, py in (pts[0], pts[-1]):
        draw.ellipse([px - radius, py - radius, px + radius, py + radius],
                     fill=GREEN)


def _mark_layer(canvas: int, content: int) -> Image.Image:
    """İşareti şeffaf zeminde, `canvas` içinde `content` genişliğe sığdırır."""
    img = Image.new("RGBA", (canvas * SS, canvas * SS), (0, 0, 0, 0))
    cw = CONTENT[2] - CONTENT[0]
    chh = CONTENT[3] - CONTENT[1]
    scale = content / cw
    dx = (canvas - cw * scale) / 2 - CONTENT[0] * scale
    dy = (canvas - chh * scale) / 2 - CONTENT[1] * scale
    _draw_mark(ImageDraw.Draw(img), scale, dx, dy, STROKE * scale)
    return img.resize((canvas, canvas), Image.LANCZOS)


def _launcher_icon(size: int) -> Image.Image:
    """Eski tip başlatıcı ikonu: yuvarlatılmış kare, köşeler şeffaf."""
    base = Image.new("RGB", (GRID * SS, GRID * SS), DARK)
    _draw_mark(ImageDraw.Draw(base), 1, 0, 0, STROKE)
    mask = Image.new("L", (GRID * SS, GRID * SS), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, GRID * SS, GRID * SS], radius=int(GRID * SS * 0.226), fill=255)
    out = Image.new("RGBA", (GRID * SS, GRID * SS), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
    return out.resize((size, size), Image.LANCZOS)


def _save(img: Image.Image, *path: str) -> None:
    target = os.path.join(*path)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    img.save(target)
    print("yazıldı:", os.path.relpath(target))


def main() -> None:
    # Adaptif ikon: 108dp tuval, güvenli bölge 66dp → içerik ~%55.
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, mul in densities.items():
        canvas = round(108 * mul)
        _save(_mark_layer(canvas, round(canvas * 0.55)),
              APP_RES, f"mipmap-{name}", "ic_launcher_foreground.png")
        _save(_launcher_icon(round(48 * mul)),
              APP_RES, f"mipmap-{name}", "ic_launcher.png")
        # Açılış işareti: 160dp genişlik, layer-list içinde ortalanır.
        _save(_mark_layer(round(160 * mul), round(160 * mul * 0.94)),
              APP_RES, f"drawable-{name}", "splash_mark.png")

    # Mağaza ve pazarlama varlıkları.
    store = Image.new("RGB", (512 * SS, 512 * SS), DARK)
    scale = 512 / GRID
    _draw_mark(ImageDraw.Draw(store), scale, 26 * scale, 26 * scale,
               STROKE * scale)
    _save(store.resize((512, 512), Image.LANCZOS),
          BRAND_OUT, "play-store-512.png")

    _save(Image.new("RGB", (432, 432), DARK),
          BRAND_OUT, "adaptive-background-432.png")
    _save(_mark_layer(432, 250), BRAND_OUT, "adaptive-foreground-432.png")


if __name__ == "__main__":
    main()
