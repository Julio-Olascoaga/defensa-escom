"""Placeholder art for Block 12 (v1.6): the 4 new cards, the 3 new enemies and
the boss of World 2, drawn by code in the family style of the 1.0 art (flat
colours, thick dark outline, a face), until the real art (tandas 3-4) arrives.

For each character it draws every piece on its own layer, then writes:
  - art/defenders/<name>.png or art/enemies/<name>.png: the assembled
    character (256 x 256, the boss 512 x 512), used by the card bar, the
    Expediente and "¡Nueva carta!" (DefenderType/EnemyType.texture);
  - tools/art_src/<name>/intacto.png, danado.png, critico.png, parts.txt and
    assembly.json: the "vista desarmada" sheets, the same as
    tools/make_placeholder_sheets.py makes for the World 1 characters (the
    damage is drawn by its damage() function).
Then tools/cut_parts.py cuts the sheets into art/characters/<name>/.

No text inside the images (plan, section 7.1): Ctrl+Z is an "undo" arrow.

Usage (from the project root, Pillow installed):
    python tools/art_src/make_world2_placeholders.py
    python tools/cut_parts.py tools/art_src/<name>      (for each new character)
"""

import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.dirname(HERE))
from make_placeholder_sheets import GAP, KEY, MARGIN, STAGES, damage  # noqa: E402

SS = 4  # supersampling: drawn 4 times bigger, then reduced (soft edges)
INK = (43, 27, 46, 255)  # the dark outline of the 1.0 art
WHITE = (255, 255, 255, 255)


class Piece:
    """One layer of a character, drawn in the coordinates of the final image."""

    def __init__(self, size):
        self.size = size
        self.img = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    @staticmethod
    def _s(points):
        return [(x * SS, y * SS) for x, y in points]

    def rrect(self, box, r, fill, w=4.5):
        x0, y0, x1, y1 = box
        self.d.rounded_rectangle([x0 * SS, y0 * SS, x1 * SS, y1 * SS], r * SS, fill=fill,
                                 outline=INK if w else None, width=int(w * SS))

    def ellipse(self, box, fill, w=4.5):
        x0, y0, x1, y1 = box
        self.d.ellipse([x0 * SS, y0 * SS, x1 * SS, y1 * SS], fill=fill,
                       outline=INK if w else None, width=int(w * SS))

    def poly(self, points, fill, w=4.5):
        pts = self._s(points)
        self.d.polygon(pts, fill=fill)
        if w:
            self.d.line(pts + [pts[0]], fill=INK, width=int(w * SS), joint="curve")

    def line(self, points, fill=INK, w=4.5):
        self.d.line(self._s(points), fill=fill, width=int(w * SS), joint="curve")

    def arc(self, box, start, end, fill=INK, w=4.5):
        x0, y0, x1, y1 = box
        self.d.arc([x0 * SS, y0 * SS, x1 * SS, y1 * SS], start, end, fill=fill, width=int(w * SS))

    def final(self):
        return self.img.resize((self.size, self.size), Image.LANCZOS)


# --- Faces (eyes look right on defenders, left on enemies) ---

def eyes(p, cx, cy, gap, r, look, mood="angry", lid=False):
    for side in (-1, 1):
        ex = cx + side * gap
        p.ellipse([ex - r, cy - r * 1.15, ex + r, cy + r * 1.15], WHITE, 3)
        pr = r * 0.55
        px = ex + look * r * 0.35
        p.ellipse([px - pr, cy - pr + 2, px + pr, cy + pr + 2], INK, 0)
        p.ellipse([px - pr * 0.35 + 2, cy - pr * 0.6, px + pr * 0.35 + 2, cy - pr * 0.6 + pr * 0.7], WHITE, 0)
        if lid:  # half-closed eyelids: sleepy / slow
            p.d.chord([(ex - r) * SS, (cy - r * 1.15) * SS, (ex + r) * SS, (cy + r * 1.15) * SS],
                      180, 360, fill=lid, outline=INK, width=int(3 * SS))
        if mood == "angry":
            p.line([(ex - r * 1.1, cy - r * 1.5 - side * r * 0.35), (ex + r * 1.1, cy - r * 1.5 + side * r * 0.35)], w=5)
        elif mood == "worried":
            p.line([(ex - r, cy - r * 1.4 + side * r * 0.4), (ex + r, cy - r * 1.4 - side * r * 0.4)], w=4)


def mouth(p, cx, cy, w, kind="smirk"):
    if kind == "smile":
        p.arc([cx - w, cy - w * 0.6, cx + w, cy + w * 0.6], 20, 160, w=4)
    elif kind == "frown":
        p.arc([cx - w, cy, cx + w, cy + w * 1.0], 200, 340, w=4)
    elif kind == "flat":
        p.line([(cx - w, cy), (cx + w, cy + 2)], w=4)
    elif kind == "open":
        p.ellipse([cx - w * 0.6, cy - w * 0.5, cx + w * 0.6, cy + w * 0.6], (120, 30, 50, 255), 3.5)
    else:  # smirk
        p.line([(cx - w, cy + 3), (cx - w * 0.2, cy + 5), (cx + w, cy - 4)], w=4)


def legs(size, xs, top, bottom, color, shoe=INK, foot=1):
    """Two short legs with shoes. foot = +1 shoes point right, -1 left."""
    out = []
    for x in xs:
        p = Piece(size)
        p.rrect([x - 10, top, x + 10, bottom - 10], 6, color, 4)
        p.ellipse([x - 14 + foot * 6, bottom - 18, x + 16 + foot * 6, bottom], shoe, 3)
        out.append(p)
    return out


# --- Defenders (look right) ---

def usb():
    s = 256
    plug = Piece(s)
    plug.rrect([98, 26, 158, 92], 6, (196, 202, 214, 255))
    plug.rrect([110, 42, 124, 56], 2, (90, 96, 110, 255), 2.5)
    plug.rrect([132, 42, 146, 56], 2, (90, 96, 110, 255), 2.5)
    body = Piece(s)
    body.rrect([68, 84, 188, 226], 26, (61, 127, 217, 255))
    body.rrect([84, 96, 172, 118], 10, (126, 178, 245, 255), 0)  # shine
    body.rrect([92, 186, 164, 206], 8, (242, 179, 61, 255), 3.5)  # the label sticker
    eyes(body, 128 + 8, 146, 20, 12, 1, "none")
    mouth(body, 136, 172, 14, "smile")
    leg_l, leg_r = legs(s, [104, 152], 220, 252, (108, 29, 69, 255), foot=1)
    return {"plug": plug, "body": body, "leg_l": leg_l, "leg_r": leg_r}, \
        ["leg_l", "leg_r", "body", "plug"], ["plug", "body", "leg_l", "leg_r"]


def calculadora():
    s = 256
    body = Piece(s)
    body.rrect([56, 22, 200, 236], 22, (72, 78, 94, 255))
    body.rrect([66, 32, 190, 52], 8, (98, 106, 124, 255), 0)
    colors = [(206, 210, 220, 255), (206, 210, 220, 255), (206, 210, 220, 255), (108, 29, 69, 255)]
    for row in range(4):
        for col in range(4):
            x = 72 + col * 29
            y = 124 + row * 25
            fill = colors[col] if not (row == 3 and col == 3) else (242, 179, 61, 255)
            body.rrect([x, y, x + 22, y + 18], 5, fill, 3)
    screen = Piece(s)
    screen.rrect([70, 42, 186, 112], 10, (186, 224, 160, 255))
    eyes(screen, 128 + 8, 74, 22, 11, 1, "angry")
    mouth(screen, 138, 98, 12, "smirk")
    leg_l, leg_r = legs(s, [100, 156], 230, 254, (108, 29, 69, 255), foot=1)
    return {"body": body, "screen": screen, "leg_l": leg_l, "leg_r": leg_r}, \
        ["leg_l", "leg_r", "body", "screen"], ["screen", "body", "leg_l", "leg_r"]


def router():
    s = 256
    pieces = {}
    for name, x in (("antenna_l", 72), ("antenna_r", 184)):
        a = Piece(s)
        a.rrect([x - 8, 34, x + 8, 150], 7, (60, 56, 70, 255), 4)
        a.ellipse([x - 13, 22, x + 13, 46], (60, 56, 70, 255), 4)
        pieces[name] = a
    body = Piece(s)
    body.poly([(30, 140), (226, 140), (238, 214), (18, 214)], (52, 48, 62, 255))
    body.rrect([24, 196, 232, 230], 10, (40, 36, 48, 255))
    body.rrect([40, 148, 216, 162], 6, (82, 78, 96, 255), 0)  # top shine
    for i, c in enumerate([(57, 229, 140, 255), (57, 229, 140, 255), (242, 179, 61, 255), (230, 70, 70, 255)]):
        x = 52 + i * 22
        body.ellipse([x - 6, 207, x + 6, 219], c, 2.5)
    eyes(body, 170, 178, 18, 11, 1, "none", lid=(52, 48, 62, 255))
    mouth(body, 172, 200, 10, "flat")
    for x in (52, 204):  # rubber feet
        body.rrect([x - 16, 226, x + 16, 240], 5, INK, 0)
    pieces["body"] = body
    return pieces, ["antenna_l", "antenna_r", "body"], ["antenna_l", "antenna_r", "body"]


def ctrl_z():
    s = 256
    key = Piece(s)
    key.rrect([30, 70, 226, 236], 26, (150, 156, 174, 255))  # the side of the key (3D)
    key.rrect([40, 52, 216, 206], 24, (232, 236, 244, 255))  # the top
    eyes(key, 156, 168, 16, 9, 1, "angry")
    mouth(key, 158, 190, 9, "smirk")
    arrow = Piece(s)
    # "undo": a curved arrow that turns back to the left
    arrow.arc([70, 72, 182, 160], 200, 380, fill=INK, w=16)
    arrow.arc([70, 72, 182, 160], 200, 380, fill=(108, 29, 69, 255), w=8)
    arrow.poly([(52, 104), (96, 90), (84, 134)], (108, 29, 69, 255), 4)
    return {"key": key, "arrow": arrow}, ["key", "arrow"], ["key", "arrow"]


# --- Enemies (look left) ---

def bibliografia():
    s = 256
    leg_l, leg_r = legs(s, [100, 150], 214, 254, (60, 40, 50, 255), foot=-1)
    body = Piece(s)
    body.rrect([58, 104, 198, 224], 10, (122, 44, 44, 255))  # a thick hardcover book
    body.rrect([188, 108, 206, 222], 4, (244, 236, 216, 255), 3.5)  # the pages
    for y in (130, 196):
        body.line([(64, y), (192, y)], (212, 170, 80, 255), 4)
    eyes(body, 112, 158, 20, 11, -1, "angry")
    body.line([(90, 158), (134, 158)], INK, 3)  # glasses bridge
    body.ellipse([82, 144, 110, 172], None, 3)
    body.ellipse([114, 144, 142, 172], None, 3)
    mouth(body, 110, 190, 14, "frown")
    armor = Piece(s)  # the pile of overdue books: lost when armor_health runs out
    books = [((56, 82, 204, 106), (60, 110, 158, 255)), ((70, 58, 190, 84), (201, 162, 39, 255)),
             ((50, 34, 196, 60), (47, 125, 79, 255)), ((78, 10, 182, 36), (108, 29, 69, 255))]
    for (x0, y0, x1, y1), c in books:
        armor.rrect([x0, y0, x1, y1], 5, c, 4)
        armor.rrect([x1 - 14, y0 + 5, x1 - 4, y1 - 5], 2, (244, 236, 216, 255), 2)
    arm = Piece(s)
    arm.rrect([34, 92, 60, 168], 12, (60, 40, 50, 255), 4)
    arm.ellipse([28, 80, 62, 108], (242, 214, 190, 255), 4)
    return {"body": body, "armor": armor, "arm": arm, "leg_l": leg_l, "leg_r": leg_r}, \
        ["leg_l", "leg_r", "body", "armor", "arm"], ["armor", "body", "arm", "leg_l", "leg_r"]


def proyecto_equipo():
    s = 256
    leg_l, leg_r = legs(s, [100, 156], 212, 254, (60, 40, 50, 255), foot=-1)
    body = Piece(s)  # a trifold project board
    body.poly([(22, 40), (78, 26), (78, 214), (22, 200)], (228, 214, 180, 255))
    body.poly([(178, 26), (234, 40), (234, 200), (178, 214)], (228, 214, 180, 255))
    body.rrect([74, 22, 182, 218], 6, (244, 236, 216, 255))
    for (x, y, c) in ((34, 70, (255, 214, 102, 255)), (196, 64, (126, 214, 245, 255)),
                      (40, 150, (245, 140, 170, 255)), (192, 146, (160, 230, 140, 255))):
        body.rrect([x, y, x + 26, y + 26], 3, c, 3)  # sticky notes
    eyes(body, 124, 96, 22, 12, -1, "worried")
    mouth(body, 124, 140, 16, "open")
    arms = {}
    for name, x in (("arm_l", 12), ("arm_r", 226)):
        a = Piece(s)
        a.rrect([x, 110, x + 20, 178], 10, (60, 40, 50, 255), 4)
        a.ellipse([x - 4, 170, x + 24, 196], (242, 214, 190, 255), 4)
        arms[name] = a
    return {"body": body, "arm_l": arms["arm_l"], "arm_r": arms["arm_r"], "leg_l": leg_l, "leg_r": leg_r}, \
        ["leg_l", "leg_r", "arm_r", "body", "arm_l"], ["body", "arm_l", "arm_r", "leg_l", "leg_r"]


def retardo():
    s = 256
    leg_l, leg_r = legs(s, [104, 152], 196, 254, (40, 60, 110, 255), foot=-1)
    bells = Piece(s)
    for cx in (84, 172):
        bells.d.chord([(cx - 26) * SS, 14 * SS, (cx + 26) * SS, 66 * SS], 180, 360,
                      fill=(242, 179, 61, 255), outline=INK, width=int(4.5 * SS))
    bells.rrect([120, 20, 136, 46], 4, (242, 179, 61, 255), 3.5)
    body = Piece(s)  # an alarm clock that is always late
    body.ellipse([44, 40, 212, 208], (232, 116, 59, 255))
    body.ellipse([64, 60, 192, 188], (250, 244, 228, 255), 4)
    body.line([(128, 124), (128, 80)], INK, 5)  # hands: always "tarde"
    body.line([(128, 124), (160, 140)], INK, 5)
    eyes(body, 112, 112, 20, 10, -1, "worried")
    mouth(body, 110, 160, 13, "open")
    body.ellipse([168, 82, 180, 98], (126, 214, 245, 255), 2)  # a drop of sweat
    arms = {}
    for name, x, y in (("arm_l", 22, 104), ("arm_r", 206, 112)):
        a = Piece(s)
        a.rrect([x, y, x + 22, y + 56], 11, (40, 60, 110, 255), 4)
        a.ellipse([x - 3, y + 48, x + 25, y + 74], (242, 214, 190, 255), 4)
        arms[name] = a
    return {"body": body, "bells": bells, "arm_l": arms["arm_l"], "arm_r": arms["arm_r"], "leg_l": leg_l, "leg_r": leg_r}, \
        ["leg_l", "leg_r", "arm_r", "body", "bells", "arm_l"], ["bells", "body", "arm_l", "arm_r", "leg_l", "leg_r"]


def profesora():
    s = 512
    purple = (74, 44, 107, 255)
    leg_l, leg_r = [], []
    for x, out in ((214, leg_l), (300, leg_r)):
        p = Piece(s)
        p.rrect([x - 16, 400, x + 16, 486], 10, (50, 30, 70, 255), 5)
        p.poly([(x - 34, 486), (x + 18, 478), (x + 22, 504), (x - 34, 504)], (108, 29, 69, 255), 4.5)  # heels
        out.append(p)
    body = Piece(s)  # the final project: a huge binder with glasses
    body.rrect([120, 110, 400, 420], 22, purple, 6)
    body.rrect([380, 120, 412, 410], 10, (244, 236, 216, 255), 5)  # pages
    for y in (150, 265, 380):  # the rings
        body.ellipse([108, y - 12, 136, y + 12], (200, 200, 214, 255), 4)
    for (x, y) in ((128, 118), (372, 118), (128, 392), (372, 392)):
        body.rrect([x - 10, y - 10, x + 18, y + 18], 4, (242, 179, 61, 255), 3.5)  # gold corners
    eyes(body, 240, 220, 42, 20, -1, "angry")
    for side in (-1, 1):  # round glasses
        body.ellipse([240 + side * 42 - 30, 190, 240 + side * 42 + 30, 250], None, 6)
    body.line([(222, 218), (258, 218)], INK, 6)
    mouth(body, 236, 300, 30, "frown")
    body.ellipse([152, 270, 190, 296], (236, 150, 170, 255), 0)  # cheeks
    bun = Piece(s)  # her hair bun with a pencil through it
    bun.ellipse([196, 30, 296, 124], (60, 36, 40, 255), 6)
    bun.line([(170, 50), (322, 104)], INK, 18)
    bun.line([(170, 50), (322, 104)], (242, 179, 61, 255), 10)
    bun.poly([(322, 104), (346, 112), (318, 92)], (244, 214, 190, 255), 4)
    arm = Piece(s)  # the long red pen she grades with
    arm.rrect([60, 200, 132, 250], 22, purple, 5)
    arm.ellipse([44, 196, 92, 248], (242, 214, 190, 255), 5)
    arm.line([(70, 120), (64, 330)], INK, 22)
    arm.line([(70, 120), (64, 330)], (210, 40, 50, 255), 14)
    arm.poly([(56, 330), (74, 330), (64, 360)], (244, 236, 216, 255), 4)
    return {"body": body, "bun": bun, "arm_pen": arm, "leg_l": leg_l[0], "leg_r": leg_r[0]}, \
        ["leg_l", "leg_r", "bun", "body", "arm_pen"], ["body", "bun", "arm_pen", "leg_l", "leg_r"]


# name -> (drawing, folder of the assembled image)
CHARACTERS = {
    "usb": (usb, "art/defenders"),
    "calculadora": (calculadora, "art/defenders"),
    "router": (router, "art/defenders"),
    "ctrl_z": (ctrl_z, "art/defenders"),
    "bibliografia": (bibliografia, "art/enemies"),
    "proyecto_equipo": (proyecto_equipo, "art/enemies"),
    "retardo": (retardo, "art/enemies"),
    "profesora": (profesora, "art/enemies"),
}


def build(name):
    draw, folder = CHARACTERS[name]
    layers, z_order, names = draw()
    finals = {n: layers[n].final() for n in names}
    size = finals[names[0]].size
    whole = Image.new("RGBA", size, (0, 0, 0, 0))
    for n in z_order:
        whole.alpha_composite(finals[n])
    os.makedirs(os.path.join(ROOT, folder), exist_ok=True)
    whole.save(os.path.join(ROOT, folder, name + ".png"), optimize=True)
    pieces = {}
    for n in names:
        box = finals[n].getbbox()
        pieces[n] = (finals[n].crop(box), box)
    width = MARGIN * 2 + sum(p.size[0] for p, _ in pieces.values()) + GAP * (len(names) - 1)
    height = MARGIN * 2 + max(p.size[1] for p, _ in pieces.values())
    out = os.path.join(HERE, name)
    os.makedirs(out, exist_ok=True)
    for stage, stage_name in enumerate(STAGES):
        sheet = Image.new("RGBA", (width, height), KEY)
        x = MARGIN
        for n in names:
            piece, _ = pieces[n]
            sheet.alpha_composite(damage(piece, stage, seed=sum(map(ord, name + n))), (x, MARGIN))
            x += piece.size[0] + GAP
        sheet.convert("RGB").save(os.path.join(out, stage_name + ".png"), optimize=True)
    with open(os.path.join(out, "parts.txt"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(names) + "\n")
    assembly = {"source": "%s/%s.png" % (folder, name), "size": list(size),
                "parts": {n: list(box) for n, (_, box) in pieces.items()}}
    with open(os.path.join(out, "assembly.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(assembly, f, indent=1)
        f.write("\n")
    print("%-16s %d pieces -> %s" % (name, len(names), os.path.relpath(out, ROOT)))


if __name__ == "__main__":
    for character in (sys.argv[1:] or CHARACTERS):
        build(character)
