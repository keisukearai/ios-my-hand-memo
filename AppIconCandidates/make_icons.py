"""MyHandMemo のアプリアイコン候補を 3 種類描き出す。

Theme.swift の色をそのまま使う。線は「点を並べて太さを変える」方式で、
書き始め／書き終わりを細くして手書きらしいテーパーを作る。
4 倍で描いてから縮小してアンチエイリアスをかける。
"""

import math
import os

from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
SIZE = 1024
SS = 4  # supersampling
C = SIZE * SS

# Theme.swift より
BG = (0xF6, 0xF3, 0xED)          # background
SURFACE = (0xFF, 0xFC, 0xF6)     # surface
PAPER_LINE = (0xDD, 0xD6, 0xC8)  # paperLine
ACCENT = (0x2F, 0x4F, 0xA0)      # accent
INK = (0x22, 0x1F, 0x1B)         # ink
SEPARATOR = (0xE2, 0xDC, 0xD1)
GROUPED = (0xF1, 0xEE, 0xE7)


def bezier(p0, p1, p2, p3, t):
    u = 1 - t
    x = u * u * u * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t * t * t * p3[0]
    y = u * u * u * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t * t * t * p3[1]
    return x, y


def sample(segments, per_seg=400):
    """cubic bezier の連なりを点列にする"""
    pts = []
    for seg in segments:
        for i in range(per_seg + 1):
            if i == 0 and pts:
                continue
            pts.append(bezier(*seg, i / per_seg))
    return pts


def taper(t, head=0.16, tail=0.22, floor=0.35):
    """書き始めと書き終わりを細くする係数"""
    a = min(1.0, t / head) if head > 0 else 1.0
    b = min(1.0, (1 - t) / tail) if tail > 0 else 1.0
    k = min(a, b)
    return floor + (1 - floor) * (k ** 0.6)


def stroke(draw, segments, width, color, head=0.16, tail=0.22, floor=0.35):
    pts = sample(segments)
    n = len(pts)
    for i, (x, y) in enumerate(pts):
        r = width * taper(i / (n - 1), head, tail, floor) / 2
        draw.ellipse((x - r, y - r, x + r, y + r), fill=color)


def scribble(cx, cy, w, h):
    """走り書きの一筆。左から右へ、山と谷を繰り返す"""
    x0, x1 = cx - w / 2, cx + w / 2
    span = w
    return [
        ((x0, cy + h * 0.30),
         (x0 + span * 0.08, cy - h * 0.55),
         (x0 + span * 0.26, cy - h * 0.62),
         (x0 + span * 0.32, cy + h * 0.10)),
        ((x0 + span * 0.32, cy + h * 0.10),
         (x0 + span * 0.38, cy + h * 0.72),
         (x0 + span * 0.52, cy + h * 0.60),
         (x0 + span * 0.56, cy - h * 0.18)),
        ((x0 + span * 0.56, cy - h * 0.18),
         (x0 + span * 0.61, cy - h * 0.74),
         (x0 + span * 0.74, cy - h * 0.60),
         (x0 + span * 0.78, cy + h * 0.02)),
        ((x0 + span * 0.78, cy + h * 0.02),
         (x0 + span * 0.83, cy + h * 0.52),
         (x0 + span * 0.94, cy + h * 0.34),
         (x1, cy - h * 0.28)),
    ]


def underline(cx, cy, w):
    """走り書きの下に引く、軽く反った線"""
    x0, x1 = cx - w / 2, cx + w / 2
    return [((x0, cy), (x0 + w * 0.3, cy + w * 0.055),
             (x0 + w * 0.7, cy + w * 0.055), (x1, cy))]


def new_canvas(bg):
    img = Image.new("RGB", (C, C), bg)
    return img, ImageDraw.Draw(img)


def finish(img, name):
    out = img.resize((SIZE, SIZE), Image.LANCZOS)
    path = os.path.join(OUT, f"{name}.png")
    out.save(path)
    return out, path


# ---------------------------------------------------------------- A: 走り書き
def icon_a():
    img, d = new_canvas(BG)
    cx = cy = C / 2
    stroke(d, scribble(cx, cy - C * 0.055, C * 0.62, C * 0.20), C * 0.085, ACCENT)
    stroke(d, underline(cx, cy + C * 0.20, C * 0.62), C * 0.024,
           PAPER_LINE, head=0.04, tail=0.06, floor=0.85)
    return finish(img, "A_scribble")


# ------------------------------------------------------------------ B: 紙と線
def icon_b():
    img, d = new_canvas(SEPARATOR)
    # 紙を1枚置く
    m = C * 0.13
    r = C * 0.055
    d.rounded_rectangle((m, m, C - m, C - m), radius=r, fill=SURFACE, outline=SEPARATOR,
                        width=int(C * 0.006))
    # 罫線
    top, bottom = m + C * 0.34, C - m - C * 0.10
    rows = 3
    for i in range(rows):
        y = top + (bottom - top) * i / (rows - 1)
        d.rounded_rectangle((m + C * 0.075, y, C - m - C * 0.075, y + C * 0.007),
                            radius=C * 0.004, fill=PAPER_LINE)
    # その上に走り書き
    stroke(d, scribble(C / 2, C * 0.40, C * 0.52, C * 0.15), C * 0.068, ACCENT)
    return finish(img, "B_paper")


# ------------------------------------------------------------------ C: 藍ベタ
def icon_c():
    img, d = new_canvas(ACCENT)
    cx = cy = C / 2
    stroke(d, scribble(cx, cy, C * 0.60, C * 0.22), C * 0.105, BG, floor=0.40)
    # 書き始めの点
    r = C * 0.030
    x0 = cx - C * 0.30 - C * 0.048
    d.ellipse((x0 - r, cy + C * 0.075 - r, x0 + r, cy + C * 0.075 + r), fill=BG)
    return finish(img, "C_ink")


# ------------------------------------------------------ 実サイズの見え方を並べる
def squircle_mask(size, n=5.0):
    ss = 4
    s = size * ss
    mask = Image.new("L", (s, s), 0)
    px = mask.load()
    half = s / 2
    for y in range(s):
        vy = abs((y + 0.5 - half) / half) ** n
        for x in range(s):
            vx = abs((x + 0.5 - half) / half) ** n
            if vx + vy <= 1.0:
                px[x, y] = 255
    return mask.resize((size, size), Image.LANCZOS)


def contact_sheet(items):
    """ホーム画面くらいの大きさ（180px）で 3 案を並べる"""
    tile, gap, pad, label_h = 180, 56, 56, 42
    w = pad * 2 + tile * 3 + gap * 2
    h = pad * 2 + tile + label_h
    sheet = Image.new("RGB", (w, h), (0xE9, 0xE4, 0xDA))
    d = ImageDraw.Draw(sheet)
    mask = squircle_mask(tile)
    for i, (img, name) in enumerate(items):
        x = pad + i * (tile + gap)
        small = img.resize((tile, tile), Image.LANCZOS)
        sheet.paste(small, (x, pad), mask)
        d.text((x + tile / 2, pad + tile + 14), name, fill=INK, anchor="ma")
    path = os.path.join(OUT, "_compare.png")
    sheet.save(path)
    return path


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    made = []
    for fn, label in ((icon_a, "A  Scribble"), (icon_b, "B  Paper"), (icon_c, "C  Ink")):
        img, path = fn()
        made.append((img, label))
        print(path)
    print(contact_sheet(made))
