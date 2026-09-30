"""
Mock engine — honest local placeholder for photo try-on without a GPU.
Composites the garment onto the person photo as a rounded "preview patch"
and stamps a DEMO tag, so results are never mistaken for real AI output.
"""

import io

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

try:
    # A decent bitmap font is bundled with Pillow.
    FONT = ImageFont.load_default(size=28)
    FONT_SMALL = ImageFont.load_default(size=18)
except Exception:  # noqa: BLE001
    FONT = ImageFont.load_default()
    FONT_SMALL = FONT


def compose_photo_mock(person_bytes: bytes, garment_bytes: bytes, garment_name: str) -> bytes:
    person = Image.open(io.BytesIO(person_bytes)).convert("RGB")
    garment = Image.open(io.BytesIO(garment_bytes)).convert("RGBA")

    # Fit the garment at ~55% width, centred on the chest area.
    target_w = int(person.width * 0.55)
    ratio = target_w / garment.width
    target_h = int(garment.height * ratio)
    garment = garment.resize((target_w, target_h), Image.LANCZOS)

    px = (person.width - target_w) // 2
    py = int(person.height * 0.30) - target_h // 3
    py = max(py, 8)

    # Rounded-corner mask for the patch.
    mask = Image.new("L", garment.size, 0)
    d = ImageDraw.Draw(mask)
    radius = int(min(garment.size) * 0.12)
    d.rounded_rectangle([0, 0, garment.size[0] - 1, garment.size[1] - 1], radius=radius, fill=255)

    # Soften the patch slightly so it reads as a preview, not a paste.
    patch = ImageEnhance.Brightness(garment).enhance(1.02)

    person.paste(patch, (px, py), mask)

    # Caption card.
    draw = ImageDraw.Draw(person)
    label = f"{garment_name} · DEMO PREVIEW"
    try:
        tw = draw.textlength(label, font=FONT_SMALL)
    except Exception:  # noqa: BLE001
        tw = person.width * 0.5
    pad = 14
    bx = (person.width - int(tw)) // 2 - pad
    by = person.height - 74
    draw.rounded_rectangle(
        [bx, by, bx + int(tw) + pad * 2, by + 44],
        radius=12,
        fill=(0, 0, 0),
    )
    draw.text((bx + pad, by + 9), label, fill=(255, 255, 255), font=FONT_SMALL)

    out = io.BytesIO()
    person.save(out, format="JPEG", quality=88)
    return out.getvalue()
