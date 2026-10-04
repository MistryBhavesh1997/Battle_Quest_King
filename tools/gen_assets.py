"""Generates placeholder pixel-art + the Tiled map for Quest of Kings.

Run: python3 tools/gen_assets.py
Replace any generated PNG with your own art of the same size to restyle the game.
"""
import random
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
IMG = ROOT / "assets" / "images"
TILES = ROOT / "assets" / "tiles"
IMG.mkdir(parents=True, exist_ok=True)
TILES.mkdir(parents=True, exist_ok=True)
random.seed(7)

# ---------------------------------------------------------------- tileset
# 8 columns x 2 rows of 16x16 tiles. gid = index + 1
T = 16
TS_COLS = 8
tileset = Image.new("RGBA", (T * TS_COLS, T * 2), (0, 0, 0, 0))


def tile(idx):
    return tileset, (idx % TS_COLS) * T, (idx // TS_COLS) * T


def speckle(d, ox, oy, base, spots, n=14):
    d.rectangle([ox, oy, ox + T - 1, oy + T - 1], fill=base)
    for _ in range(n):
        x, y = ox + random.randrange(T), oy + random.randrange(T)
        d.point((x, y), fill=random.choice(spots))


d = ImageDraw.Draw(tileset)
# 0 grass
speckle(d, *tile(0)[1:], (88, 160, 72, 255), [(72, 140, 60, 255), (104, 178, 84, 255)])
# 1 grass + flowers
ox, oy = tile(1)[1:]
speckle(d, ox, oy, (88, 160, 72, 255), [(72, 140, 60, 255), (104, 178, 84, 255)], 10)
for (x, y, c) in [(4, 5, (250, 240, 120, 255)), (11, 10, (240, 120, 150, 255)), (7, 13, (255, 255, 255, 255))]:
    d.point((ox + x, oy + y), fill=c)
    d.point((ox + x + 1, oy + y), fill=c)
# 2 dirt path
speckle(d, *tile(2)[1:], (196, 160, 108, 255), [(176, 140, 92, 255), (214, 180, 128, 255)], 20)
# 3 water
ox, oy = tile(3)[1:]
d.rectangle([ox, oy, ox + 15, oy + 15], fill=(60, 120, 200, 255))
for (x, y) in [(2, 4), (9, 9), (5, 13), (12, 3)]:
    d.line([ox + x, oy + y, ox + x + 3, oy + y], fill=(130, 180, 240, 255))
# 4 tree (on transparent so it can sit over grass)
ox, oy = tile(4)[1:]
d.rectangle([ox + 7, oy + 10, ox + 9, oy + 15], fill=(110, 72, 40, 255))
d.ellipse([ox + 1, oy + 0, ox + 14, oy + 12], fill=(40, 110, 54, 255))
d.ellipse([ox + 3, oy + 1, ox + 10, oy + 7], fill=(60, 140, 70, 255))
# 5 house wall
ox, oy = tile(5)[1:]
d.rectangle([ox, oy, ox + 15, oy + 15], fill=(214, 190, 150, 255))
for y in (5, 10):
    d.line([ox, oy + y, ox + 15, oy + y], fill=(170, 146, 108, 255))
# 6 roof
ox, oy = tile(6)[1:]
d.rectangle([ox, oy, ox + 15, oy + 15], fill=(176, 64, 56, 255))
for y in (3, 7, 11, 15):
    d.line([ox, oy + y, ox + 15, oy + y], fill=(130, 44, 40, 255))
# 7 door
ox, oy = tile(7)[1:]
d.rectangle([ox, oy, ox + 15, oy + 15], fill=(214, 190, 150, 255))
d.rectangle([ox + 3, oy + 2, ox + 12, oy + 15], fill=(100, 64, 36, 255))
d.point((ox + 10, oy + 9), fill=(250, 220, 90, 255))
# 8 stone / rock (decor)
ox, oy = tile(8)[1:]
d.ellipse([ox + 2, oy + 5, ox + 14, oy + 14], fill=(130, 130, 140, 255))
d.ellipse([ox + 4, oy + 6, ox + 9, oy + 10], fill=(168, 168, 178, 255))
# 9 sand shore
speckle(d, *tile(9)[1:], (226, 208, 150, 255), [(208, 190, 130, 255), (240, 224, 170, 255)], 16)
tileset.save(IMG / "tileset.png")


# ---------------------------------------------------------------- sprites
def hero_frame(direction, frame):
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    g = ImageDraw.Draw(im)
    bob = 1 if frame in (1, 3) else 0
    swing = [0, 2, 0, -2][frame]
    # shadow
    g.ellipse([9, 26, 23, 30], fill=(0, 0, 0, 70))
    skin, hair, tunic, pants, boots = (240, 200, 160), (110, 70, 40), (60, 110, 200), (70, 60, 90), (60, 40, 30)
    # legs
    if direction in (0, 3):
        g.rectangle([11, 21 - bob, 14, 27 + swing // 2 * -1], fill=pants)
        g.rectangle([17, 21 - bob, 20, 27 + swing // 2], fill=pants)
        g.rectangle([11, 27 - swing // 2, 14, 28 - swing // 2], fill=boots)
        g.rectangle([17, 27 + swing // 2, 20, 28 + swing // 2], fill=boots)
    else:
        g.rectangle([13 + swing, 21 - bob, 17 + swing, 27], fill=pants)
        g.rectangle([13 - swing, 21 - bob, 17 - swing, 27], fill=(55, 46, 72, 255))
        g.rectangle([13 + swing, 27, 18 + swing, 28], fill=boots)
    # body
    g.rectangle([10, 13 - bob, 21, 22 - bob], fill=tunic)
    g.rectangle([10, 19 - bob, 21, 20 - bob], fill=(220, 180, 60, 255))  # belt
    # arms
    if direction in (0, 3):
        g.rectangle([8, 14 - bob, 9, 20 - bob + swing // 2], fill=skin)
        g.rectangle([22, 14 - bob, 23, 20 - bob - swing // 2], fill=skin)
    # head
    g.rectangle([10, 4 - bob, 21, 13 - bob], fill=skin)
    g.rectangle([10, 3 - bob, 21, 7 - bob], fill=hair)
    if direction == 0:  # face down
        g.rectangle([12, 9 - bob, 13, 10 - bob], fill=(30, 30, 40, 255))
        g.rectangle([18, 9 - bob, 19, 10 - bob], fill=(30, 30, 40, 255))
    elif direction == 1:  # left
        g.rectangle([11, 9 - bob, 12, 10 - bob], fill=(30, 30, 40, 255))
        g.rectangle([16, 4 - bob, 21, 12 - bob], fill=hair)
    elif direction == 2:  # right
        g.rectangle([19, 9 - bob, 20, 10 - bob], fill=(30, 30, 40, 255))
        g.rectangle([10, 4 - bob, 15, 12 - bob], fill=hair)
    else:  # up
        g.rectangle([10, 3 - bob, 21, 12 - bob], fill=hair)
    # sword on side
    if direction in (0, 1):
        g.line([6, 17 - bob, 6, 24 - bob], fill=(200, 200, 215, 255), width=1)
        g.point((6, 25 - bob), fill=(180, 120, 40, 255))
    return im


hero = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
for row in range(4):
    for col in range(4):
        hero.paste(hero_frame(row, col), (col * 32, row * 32))
hero.save(IMG / "hero.png")


def slime_frame(f):
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    g = ImageDraw.Draw(im)
    squash = [0, 2, 3, 1][f]
    top = 12 + squash
    wid = 2 - squash // 2
    g.ellipse([8 - wid, 27, 24 + wid, 31], fill=(0, 0, 0, 70))
    g.ellipse([6 - wid, top, 26 + wid, 29], fill=(80, 200, 110, 255))
    g.ellipse([8 - wid, top + 1, 22 + wid, 24], fill=(120, 230, 150, 255))
    g.ellipse([10, top + 3, 14, top + 6], fill=(220, 255, 230, 255))
    g.rectangle([11, 20, 13, 23], fill=(20, 40, 30, 255))
    g.rectangle([19, 20, 21, 23], fill=(20, 40, 30, 255))
    return im


slime = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
for i in range(4):
    slime.paste(slime_frame(i), (i * 32, 0))
slime.save(IMG / "slime.png")

# NPC elder (single frame)
npc = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
g = ImageDraw.Draw(npc)
g.ellipse([9, 26, 23, 30], fill=(0, 0, 0, 70))
g.polygon([(9, 27), (11, 12), (21, 12), (23, 27)], fill=(130, 60, 160, 255))
g.rectangle([10, 19, 21, 20], fill=(230, 200, 80, 255))
g.rectangle([10, 4, 21, 13], fill=(238, 200, 164, 255))
g.rectangle([9, 10, 22, 17], fill=(235, 235, 240, 255))  # beard
g.rectangle([12, 9, 13, 10], fill=(30, 30, 40, 255))
g.rectangle([18, 9, 19, 10], fill=(30, 30, 40, 255))
g.polygon([(8, 5), (16, -2), (24, 5)], fill=(100, 40, 130, 255))
g.rectangle([25, 6, 26, 28], fill=(120, 80, 40, 255))  # staff
g.ellipse([23, 3, 28, 8], fill=(100, 220, 250, 255))
npc.save(IMG / "npc.png")

# Potion 16x16
potion = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
g = ImageDraw.Draw(potion)
g.rectangle([6, 1, 9, 4], fill=(170, 130, 80, 255))
g.rectangle([6, 4, 9, 6], fill=(220, 230, 240, 255))
g.ellipse([3, 6, 12, 15], fill=(220, 50, 70, 255))
g.ellipse([5, 8, 7, 10], fill=(255, 170, 180, 255))
potion.save(IMG / "potion.png")

# Key 16x16
key = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
g = ImageDraw.Draw(key)
gold = (240, 200, 60, 255)
g.ellipse([2, 2, 8, 8], outline=gold, width=2)
g.rectangle([7, 7, 8, 14], fill=gold)
g.rectangle([8, 11, 11, 12], fill=gold)
g.rectangle([8, 14, 10, 14], fill=gold)
key.save(IMG / "key.png")

# App icon (1024) — crown on royal-blue
icon = Image.new("RGBA", (1024, 1024), (24, 28, 64, 255))
g = ImageDraw.Draw(icon)
for r in range(480, 0, -8):
    shade = int(40 + (480 - r) * 0.09)
    g.ellipse([512 - r, 512 - r, 512 + r, 512 + r], fill=(shade, shade + 6, shade + 50, 255))
crown = [(212, 640), (212, 380), (360, 520), (512, 330), (664, 520), (812, 380), (812, 640)]
g.polygon(crown, fill=(244, 196, 48, 255), outline=(150, 100, 20, 255))
g.rectangle([212, 640, 812, 720], fill=(224, 170, 36, 255))
for cx, cy in [(212, 370), (512, 320), (812, 370)]:
    g.ellipse([cx - 34, cy - 34, cx + 34, cy + 34], fill=(220, 60, 80, 255), outline=(255, 230, 150, 255), width=6)
for cx in (330, 512, 694):
    g.ellipse([cx - 22, 664, cx + 22, 700], fill=(90, 200, 250, 255))
icon.save(ROOT / "assets" / "icon.png")

# ---------------------------------------------------------------- map
W, H = 40, 28
GRASS, FLOWER, PATH, WATER, TREE, WALL, ROOF, DOOR, ROCK, SAND = [i + 1 for i in range(10)]

ground = [[GRASS] * W for _ in range(H)]
decor = [[0] * W for _ in range(H)]
for y in range(H):
    for x in range(W):
        if random.random() < 0.08:
            ground[y][x] = FLOWER

# paths: horizontal through middle, vertical to the house
for x in range(W):
    for y in (13, 14):
        ground[y][x] = PATH
for y in range(6, 14):
    for x in (9, 10):
        ground[y][x] = PATH

# pond (with sand shore)
pond = (26, 4, 33, 9)  # x0,y0,x1,y1 inclusive
for y in range(pond[1] - 1, pond[3] + 2):
    for x in range(pond[0] - 1, pond[2] + 2):
        ground[y][x] = SAND
for y in range(pond[1], pond[3] + 1):
    for x in range(pond[0], pond[2] + 1):
        ground[y][x] = WATER

collisions = []  # pixel rects


def rect(x0, y0, x1, y1):
    collisions.append((x0 * T, y0 * T, (x1 - x0 + 1) * T, (y1 - y0 + 1) * T))


# border trees
for x in range(W):
    for y in (0, H - 1):
        decor[y][x] = TREE
for y in range(H):
    for x in (0, W - 1):
        decor[y][x] = TREE
rect(0, 0, W - 1, 0)
rect(0, H - 1, W - 1, H - 1)
rect(0, 1, 0, H - 2)
rect(W - 1, 1, W - 1, H - 2)
rect(*pond)

# house (roof 2 rows + wall row with door)
hx0, hx1, hy = 6, 12, 2
for x in range(hx0, hx1 + 1):
    decor[hy][x] = ROOF
    decor[hy + 1][x] = ROOF
    decor[hy + 2][x] = WALL
    decor[hy + 3][x] = WALL
decor[hy + 3][9] = DOOR
ground[hy + 4][9] = PATH
ground[hy + 4][10] = PATH
rect(hx0, hy, hx1, hy + 3)

# scattered trees & rocks (each blocks)
for (x, y) in [(16, 4), (18, 6), (20, 3), (15, 9), (4, 18), (6, 21), (3, 24), (22, 20),
               (30, 18), (33, 22), (36, 17), (24, 24), (12, 22), (35, 8), (37, 11), (19, 17)]:
    decor[y][x] = TREE
    rect(x, y, x, y)
for (x, y) in [(14, 18), (27, 16), (32, 25), (8, 17)]:
    decor[y][x] = ROCK
    rect(x, y, x, y)


def csv(layer):
    return ",\n".join(",".join(str(v) for v in row) for row in layer)


spawns = []
oid = [10]


def point(name, x, y, **props):
    oid[0] += 1
    p = "".join(f'<property name="{k}" value="{v}"/>' for k, v in props.items())
    spawns.append(
        f'  <object id="{oid[0]}" name="{name}" x="{x * T + 8}" y="{y * T + 8}"><properties>{p}</properties><point/></object>'
    )


point("", 9, 8, kind="player")
point("Elder", 12, 8, kind="npc", sprite="npc.png", quest="slime_trouble",
      dialogue="Hail, brave traveller!|Slimes are swarming our village.|Defeat 3 of them and a reward is yours.")
for (x, y) in [(18, 13), (24, 11), (30, 14), (22, 22), (34, 20)]:
    point("", x, y, kind="enemy", type="slime")
point("", 14, 11, kind="item", item="potion")
point("", 36, 13, kind="item", item="potion")
point("", 5, 20, kind="item", item="key")

coll_xml = "\n".join(
    f'  <object id="{i + 1}" x="{x}" y="{y}" width="{w}" height="{h}"/>' for i, (x, y, w, h) in enumerate(collisions)
)

tmx = f"""<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.10.2" orientation="orthogonal" renderorder="right-down" width="{W}" height="{H}" tilewidth="{T}" tileheight="{T}" infinite="0" nextlayerid="5" nextobjectid="{oid[0] + 1}">
 <tileset firstgid="1" name="tileset" tilewidth="{T}" tileheight="{T}" tilecount="{TS_COLS * 2}" columns="{TS_COLS}">
  <image source="../images/tileset.png" width="{T * TS_COLS}" height="{T * 2}"/>
 </tileset>
 <layer id="1" name="Ground" width="{W}" height="{H}">
  <data encoding="csv">
{csv(ground)}
</data>
 </layer>
 <layer id="2" name="Decor" width="{W}" height="{H}">
  <data encoding="csv">
{csv(decor)}
</data>
 </layer>
 <objectgroup id="3" name="Collisions">
{coll_xml}
 </objectgroup>
 <objectgroup id="4" name="Spawns">
{chr(10).join(spawns)}
 </objectgroup>
</map>
"""
(TILES / "village.tmx").write_text(tmx)
print("generated assets in", IMG, "and", TILES)
