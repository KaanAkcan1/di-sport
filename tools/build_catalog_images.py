"""Katalog görsellerini üretir.

Kaynak: free-exercise-db (kamu malı). Ham fotoğraflar doğrudan
kullanılmıyor; hepsi aynı işlemden geçiyor:

1. Kırpma — kadrajın kenarlarındaki salon tabelaları ve kalabalık dışarıda
   kalsın diye. Ürüne üçüncü taraf markası girmemeli.
2. Duotone — gri tonlamadan marka lacivertine eşleme. Farklı ışıkta,
   farklı salonda çekilmiş kareler tek görsel dile oturur.
3. İki kare yan yana — veri setinin 0.jpg'si başlangıç, 1.jpg'si bitiş
   pozisyonu. Tek kare hareketi anlatmıyor; ikisi birlikte anlatıyor.
4. Numaralandırma — sıra belirsiz kalmasın.

Çıktı: app/assets/exercises/<id>.webp
"""

from __future__ import annotations

import io
import os
import urllib.request

from PIL import Image, ImageDraw, ImageEnhance, ImageFont, ImageOps

BASE = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises"
OUT_DIR = os.path.join("..", "..", "..", "..", "..", "..", "..")  # kullanılmıyor

# Uygulamadaki katalog id'si -> (kaynak id, sol kırpma, sağ kırpma)
#
# Kırpma oranı hareket başına ayarlı. Tek tip kırpma denendi ve bazı
# karelerde asıl konuyu kesti: band açmada bandın bir ucunu, basamak
# çıkışında basamağın kendisini. Konu geniş olan karelerde kırpma
# gevşetilir, kalabalık olanlarda sıkılır.
SOURCES = {
    # Yalnızca hareketi net gösteren ve arka planında okunur üçüncü taraf
    # markası kalmayan kareler. Elenenler ve gerekçeleri:
    #   band_pull_apart        - iki kare de aynı pozu gösteriyor, salon
    #                            tabelası kırpmadan sonra da okunuyor
    #   step_up                - kareler basamak çıkışını göstermiyor
    #   stationary_bike        - kalabalık kadraj; makine zaten tanıdık
    #   treadmill_incline_walk - aynı gerekçe
    # Bu hareketler görselsiz kalır; anlatım metni taşır.
    "incline_pushup": ("Incline_Push-Up", 0.24, 0.12),
    "pushup": ("Pushups", 0.18, 0.08),
    "superman": ("Superman", 0.12, 0.06),
    "plank": ("Plank", 0.16, 0.06),
    "dead_bug": ("Dead_Bug", 0.06, 0.04),
    "chair_squat": ("Bodyweight_Squat", 0.20, 0.10),
    "glute_bridge": ("Butt_Lift_Bridge", 0.10, 0.06),
}

DARK = (23, 42, 84)  # brand900 civarı
LIGHT = (241, 245, 249)  # neutral100
BADGE = (29, 78, 216)  # brand700

CARD_W = 900
GAP = 6


def fetch(source_id: str, index: int) -> Image.Image:
    url = f"{BASE}/{source_id}/{index}.jpg"
    with urllib.request.urlopen(url, timeout=60) as resp:
        return Image.open(io.BytesIO(resp.read())).convert("RGB")


def treat(im: Image.Image, left: float, right: float) -> Image.Image:
    w, h = im.size
    im = im.crop((int(w * left), int(h * 0.05), w - int(w * right), h))
    gray = ImageOps.grayscale(im)
    gray = ImageEnhance.Contrast(gray).enhance(1.15)
    return ImageOps.colorize(gray, black=DARK, white=LIGHT)


def badge(draw: ImageDraw.ImageDraw, x: int, y: int, text: str) -> None:
    r = 17
    draw.ellipse([x, y, x + r * 2, y + r * 2], fill=BADGE)
    try:
        font = ImageFont.truetype("arial.ttf", 20)
    except OSError:
        font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), text, font=font)
    draw.text(
        (x + r - (bbox[2] - bbox[0]) / 2, y + r - (bbox[3] - bbox[1]) / 2 - 2),
        text,
        fill=(255, 255, 255),
        font=font,
    )


def build(catalog_id: str, spec: tuple, out_dir: str) -> str:
    source_id, left, right = spec
    half = (CARD_W - GAP) // 2
    frames = []
    for i in (0, 1):
        img = treat(fetch(source_id, i), left, right)
        h = int(half * img.height / img.width)
        frames.append(img.resize((half, h), Image.LANCZOS))

    height = min(f.height for f in frames)
    card = Image.new("RGB", (CARD_W, height), (255, 255, 255))
    card.paste(frames[0].crop((0, 0, half, height)), (0, 0))
    card.paste(frames[1].crop((0, 0, half, height)), (half + GAP, 0))

    draw = ImageDraw.Draw(card)
    badge(draw, 12, 12, "1")
    badge(draw, half + GAP + 12, 12, "2")

    path = os.path.join(out_dir, f"{catalog_id}.webp")
    card.save(path, "WEBP", quality=82, method=6)
    return path


def main() -> None:
    out_dir = os.environ["OUT_DIR"]
    os.makedirs(out_dir, exist_ok=True)
    total = 0
    for catalog_id, spec in SOURCES.items():
        path = build(catalog_id, spec, out_dir)
        size = os.path.getsize(path)
        total += size
        print(f"{catalog_id:24} <- {spec[0]:26} {size / 1024:6.1f} KB")
    print(f"\ntoplam {len(SOURCES)} gorsel, {total / 1024:.0f} KB")


if __name__ == "__main__":
    main()
