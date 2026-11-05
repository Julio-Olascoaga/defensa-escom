"""Cut-out pipeline of Block 10 (v1.4): turns a character drawn in "vista
desarmada" into the part strips the puppets use.

Input: a folder with three sheets of the SAME layout (draw the damaged ones on
top of a copy of the intact one, so every piece stays in its place):
    intacto.png   danado.png   critico.png
Each sheet has the pieces of the character on a flat background of one colour
(pure green #00FF00 or magenta #FF00FF; it is read from the top-left pixel),
at least 40 px apart. Optional parts.txt: the name of each piece, one per line,
in reading order (rows from top to bottom, left to right inside a row).

Output: art/characters/<character>/<piece>.png, one PNG strip per piece with
3 frames side by side (intact | damaged | critical), all frames the same size.
In Godot the Sprite2D of the piece uses hframes = 3 and CharacterVisual
chooses the frame (set_damage_stage).

How it works: chroma key (distance to the background colour -> transparency,
with soft edges and spill removal), then the bounding box of every piece:
the opaque pixels are grown by ~18 px so that bits of one piece closer than
40 px join, and each connected group is one piece. The three sheets are cut
with the same rectangle per piece (the union of the three boxes).

Usage (Pillow: pip install pillow):
    python tools/cut_parts.py tools/art_src/cafe
    python tools/cut_parts.py tools/art_src/cafe --name cafe --out art/characters
    python tools/cut_parts.py --all          (every folder in tools/art_src)
    python tools/cut_parts.py tools/art_src/cafe --scale 0.25
        (the real sheets are 2048 x 2048: --scale makes the strips smaller, so a
         character is about 256-512 px wide like the 1.0 art; lighter on phones)
"""

import argparse
import os
import sys

from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEETS = ["intacto.png", "danado.png", "critico.png"]
## Colour distance (0-441) under which a pixel is background, and over which it is solid.
KEY_INNER = 60.0
KEY_OUTER = 140.0
## Minimum distance between pieces, in pixels (plan, section 4.3).
MIN_GAP = 40
## Work on a mask reduced this many times (speed); the boxes are exact anyway.
REDUCE = 4
## Pieces smaller than this (in pixels of the sheet) are dust and are ignored.
MIN_PIECE = 6


def key_out(sheet):
    """Chroma key: returns an RGBA image with the background transparent."""
    rgb = sheet.convert("RGB")
    key = rgb.getpixel((0, 0))
    kr, kg, kb = key
    green_key = kg > max(kr, kb)
    px = rgb.load()
    w, h = rgb.size
    out = Image.new("RGBA", (w, h))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            dist = ((r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2) ** 0.5
            if dist <= KEY_INNER:
                op[x, y] = (0, 0, 0, 0)
                continue
            a = 255 if dist >= KEY_OUTER else int(255 * (dist - KEY_INNER) / (KEY_OUTER - KEY_INNER))
            if a < 255:  # spill: the edge still has some of the key colour
                if green_key:
                    g = min(g, max(r, b))
                else:
                    m = min(r, b)
                    r, b = min(r, max(g, m)), min(b, max(g, m))
            op[x, y] = (r, g, b, a)
    return out


def find_boxes(rgba):
    """Bounding boxes of the pieces (pixels closer than MIN_GAP join), in reading order."""
    w, h = rgba.size
    small = rgba.getchannel("A").resize((max(1, w // REDUCE), max(1, h // REDUCE)), Image.BOX)
    small = small.point(lambda v: 255 if v > 8 else 0)
    grow = (MIN_GAP // 2 - 2) // REDUCE  # radius in reduced pixels (< half the gap)
    grown = small.filter(ImageFilter.MaxFilter(grow * 2 + 1)) if grow > 0 else small
    sw, sh = grown.size
    g = grown.load()
    s = small.load()
    seen = bytearray(sw * sh)
    boxes = []
    for y0 in range(sh):
        for x0 in range(sw):
            if g[x0, y0] == 0 or seen[y0 * sw + x0]:
                continue
            stack = [(x0, y0)]
            seen[y0 * sw + x0] = 1
            x1 = y1 = 10 ** 9
            x2 = y2 = -1
            while stack:
                x, y = stack.pop()
                if s[x, y]:  # only the real pixels count for the box, not the grown ones
                    x1, y1, x2, y2 = min(x1, x), min(y1, y), max(x2, x), max(y2, y)
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < sw and 0 <= ny < sh and g[nx, ny] and not seen[ny * sw + nx]:
                        seen[ny * sw + nx] = 1
                        stack.append((nx, ny))
            if x2 < 0:
                continue
            # back to sheet pixels, then shrink to the exact opaque pixels
            box = (max(0, (x1 - 1) * REDUCE), max(0, (y1 - 1) * REDUCE),
                   min(w, (x2 + 2) * REDUCE), min(h, (y2 + 2) * REDUCE))
            exact = rgba.crop(box).getchannel("A").getbbox()
            if exact is None:
                continue
            box = (box[0] + exact[0], box[1] + exact[1], box[0] + exact[2], box[1] + exact[3])
            if box[2] - box[0] >= MIN_PIECE and box[3] - box[1] >= MIN_PIECE:
                boxes.append(box)
    return reading_order(boxes)


def reading_order(boxes):
    """Rows from top to bottom (a box joins a row if it overlaps it vertically), left to right."""
    rows = []
    for box in sorted(boxes, key=lambda b: b[1]):
        for row in rows:
            if box[1] < row["bottom"] and box[3] > row["top"]:
                row["boxes"].append(box)
                row["top"] = min(row["top"], box[1])
                row["bottom"] = max(row["bottom"], box[3])
                break
        else:
            rows.append({"top": box[1], "bottom": box[3], "boxes": [box]})
    ordered = []
    for row in rows:
        ordered += sorted(row["boxes"], key=lambda b: b[0])
    return ordered


def overlaps(a, b):
    return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


def cut(folder, name=None, out_root=None, scale=1.0):
    name = name or os.path.basename(os.path.normpath(folder))
    out_dir = os.path.join(out_root or os.path.join(ROOT, "art", "characters"), name)
    keyed = []
    for sheet_name in SHEETS:
        path = os.path.join(folder, sheet_name)
        if not os.path.exists(path):
            sys.exit("Missing sheet: %s (need %s)" % (path, ", ".join(SHEETS)))
        keyed.append(key_out(Image.open(path)))
    if len({k.size for k in keyed}) != 1:
        sys.exit("%s: the three sheets must have the same size" % folder)

    boxes = [find_boxes(k) for k in keyed]
    base = boxes[0]
    names_path = os.path.join(folder, "parts.txt")
    if os.path.exists(names_path):
        with open(names_path, encoding="utf-8") as f:
            names = [line.strip() for line in f if line.strip()]
        if len(names) != len(base):
            sys.exit("%s: parts.txt names %d pieces but the intact sheet has %d (are they 40 px apart?)"
                     % (folder, len(names), len(base)))
    else:
        names = ["part_%02d" % (i + 1) for i in range(len(base))]

    os.makedirs(out_dir, exist_ok=True)
    for i, box in enumerate(base):
        # the same piece in the damaged sheets: the boxes that overlap this one
        union = list(box)
        for other in boxes[1:]:
            for b in other:
                if overlaps(b, box):
                    union = [min(union[0], b[0]), min(union[1], b[1]), max(union[2], b[2]), max(union[3], b[3])]
        union = tuple(union)
        fw, fh = union[2] - union[0], union[3] - union[1]
        strip = Image.new("RGBA", (fw * 3, fh), (0, 0, 0, 0))
        for frame, k in enumerate(keyed):
            strip.paste(k.crop(union), (fw * frame, 0))
        if scale != 1.0:
            fw, fh = max(1, round(fw * scale)), max(1, round(fh * scale))
            frames = [strip.crop((f * (strip.width // 3), 0, (f + 1) * (strip.width // 3), strip.height)).resize((fw, fh), Image.LANCZOS)
                      for f in range(3)]
            strip = Image.new("RGBA", (fw * 3, fh), (0, 0, 0, 0))
            for f, img in enumerate(frames):
                strip.paste(img, (fw * f, 0))
        strip.save(os.path.join(out_dir, names[i] + ".png"), optimize=True)
        print("  %-10s %4d x %-4d (3 frames) from %s" % (names[i], fw, fh, union))
    print("%s: %d pieces -> %s" % (name, len(base), os.path.relpath(out_dir, ROOT)))


def main():
    parser = argparse.ArgumentParser(description="Cut a character sheet (vista desarmada) into 3-frame part strips.")
    parser.add_argument("folder", nargs="?", help="folder with intacto.png, danado.png, critico.png [, parts.txt]")
    parser.add_argument("--name", help="character name (default: the folder name)")
    parser.add_argument("--out", help="output root (default: art/characters)")
    parser.add_argument("--all", action="store_true", help="cut every folder in tools/art_src")
    parser.add_argument("--scale", type=float, default=1.0, help="resize the strips (for example 0.25 for 2048 px sheets)")
    args = parser.parse_args()
    if args.all:
        src = os.path.join(ROOT, "tools", "art_src")
        for d in sorted(os.listdir(src)):
            if os.path.isdir(os.path.join(src, d)):
                cut(os.path.join(src, d), out_root=args.out, scale=args.scale)
    elif args.folder:
        cut(args.folder, args.name, args.out, args.scale)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
