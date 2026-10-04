#!/usr/bin/env python3
"""Build the PICO-8 text cartridge from Lua and hand-authored pixel matrices."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def sprites():
    grid = [["f"] * 128 for _ in range(64)]
    used = set()
    blocks = re.split(r"^@ ", (ROOT / "assets/sprites.txt").read_text(), flags=re.M)[1:]
    for block in blocks:
        lines = block.splitlines()
        name, sx, sy = lines[0].split()
        sx, sy = int(sx), int(sy)
        rows = [s.strip() for s in lines[1:] if s.strip() and not s.startswith("#")]
        width = len(rows[0])
        if any(len(row) != width for row in rows):
            raise ValueError(f"{name}: uneven rows")
        for y, row in enumerate(rows):
            for x, value in enumerate(row):
                px, py = sx + x, sy + y
                if not (0 <= px < 128 and 0 <= py < 64):
                    raise ValueError(f"{name}: outside upper sprite bank")
                if (px, py) in used:
                    raise ValueError(f"{name}: overlapping sprites at {px},{py}")
                value = "f" if value == "." else value
                if value not in "0123456789abcdef":
                    raise ValueError(f"{name}: invalid colour {value}")
                grid[py][px] = value
                used.add((px, py))
    return "\n".join("".join(row) for row in grid)

def sfx():
    effects = [
        (2, [(24, 0, 4, 0), (29, 0, 4, 0), (34, 0, 3, 0), (38, 0, 2, 0)]),
        (1, [(38, 6, 4, 0), (31, 6, 3, 0), (24, 6, 2, 0), (19, 6, 1, 0)]),
        (1, [(34, 6, 3, 0), (29, 6, 2, 0), (24, 6, 1, 0)]),
        (2, [(16, 3, 4, 0), (12, 3, 3, 0), (9, 3, 2, 0)]),
        (2, [(30, 6, 4, 0), (24, 6, 3, 0), (17, 6, 2, 0), (12, 6, 1, 0)]),
        (5, [(24, 0, 4, 0), (28, 0, 4, 0), (31, 0, 4, 0), (36, 0, 3, 0)]),
    ]
    result = []
    for speed, notes in effects:
        padded = notes + [(0, 0, 0, 0)] * (32 - len(notes))
        result.append(f"00{speed:02x}0000" + "".join(f"{p:02x}{w:x}{v:x}{e:x}" for p,w,v,e in padded))
    return "\n".join(result)

lua = (ROOT / "src/game.lua").read_text()
lua.encode("ascii")
cart = f"pico-8 cartridge // http://www.pico-8.com\nversion 42\n__lua__\n{lua}\n__gfx__\n{sprites()}\n__sfx__\n{sfx()}\n"
(ROOT / "nero-fuori.p8").write_text(cart)
print(f"Built nero-fuori.p8: {len(lua)} Lua characters; sprites in upper 64 rows")
