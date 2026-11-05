"""Builds the game backgrounds of Block 11 from the art pieces (2560 x 1440).

The pieces were drawn separately so that the background fits the board exactly
(see tools/art_src/<world>/): a seamless floor texture, the building strip of the
left edge, the gate strip of the right edge and loose decorations, the last
three on a flat green #00FF00 background that this script removes.

Layout of a background (same as the 1.0, aligned with the board):
    0..200 px high        hidden by the top bar of the game
    x 0..160              the building (the student's safe zone)
    x 160..2320, y 220..1420   the 5 lanes (cell = 240 px; board at (80, 110) x 0.5)
    x 2320..2560          where the enemies come in

Usage (from the project root, numpy and Pillow installed):
    python tools/art_src/compose_backgrounds.py
"""

import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "tools", "art_src")
W, H = 2560, 1440
BOARD_LEFT, BOARD_RIGHT = 160, 2320
BOARD_TOP = 220
CELL = 240
STRIP_TOP = 200   # the strips start right under the top bar


def load(*parts):
    return Image.open(os.path.join(SRC, *parts)).convert("RGB")


def remove_green(image, keep_shadow=False):
    """Flat green #00FF00 -> transparent. With keep_shadow, the darker green of
    a drawn shadow becomes a soft black shadow instead of green."""
    a = np.asarray(image).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    background = (g > 170) & (r < 120) & (b < 120) & (g - r > 100)
    alpha = np.where(background, 0.0, 255.0)
    if keep_shadow:
        shadow = (~background) & (g - r > 50) & (g - b > 50) & (r < 90)
        darkness = np.clip((235.0 - g) / 235.0, 0.0, 1.0)
        alpha = np.where(shadow, darkness * 170.0, alpha)
        a[shadow] = 0.0
    # Pixels next to the background lose their green tint (no green halo).
    edge = Image.fromarray((background * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))
    edge = np.asarray(edge) > 0
    spill = edge & ~background
    a[..., 1] = np.where(spill, np.minimum(g, np.maximum(r, b)), a[..., 1])
    rgba = np.dstack([a, alpha]).clip(0, 255).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def tile_floor(texture, tile_size):
    """The floor texture repeated over the whole picture (tile_size = its width)."""
    floor = Image.new("RGB", (W, H))
    tile = texture.resize((tile_size, round(tile_size * texture.height / texture.width)), Image.LANCZOS)
    for y in range(0, H, tile.height):
        for x in range(BOARD_LEFT, W, tile_size):
            floor.paste(tile, (x, y))
        for x in range(BOARD_LEFT - tile_size, -tile_size, -tile_size):
            floor.paste(tile, (x, y))
    return floor


def stone_strips(image, every_columns, color, edge_color, width=24):
    """Strips of light stone along every lane line and every few columns."""
    d = ImageDraw.Draw(image)
    rng = np.random.default_rng(7)
    lines = [("h", BOARD_TOP + k * CELL) for k in range(6)]
    lines += [("v", BOARD_LEFT + k * CELL) for k in range(0, 10, every_columns)] + [("v", BOARD_RIGHT)]
    for kind, p in lines:
        if kind == "h":
            box = [BOARD_LEFT, p - width // 2, BOARD_RIGHT, p + width // 2]
        else:
            box = [p - width // 2, STRIP_TOP, p + width // 2, H]
        d.rectangle(box, fill=color, outline=edge_color, width=3)
    # a few darker specks so the stone does not look like plastic
    px = image.load()
    for _ in range(9000):
        x, y = int(rng.integers(0, W)), int(rng.integers(STRIP_TOP, H))
        if px[x, y] == color:
            px[x, y] = tuple(int(c * 0.93) for c in color)


def place_strip(canvas, strip, crop_left, crop_right, x, width, crop_top=0.0, crop_bottom=1.0, y=STRIP_TOP, height=H - STRIP_TOP):
    """Cuts the band [crop_left, crop_right] (fractions of the width) of a strip
    piece and puts it at x with that width, from STRIP_TOP to the bottom."""
    w, h = strip.size
    band = strip.crop((int(crop_left * w), int(crop_top * h), int(crop_right * w), int(crop_bottom * h)))
    band = band.resize((width, height), Image.LANCZOS)
    canvas.alpha_composite(band, (x, y))


def place_sprite(canvas, sprite, base_x, base_y, height):
    """A loose decoration with the bottom center of its drawing at (base_x, base_y)."""
    box = sprite.getbbox()
    sprite = sprite.crop(box)
    width = int(sprite.width * height / sprite.height)
    sprite = sprite.resize((width, height), Image.LANCZOS)
    canvas.alpha_composite(sprite, (base_x - width // 2, base_y - height))


def biblioteca():
    canvas = tile_floor(load("biblioteca", "floor.jpg"), 2 * CELL).convert("RGBA")
    stone_strips(canvas, 2, (230, 220, 200, 255), (150, 128, 112, 255))
    # Left: from the scalloped roof edge to the end of the staircase. The facade
    # (0.717 of the piece) falls on the edge of the board (x = 160).
    left = remove_green(load("biblioteca", "left_strip.jpg"))
    facade, start, end = 0.717, 0.421, 0.96
    scale = BOARD_LEFT / (facade - start)
    place_strip(canvas, left, start, end, 0, int((end - start) * scale))
    # Right: walkway, hedge and the open gate, over the entry area.
    right = remove_green(load("biblioteca", "right_strip.jpg"))
    place_strip(canvas, right, 0.269, 0.616, BOARD_RIGHT, W - BOARD_RIGHT)
    lamp = remove_green(load("biblioteca", "lamp.jpg"), keep_shadow=True)
    for base_y in (640, 1400):
        place_sprite(canvas, lamp, 2362, base_y, 230)
    canvas.convert("RGB").save(os.path.join(ROOT, "art", "backgrounds", "biblioteca_bg.jpg"), quality=92)


def escom():
    # The approved floor, cut between two joint lines (rows 99 and 1947) so that
    # its top continues its bottom; no stone strips (the board draws the grid).
    floor = load("escom", "floor.jpg")
    floor = floor.crop((0, round(99 * floor.height / 2000), floor.width, round(1947 * floor.height / 2000)))
    canvas = tile_floor(floor, 2 * CELL).convert("RGBA")
    # Left: the ESCOM block seen from above, its facade (0.735 of the piece) on
    # the edge of the board; the platform with the flagpoles goes out to the plaza.
    left = remove_green(load("escom", "left_strip.jpg"), keep_shadow=True)
    facade, start, end = 0.735, 0.470, 0.892
    scale = BOARD_LEFT / (facade - start)
    place_strip(canvas, left, start, end, 0, int((end - start) * scale))
    # Right: guinda fence with the open gate, hedge and walkway.
    right = remove_green(load("escom", "right_strip.jpg"))
    place_strip(canvas, right, 0.305, 0.651, BOARD_RIGHT, W - BOARD_RIGHT)
    canvas.convert("RGB").save(os.path.join(ROOT, "art", "backgrounds", "escom_bg.jpg"), quality=92)


if __name__ == "__main__":
    escom()
    biblioteca()
    print("done")
