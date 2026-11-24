#!/usr/bin/env python3
"""Draws the Roblox icon (512x512), thumbnails (1920x1080) and pass icons for Slap the Blob.

Usage:  python3 tools/make_art.py      (needs Pillow: pip install pillow)
Output: marketing/*.png
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "marketing"
OUT.mkdir(exist_ok=True)

FONT_BLACK = "/usr/share/fonts/opentype/inter/InterDisplay-Black.otf"
FONT_BOLD = "/usr/share/fonts/opentype/inter/InterDisplay-ExtraBold.otf"
OUTLINE = (40, 15, 45)
SS = 2  # supersampling for smooth edges


def font(path, size):
    return ImageFont.truetype(path, int(size))


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def darker(c, f=0.75):
    return tuple(int(v * f) for v in c[:3])


def background(w, h, top, bottom, ray_color, center, rays=18):
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        d.line([(0, y), (w, y)], fill=lerp(top, bottom, y / (h - 1)))
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    cx, cy = center
    radius = math.hypot(w, h)
    for i in range(rays):
        a0 = (i / rays) * 2 * math.pi
        a1 = a0 + math.pi / rays
        od.polygon([(cx, cy), (cx + math.cos(a0) * radius, cy + math.sin(a0) * radius),
                    (cx + math.cos(a1) * radius, cy + math.sin(a1) * radius)], fill=ray_color)
    img = Image.alpha_composite(img.convert("RGBA"), overlay)
    return img


def ellipse(d, box, fill, width):
    d.ellipse(box, fill=fill, outline=OUTLINE, width=width)


def draw_blob(img, cx, cy, s, color, accessory=None, shocked=True):
    """Round cartoon blob monster, same design as the in-game Blobs. (cx, cy) = body center, s = diameter."""
    ow = max(3, int(s * 0.018))
    r = s / 2
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([cx - r * 0.95, cy + r * 0.88, cx + r * 0.95, cy + r * 1.12], fill=(0, 0, 0, 70))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(s * 0.03)))
    d = ImageDraw.Draw(img)
    # feet
    for side in (-1, 1):
        fx = cx + side * s * 0.22
        ellipse(d, [fx - s * 0.16, cy + r * 0.82, fx + s * 0.16, cy + r * 1.08], darker(color, 0.8), ow)
    # body
    ellipse(d, [cx - r, cy - r, cx + r, cy + r], color, ow)
    # body shine
    d.ellipse([cx - r * 0.62, cy - r * 0.7, cx - r * 0.3, cy - r * 0.42], fill=(255, 255, 255, 170))
    # eyes
    for side in (-1, 1):
        ex, ey = cx + side * s * 0.17, cy - s * 0.08
        er = s * 0.12
        ellipse(d, [ex - er, ey - er, ex + er, ey + er], (255, 255, 255), ow)
        pr = s * 0.06
        px = ex + (s * 0.01 if side < 0 else -s * 0.01)
        d.ellipse([px - pr, ey - pr + s * 0.01, px + pr, ey + pr + s * 0.01], fill=OUTLINE)
        d.ellipse([px - pr * 0.35 - s * 0.015, ey - pr * 0.6, px - pr * 0.35 + s * 0.015, ey - pr * 0.6 + s * 0.03], fill=(255, 255, 255))
        # brows (surprised)
        bx = ex
        d.line([(bx - s * 0.08, ey - s * 0.17 - side * s * 0.0), (bx + s * 0.08, ey - s * 0.19)], fill=OUTLINE, width=int(ow * 1.8)) if side < 0 else \
            d.line([(bx - s * 0.08, ey - s * 0.19), (bx + s * 0.08, ey - s * 0.17)], fill=OUTLINE, width=int(ow * 1.8))
        # blush
        bl = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(bl).ellipse([cx + side * s * 0.3 - s * 0.07, cy + s * 0.06 - s * 0.045, cx + side * s * 0.3 + s * 0.07, cy + s * 0.06 + s * 0.045], fill=(255, 100, 150, 150))
        img.alpha_composite(bl)
        d = ImageDraw.Draw(img)
    # mouth
    if shocked:
        ellipse(d, [cx - s * 0.07, cy + s * 0.1, cx + s * 0.07, cy + s * 0.25], (130, 25, 60), ow)
    else:
        d.arc([cx - s * 0.12, cy + s * 0.02, cx + s * 0.12, cy + s * 0.2], 20, 160, fill=OUTLINE, width=int(ow * 1.6))
    if accessory == "crown":
        gold = (255, 200, 40)
        base_y = cy - r * 0.86
        pts = [(cx - s * 0.2, base_y), (cx - s * 0.2, base_y - s * 0.14), (cx - s * 0.12, base_y - s * 0.06), (cx - s * 0.05, base_y - s * 0.2),
               (cx, base_y - s * 0.07), (cx + s * 0.05, base_y - s * 0.2), (cx + s * 0.12, base_y - s * 0.06), (cx + s * 0.2, base_y - s * 0.14), (cx + s * 0.2, base_y)]
        d.polygon(pts, fill=gold, outline=OUTLINE, width=ow)
        for gx, col in ((-0.12, (255, 40, 80)), (0, (60, 160, 255)), (0.12, (255, 40, 80))):
            d.ellipse([cx + gx * s - s * 0.022, base_y - s * 0.05, cx + gx * s + s * 0.022, base_y - s * 0.006], fill=col)
    if accessory == "bow":
        pink = (255, 80, 150)
        bx, by = cx + r * 0.5, cy - r * 0.82
        for dx in (-1, 1):
            ellipse(d, [bx + dx * s * 0.1 - s * 0.08, by - s * 0.06, bx + dx * s * 0.1 + s * 0.08, by + s * 0.06], pink, ow)
        ellipse(d, [bx - s * 0.04, by - s * 0.04, bx + s * 0.04, by + s * 0.04], pink, ow)


def hand_layer(size, color, kind="normal"):
    """Open hand, fingers up, on a transparent layer of size x size."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    s = size
    ow = max(3, int(s * 0.022))
    cx = s * 0.5
    palm = [cx - s * 0.22, s * 0.38, cx + s * 0.22, s * 0.78]
    fingers = [(-0.165, 0.27), (-0.055, 0.2), (0.055, 0.22), (0.165, 0.3)]
    for fx, top in fingers:
        x = cx + fx * s
        d.rounded_rectangle([x - s * 0.05, s * top, x + s * 0.05, s * 0.5], radius=s * 0.05, fill=color, outline=OUTLINE, width=ow)
    # thumb
    th = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(th).rounded_rectangle([cx + s * 0.16, s * 0.42, cx + s * 0.27, s * 0.68], radius=s * 0.05, fill=color, outline=OUTLINE, width=ow)
    th = th.rotate(-35, center=(cx + s * 0.2, s * 0.64), resample=Image.BICUBIC)
    layer.alpha_composite(th)
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle(palm, radius=s * 0.1, fill=color, outline=OUTLINE, width=ow)
    cuff_color = (255, 110, 180) if kind == "normal" else (255, 215, 60)
    d.rounded_rectangle([cx - s * 0.24, s * 0.74, cx + s * 0.24, s * 0.86], radius=s * 0.04, fill=cuff_color, outline=OUTLINE, width=ow)
    if kind == "thanos":
        stones = [(160, 60, 255), (60, 140, 255), (255, 40, 40), (40, 230, 90)]
        for (fx, _), col in zip(fingers, stones):
            x = cx + fx * s
            d.ellipse([x - s * 0.035, s * 0.42, x + s * 0.035, s * 0.49], fill=col, outline=OUTLINE, width=max(2, ow // 2))
        d.ellipse([cx - s * 0.07, s * 0.55, cx + s * 0.07, s * 0.69], fill=(255, 230, 40), outline=OUTLINE, width=ow)
        d.ellipse([cx + s * 0.19, s * 0.55, cx + s * 0.25, s * 0.61], fill=(255, 150, 30), outline=OUTLINE, width=max(2, ow // 2))
    if kind == "ultragod":
        rainbow = [(255, 60, 60), (255, 160, 40), (255, 230, 60), (80, 220, 90), (70, 160, 255), (170, 90, 255)]
        for i in range(10):
            a = i / 10 * 2 * math.pi
            x = cx + math.cos(a) * s * 0.3
            y = s * 0.8 + math.sin(a) * s * 0.07
            col = rainbow[i % len(rainbow)]
            d.ellipse([x - s * 0.03, y - s * 0.03, x + s * 0.03, y + s * 0.03], fill=col, outline=OUTLINE, width=max(2, ow // 2))
        for fx, _ in fingers:
            x = cx + fx * s
            d.polygon([(x, s * 0.4), (x + s * 0.03, s * 0.45), (x, s * 0.5), (x - s * 0.03, s * 0.45)], fill=(255, 215, 60), outline=OUTLINE)
    return layer


def glow(img, layer, pos, color, radius):
    alpha = layer.split()[3]
    g = Image.new("RGBA", layer.size, color + (0,))
    g.putalpha(alpha)
    g = g.filter(ImageFilter.GaussianBlur(radius))
    for _ in range(2):
        img.alpha_composite(g, pos)


def paste_hand(img, color, center, size, angle, kind="normal", glow_color=None):
    layer = hand_layer(size, color, kind).rotate(angle, resample=Image.BICUBIC, expand=True)
    pos = (int(center[0] - layer.width / 2), int(center[1] - layer.height / 2))
    if glow_color:
        glow(img, layer, pos, glow_color, size * 0.06)
    img.alpha_composite(layer, pos)


def burst(img, center, r, text, fill=(255, 230, 60), text_color=(255, 70, 140), points=14, rot=0):
    d = ImageDraw.Draw(img)
    cx, cy = center
    pts = []
    for i in range(points * 2):
        a = i / (points * 2) * 2 * math.pi + rot
        rr = r if i % 2 == 0 else r * 0.68
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    d.polygon(pts, fill=fill, outline=OUTLINE, width=max(4, int(r * 0.05)))
    f = font(FONT_BLACK, r * 0.5)
    d.text((cx, cy), text, font=f, fill=text_color, anchor="mm", stroke_width=max(3, int(r * 0.05)), stroke_fill=OUTLINE)


def motion_lines(img, start, direction, count, length, spread, width, color=(255, 255, 255, 230)):
    d = ImageDraw.Draw(img)
    dx, dy = direction
    n = math.hypot(dx, dy)
    dx, dy = dx / n, dy / n
    px, py = -dy, dx
    for i in range(count):
        off = (i - (count - 1) / 2) * spread
        sx, sy = start[0] + px * off, start[1] + py * off
        l = length * (0.6 + 0.4 * ((i * 37) % 10) / 10)
        d.line([(sx, sy), (sx - dx * l, sy - dy * l)], fill=color, width=width)


def title(img, xy, text, size, fill, anchor="la", stroke=None, path=FONT_BLACK):
    d = ImageDraw.Draw(img)
    f = font(path, size)
    st = stroke if stroke is not None else max(4, int(size * 0.09))
    # drop shadow
    d.text((xy[0] + size * 0.05, xy[1] + size * 0.07), text, font=f, fill=(30, 10, 40), anchor=anchor, stroke_width=st, stroke_fill=(30, 10, 40))
    d.text(xy, text, font=f, fill=fill, anchor=anchor, stroke_width=st, stroke_fill=OUTLINE)


def pill(img, center, text, size, bg, fg=(255, 255, 255)):
    d = ImageDraw.Draw(img)
    f = font(FONT_BLACK, size)
    box = d.textbbox((0, 0), text, font=f)
    w, h = box[2] - box[0], box[3] - box[1]
    pad = size * 0.5
    x0, y0 = center[0] - w / 2 - pad, center[1] - h / 2 - pad * 0.7
    x1, y1 = center[0] + w / 2 + pad, center[1] + h / 2 + pad * 0.7
    d.rounded_rectangle([x0 + size * 0.08, y0 + size * 0.12, x1 + size * 0.08, y1 + size * 0.12], radius=(y1 - y0) / 2, fill=(30, 10, 40))
    d.rounded_rectangle([x0, y0, x1, y1], radius=(y1 - y0) / 2, fill=bg, outline=OUTLINE, width=max(3, int(size * 0.12)))
    d.text(center, text, font=f, fill=fg, anchor="mm")


def sparkles(img, rng, area, count, size):
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = area
    for _ in range(count):
        x, y = rng.uniform(x0, x1), rng.uniform(y0, y1)
        s = rng.uniform(size * 0.4, size)
        d.polygon([(x, y - s), (x + s * 0.25, y - s * 0.25), (x + s, y), (x + s * 0.25, y + s * 0.25), (x, y + s),
                   (x - s * 0.25, y + s * 0.25), (x - s, y), (x - s * 0.25, y - s * 0.25)], fill=(255, 255, 220, 230))


def finish(img, size, name):
    img = img.convert("RGB").resize(size, Image.LANCZOS)
    path = OUT / name
    img.save(path, optimize=True)
    print("Written:", path)


# ---------------------------------------------------------------- icon
def make_icon():
    W = H = 512 * SS
    img = background(W, H, (255, 120, 190), (140, 70, 230), (255, 255, 255, 38), (W * 0.62, H * 0.42))
    rng = random.Random(3)
    sparkles(img, rng, (0, 0, W, H * 0.5), 10, W * 0.025)
    draw_blob(img, W * 0.42, H * 0.58, W * 0.66, (255, 125, 170), accessory="bow")
    motion_lines(img, (W * 0.84, H * 0.42), (1, -0.9), 4, W * 0.14, W * 0.045, int(W * 0.016))
    paste_hand(img, (255, 205, 170), (W * 0.72, H * 0.27), int(W * 0.46), 38)
    burst(img, (W * 0.71, H * 0.6), W * 0.17, "SLAP!", rot=0.1)
    # frame
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([W * 0.012, H * 0.012, W * 0.988, H * 0.988], radius=W * 0.08, outline=(255, 255, 255), width=int(W * 0.018))
    finish(img, (512, 512), "icon.png")


# ---------------------------------------------------------------- thumbnail 1
def make_thumb1():
    W, H = 1920 * SS, 1080 * SS
    img = background(W, H, (120, 200, 255), (255, 140, 200), (255, 255, 255, 34), (W * 0.7, H * 0.45), rays=22)
    d = ImageDraw.Draw(img)
    # ground
    d.ellipse([-W * 0.2, H * 0.8, W * 1.2, H * 1.6], fill=(105, 200, 105), outline=OUTLINE, width=8)
    rng = random.Random(7)
    for _ in range(18):
        x = rng.uniform(0, W)
        y = rng.uniform(H * 0.86, H)
        c = rng.choice([(255, 90, 140), (255, 220, 60), (160, 120, 255), (255, 255, 255)])
        d.ellipse([x - 14, y - 14, x + 14, y + 14], fill=c, outline=OUTLINE, width=3)
    sparkles(img, rng, (W * 0.45, 0, W, H * 0.4), 16, W * 0.012)
    # big gyatt + small gyatt
    draw_blob(img, W * 0.93, H * 0.8, H * 0.26, (130, 220, 110), shocked=False)
    draw_blob(img, W * 0.73, H * 0.58, H * 0.6, (255, 125, 170), accessory="crown")
    motion_lines(img, (W * 0.5, H * 0.42), (-0.6, -1), 5, H * 0.16, H * 0.05, int(H * 0.012))
    paste_hand(img, (220, 170, 40), (W * 0.52, H * 0.3), int(H * 0.5), 28, kind="thanos", glow_color=(170, 90, 255))
    burst(img, (W * 0.6, H * 0.62), H * 0.13, "SLAP!", rot=0.2)
    # damage numbers
    title(img, (W * 0.9, H * 0.14), "-1.2M", H * 0.075, (255, 255, 255), anchor="mm")
    title(img, (W * 0.92, H * 0.3), "CRIT!", H * 0.07, (255, 220, 60), anchor="mm")
    title(img, (W * 0.47, H * 0.82), "+50K", H * 0.06, (140, 255, 160), anchor="mm")
    # title
    title(img, (W * 0.04, H * 0.06), "SLAP THE", H * 0.15, (255, 255, 255))
    title(img, (W * 0.04, H * 0.22), "BLOB!", H * 0.22, (255, 90, 170))
    pill(img, (W * 0.2, H * 0.58), "6 WORLDS", H * 0.05, (70, 170, 255))
    pill(img, (W * 0.2, H * 0.7), "28 PETS", H * 0.05, (60, 200, 100))
    pill(img, (W * 0.2, H * 0.82), "LEGENDARY HANDS", H * 0.05, (160, 90, 255))
    finish(img, (1920, 1080), "thumbnail_1.png")


# ---------------------------------------------------------------- thumbnail 2
def make_thumb2():
    W, H = 1920 * SS, 1080 * SS
    img = background(W, H, (35, 15, 70), (150, 40, 140), (255, 230, 150, 26), (W * 0.5, H * 0.55), rays=26)
    rng = random.Random(11)
    d = ImageDraw.Draw(img)
    for _ in range(140):
        x, y = rng.uniform(0, W), rng.uniform(0, H)
        r = rng.uniform(1.5, 5)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 230))
    # lightning bolt behind the ultra god hand
    bx = W * 0.73
    bolt = [(bx - 40, 0), (bx + 60, 0), (bx + 10, H * 0.32), (bx + 110, H * 0.32), (bx - 90, H * 0.85), (bx - 20, H * 0.44), (bx - 120, H * 0.44)]
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow_layer).polygon(bolt, fill=(255, 250, 180, 255))
    img.alpha_composite(glow_layer.filter(ImageFilter.GaussianBlur(40)))
    ImageDraw.Draw(img).polygon(bolt, fill=(255, 250, 200), outline=OUTLINE, width=8)
    sparkles(img, rng, (0, H * 0.25, W, H), 24, W * 0.012)
    paste_hand(img, (220, 170, 40), (W * 0.28, H * 0.58), int(H * 0.72), 12, kind="thanos", glow_color=(170, 90, 255))
    paste_hand(img, (255, 250, 220), (W * 0.72, H * 0.58), int(H * 0.78), -12, kind="ultragod", glow_color=(255, 240, 150))
    title(img, (W * 0.5, H * 0.1), "LEGENDARY HANDS", H * 0.12, (255, 220, 70), anchor="mm")
    title(img, (W * 0.28, H * 0.93), "TITAN GAUNTLET", H * 0.062, (200, 140, 255), anchor="mm")
    title(img, (W * 0.72, H * 0.93), "ULTRA GOD HAND", H * 0.062, (255, 245, 170), anchor="mm")
    burst(img, (W * 0.12, H * 0.3), H * 0.1, "SNAP!", fill=(190, 120, 255), text_color=(255, 255, 255), rot=0.3)
    burst(img, (W * 0.9, H * 0.28), H * 0.11, "x2500", fill=(255, 230, 60), text_color=(255, 70, 140), rot=0.1)
    finish(img, (1920, 1080), "thumbnail_2.png")


# ---------------------------------------------------------------- game pass icons
def make_pass_icon(name, hand_kind, hand_color, top, bottom, glow_color, label, label_color):
    W = H = 512 * SS
    img = background(W, H, top, bottom, (255, 255, 255, 30), (W * 0.5, H * 0.48), rays=20)
    rng = random.Random(hash(name) % 1000)
    sparkles(img, rng, (W * 0.15, H * 0.12, W * 0.85, H * 0.6), 9, W * 0.025)
    paste_hand(img, hand_color, (W * 0.5, H * 0.46), int(W * 0.62), 0, kind=hand_kind, glow_color=glow_color)
    # label in the lower middle (stays inside the circle crop)
    pill(img, (W * 0.5, H * 0.8), label, H * 0.07, label_color)
    finish(img, (512, 512), name)


def make_pass_icons():
    make_pass_icon("pass_titan.png", "thanos", (220, 170, 40), (60, 20, 110), (150, 50, 200), (170, 90, 255), "TITAN", (150, 70, 230))
    make_pass_icon("pass_ultragod.png", "ultragod", (255, 250, 220), (255, 200, 80), (230, 90, 200), (255, 240, 150), "ULTRA GOD", (235, 160, 30))


if __name__ == "__main__":
    make_icon()
    make_thumb1()
    make_thumb2()
    make_pass_icons()
