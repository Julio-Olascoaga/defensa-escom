"""Placeholder art for Block 10 (v1.4): builds the "vista desarmada" sheets of the
seven characters from the fixed 1.0 images, so the cut-out pipeline and the
puppets work before the real art (tandas 1-2) arrives.

For each character it cuts the 1.0 image into pieces (simple rules per
character, below), draws the damage programmatically (cracks, chipped bits,
soot) and lays the pieces out on a flat green background, 48 px apart, in
three sheets: intacto.png, danado.png, critico.png. It also writes parts.txt
(the names of the pieces in reading order) and assembly.json (where each piece
goes in the assembled character, used only to place the placeholder puppets).

Then tools/cut_parts.py cuts those sheets exactly like it will cut the real ones.

Usage (from the project root, Pillow installed: pip install pillow):
    python tools/make_placeholder_sheets.py
"""

import json
import math
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "tools", "art_src")
KEY = (0, 255, 0, 255)  # flat green background
GAP = 48                # pixels between pieces (the cutter needs at least 40)
MARGIN = 48

STAGES = ["intacto", "danado", "critico"]


# --- Cut rules: (x, y, rgba) of the 1.0 image -> piece name, a tuple of names
# (the pixel goes to several pieces) or None (dropped) ---

def inside(poly, x, y):
    """Point in polygon (ray casting)."""
    hit = False
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            hit = not hit
    return hit


def cut_cafe(x, y, p):
    if y < 54:
        return None  # the 1.0 steam: the puppet uses particles instead
    if y >= 229:
        return "leg_l" if x < 158 else "leg_r"
    if x < 70 and y > 100:
        return "handle"
    return "body"


def cut_laptop(x, y, p):
    return "lid" if y < 156 and x >= 74 else "base"


FIREWALL_BRICKS = [(64, 68), (194, 68), (193, 168), (128, 222), (64, 168)]


def firewall_top(x):
    """Upper edge of the shield: the flames are above it."""
    return 78 - (x - 30) * 38 / 98 if x < 128 else 40 + (x - 128) * 38 / 98


def cut_firewall(x, y, p):
    if y < firewall_top(x) - 2:
        return "flames"
    if inside(FIREWALL_BRICKS, x, y):
        # the frame keeps the bricks too (an under-layer): when the bricks
        # "breathe" or get hit, no hole appears behind them
        return ("frame", "bricks")
    return "frame"


def cut_tarea(x, y, p):
    if y >= 222:
        return "leg_l" if x < 120 else "leg_r"
    if y < 62:
        return "armor"  # the pile on top: lost when armor_health runs out
    return "body"


SORPRESA_BODY = [(54, 6), (198, 2), (200, 199), (60, 199)]


def cut_sorpresa(x, y, p):
    if inside(SORPRESA_BODY, x, y):
        return "body"
    if y >= 170:
        return "leg_l" if x < 125 else "leg_r"
    return "arm_l" if x < 128 else "arm_r"


def cut_diapositivas(x, y, p):
    if y >= 212:
        return "leg_l" if x < 128 else "leg_r"
    return "body"


def cut_examen_final(x, y, p):
    if y < 90 and 196 < x < 320:
        return "clock"
    if y >= 422:
        return "leg_l" if x < 280 else "leg_r"
    if x < 132:
        return "arm_pen"
    return "body"


# name -> (1.0 image, cut rule, pieces in reading order)
CHARACTERS = {
    "cafe": ("art/defenders/cafe.png", cut_cafe, ["body", "handle", "leg_l", "leg_r"]),
    "laptop": ("art/defenders/laptop.png", cut_laptop, ["lid", "base"]),
    "firewall": ("art/defenders/firewall.png", cut_firewall, ["flames", "frame", "bricks"]),
    "tarea_infinita": ("art/enemies/tarea_infinita.png", cut_tarea, ["body", "armor", "leg_l", "leg_r"]),
    "examen_sorpresa": ("art/enemies/examen_sorpresa.png", cut_sorpresa, ["body", "arm_l", "arm_r", "leg_l", "leg_r"]),
    "diapositivas": ("art/enemies/diapositivas.png", cut_diapositivas, ["body", "leg_l", "leg_r"]),
    "examen_final": ("art/enemies/examen_final.png", cut_examen_final, ["body", "clock", "arm_pen", "leg_l", "leg_r"]),
}


# --- Damage drawn by code ---

def edge_points(alpha):
    """Pixels of the piece that touch transparency (where cracks and chips start)."""
    w, h = alpha.size
    a = alpha.load()
    pts = []
    for y in range(1, h - 1, 2):
        for x in range(1, w - 1, 2):
            if a[x, y] > 200 and (a[x - 2 if x > 1 else 0, y] < 50 or a[min(x + 2, w - 1), y] < 50
                                  or a[x, y - 2 if y > 1 else 0] < 50 or a[x, min(y + 2, h - 1)] < 50):
                pts.append((x, y))
    return pts


def damage(piece, stage, seed):
    """stage 0 = intact, 1 = damaged, 2 = critical. Same seed -> the damage of
    stage 2 contains the damage of stage 1 (the cracks only grow)."""
    if stage == 0:
        return piece.copy()
    rng = random.Random(seed)
    w, h = piece.size
    alpha = piece.getchannel("A")
    pts = edge_points(alpha) or [(w // 2, h // 2)]
    size = max(w, h)
    cracks = max(3, size // 70) * stage
    chips = stage * max(2, size // 100)

    out = piece.copy()
    # darker and a bit greyer, like dirt
    dark = Image.new("RGBA", (w, h), (40, 22, 30, 255))
    out = Image.blend(out, dark, 0.12 * stage)
    out.putalpha(alpha)

    over = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    # soot spots (critical only)
    if stage >= 1:
        for _ in range((3 + size // 80) * stage - 2):
            cx, cy = rng.randrange(w), rng.randrange(h)
            r = rng.randint(size // 16 + 2, size // 8 + 4)
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(25, 15, 20, 70))
    # cracks: jagged lines that start on the border and go inwards
    for _ in range(cracks):
        x, y = rng.choice(pts)
        ang = math.atan2(h / 2 - y, w / 2 - x) + rng.uniform(-0.7, 0.7)
        line = [(x, y)]
        for _ in range(rng.randint(4, 7)):
            step = rng.uniform(size * 0.04, size * 0.09)
            ang += rng.uniform(-0.6, 0.6)
            x += math.cos(ang) * step
            y += math.sin(ang) * step
            line.append((x, y))
        d.line(line, fill=(35, 18, 25, 255), width=max(4, size // 45))
        d.line([(px + 2, py + 2) for px, py in line], fill=(255, 255, 255, 70), width=2)
    over.putalpha(Image.composite(over.getchannel("A"), Image.new("L", (w, h), 0), alpha))
    out.alpha_composite(over)

    # chipped bits: triangles cut out of the border
    a = out.getchannel("A")
    da = ImageDraw.Draw(a)
    for _ in range(chips):
        x, y = rng.choice(pts)
        r = rng.randint(size // 22 + 3, size // 12 + 5) * (1 + 0.5 * (stage - 1))
        da.polygon([(x + rng.uniform(-r, r), y + rng.uniform(-r, r)) for _ in range(3)], fill=0)
    out.putalpha(a)
    return out


# --- Sheets ---

def split(path, rule, names):
    src = Image.open(os.path.join(ROOT, path)).convert("RGBA")
    w, h = src.size
    sp = src.load()
    layers = {n: Image.new("RGBA", (w, h), (0, 0, 0, 0)) for n in names}
    lp = {n: layers[n].load() for n in names}
    for y in range(h):
        for x in range(w):
            p = sp[x, y]
            if p[3] == 0:
                continue
            n = rule(x, y, p)
            for name in (n if isinstance(n, tuple) else (n,)):
                if name is not None:
                    lp[name][x, y] = p
    pieces = {}
    for n in names:
        box = layers[n].getbbox()
        if box is None:
            raise SystemExit("%s: piece %s is empty" % (path, n))
        pieces[n] = (layers[n].crop(box), box)
    return src.size, pieces


def build(name):
    path, rule, names = CHARACTERS[name]
    size, pieces = split(path, rule, names)
    # one row, in the order of parts.txt
    width = MARGIN * 2 + sum(p.size[0] for p, _ in pieces.values()) + GAP * (len(names) - 1)
    height = MARGIN * 2 + max(p.size[1] for p, _ in pieces.values())
    folder = os.path.join(OUT_DIR, name)
    os.makedirs(folder, exist_ok=True)
    for stage, stage_name in enumerate(STAGES):
        sheet = Image.new("RGBA", (width, height), KEY)
        x = MARGIN
        for i, n in enumerate(names):
            piece, _ = pieces[n]
            img = damage(piece, stage, seed=sum(map(ord, name + n)))  # fixed seed: same result every run
            # flatten on the key colour, like a painted sheet (no transparency)
            sheet.alpha_composite(img, (x, MARGIN))
            x += piece.size[0] + GAP
        sheet.convert("RGB").save(os.path.join(folder, stage_name + ".png"), optimize=True)
    with open(os.path.join(folder, "parts.txt"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(names) + "\n")
    assembly = {"source": path, "size": list(size),
                "parts": {n: list(box) for n, (_, box) in pieces.items()}}
    with open(os.path.join(folder, "assembly.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(assembly, f, indent=1)
        f.write("\n")
    print("%-16s %d pieces -> %s" % (name, len(names), os.path.relpath(folder, ROOT)))


if __name__ == "__main__":
    for character in CHARACTERS:
        build(character)
