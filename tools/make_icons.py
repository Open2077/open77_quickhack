"""Draws the built-in quickhack icons (original line art) as PNGs into ../ui/icons/.

python tools/make_icons.py      (Pillow only; rendered at 4x and downsampled for clean edges)

Icons are white glyphs on transparent, 128x128. The UI tints them through `image-color`, so one
file serves the ready / hovered / blocked states. Server developers can ship their own PNGs and
reference them from a quickhack definition (`icon = "/ui/my.png"` inside their resource).
"""
import math
import pathlib

from PIL import Image, ImageDraw

SIZE = 128
SS = 4
S = SIZE * SS
W = 6 * SS          # main stroke
T = 4 * SS          # thin stroke
OUT = pathlib.Path(__file__).resolve().parent.parent / "ui" / "icons"
WHITE = (255, 255, 255, 255)


def P(x, y):
    """Design space is 0..100."""
    return (x * S / 100.0, y * S / 100.0)


def line(d, pts, w=W):
    pts = [P(*p) for p in pts]
    d.line(pts, fill=WHITE, width=int(w), joint="curve")
    r = w / 2
    for x, y in (pts[0], pts[-1]):
        d.ellipse((x - r, y - r, x + r, y + r), fill=WHITE)


def poly(d, pts, fill=True, w=W):
    pts = [P(*p) for p in pts]
    if fill:
        d.polygon(pts, fill=WHITE)
    else:
        d.line(pts + [pts[0]], fill=WHITE, width=int(w), joint="curve")


def circle(d, cx, cy, r, w=W, fill=False):
    x, y = P(cx, cy)
    rr = r * S / 100.0
    if fill:
        d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=WHITE)
    else:
        d.ellipse((x - rr, y - rr, x + rr, y + rr), outline=WHITE, width=int(w))


def arc(d, cx, cy, r, a0, a1, w=W):
    x, y = P(cx, cy)
    rr = r * S / 100.0
    d.arc((x - rr, y - rr, x + rr, y + rr), a0, a1, fill=WHITE, width=int(w))


def head(d, x=50, y=54, scale=1.0, w=W):
    """A profile head facing right (neck to the bottom-left), used by several hacks."""
    pts = [(-14, 30), (-14, 14), (-20, 4), (-20, -10), (-12, -24), (2, -28), (14, -22), (20, -10),
           (20, -2), (26, 6), (20, 8), (20, 16), (12, 18), (10, 30)]
    line(d, [(x + px * scale, y + py * scale) for px, py in pts], w)


def bolt(d, x, y, s=1.0):
    poly(d, [(x + 2 * s, y - 22 * s), (x - 10 * s, y + 2 * s), (x - 1 * s, y + 2 * s), (x - 5 * s, y + 22 * s),
             (x + 11 * s, y - 4 * s), (x + 2 * s, y - 4 * s)])


def eye(d, cx, cy, rx, ry, w=W):
    pts = []
    for i in range(0, 41):
        t = math.pi * i / 40
        pts.append((cx - rx * math.cos(t), cy - ry * math.sin(t)))
    for i in range(0, 41):
        t = math.pi * i / 40
        pts.append((cx + rx * math.cos(t), cy + ry * math.sin(t)))
    line(d, pts, w)


ICONS = {}


def icon(name):
    def wrap(fn):
        ICONS[name] = fn
        return fn
    return wrap


@icon("overheat")
def _(d):
    head(d, 44, 58, 1.0)
    for x, h in ((70, 30), (80, 40), (90, 26)):
        line(d, [(x, 70), (x - 5, 70 - h * 0.45), (x + 3, 70 - h * 0.7), (x - 2, 70 - h)], T)


@icon("short_circuit")
def _(d):
    bolt(d, 50, 50, 1.35)
    for a in range(0, 360, 45):
        r0, r1 = 34, 46
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        line(d, [(50 + ca * r0, 50 + sa * r0), (50 + ca * r1, 50 + sa * r1)], T)


@icon("reboot_optics")
def _(d):
    eye(d, 50, 50, 34, 18)
    circle(d, 50, 50, 9, fill=True)
    arc(d, 50, 50, 42, 200, 330, T)
    poly(d, [(84, 28), (90, 40), (78, 40)])
    arc(d, 50, 50, 42, 20, 150, T)
    poly(d, [(16, 72), (10, 60), (22, 60)])


@icon("synapse_burnout")
def _(d):
    line(d, [(50, 22), (38, 18), (24, 26), (18, 42), (22, 58), (34, 70), (50, 74), (66, 70), (78, 58), (82, 42),
             (76, 26), (62, 18), (50, 22)])
    line(d, [(50, 22), (46, 36), (56, 46), (44, 58), (50, 74)], T)
    line(d, [(30, 40), (40, 46)], T)
    line(d, [(70, 38), (62, 52)], T)
    line(d, [(46, 84), (40, 92)], T)
    line(d, [(56, 84), (62, 94)], T)


@icon("ping")
def _(d):
    nodes = [(50, 30), (26, 62), (74, 62), (50, 80)]
    for a in nodes:
        for b in nodes:
            if a < b:
                line(d, [a, b], T * 0.7)
    for x, y in nodes:
        circle(d, x, y, 7, fill=True)
    arc(d, 50, 30, 18, 200, 340, T)
    arc(d, 50, 30, 27, 205, 335, T)


@icon("contagion")
def _(d):
    circle(d, 50, 50, 14)
    for a in range(0, 360, 60):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        line(d, [(50 + ca * 16, 50 + sa * 16), (50 + ca * 32, 50 + sa * 32)])
        circle(d, 50 + ca * 37, 50 + sa * 37, 6, fill=True)
    circle(d, 50, 50, 5, fill=True)


@icon("breach_protocol")
def _(d):
    line(d, [(30, 46), (30, 30), (36, 20), (48, 16), (60, 20), (66, 28)])
    poly(d, [(22, 46), (78, 46), (78, 86), (22, 86)], fill=False)
    bolt(d, 52, 66, 0.75)


@icon("cyberpsychosis")
def _(d):
    eye(d, 50, 50, 36, 22)
    circle(d, 50, 50, 12)
    circle(d, 50, 50, 4, fill=True)
    for a in (-60, -30, 0, 30, 60):
        ca, sa = math.cos(math.radians(a - 90)), math.sin(math.radians(a - 90))
        line(d, [(50 + ca * 28, 50 + sa * 28), (50 + ca * 40, 50 + sa * 40)], T)


@icon("system_reset")
def _(d):
    arc(d, 50, 54, 30, -50, 230)
    line(d, [(50, 14), (50, 50)])
    line(d, [(80, 20), (88, 12)], T)
    line(d, [(84, 30), (94, 28)], T)


@icon("suicide")
def _(d):
    head(d, 40, 58, 1.0)
    poly(d, [(62, 40), (88, 40), (88, 48), (72, 48), (72, 58), (64, 58)])


@icon("cripple_movement")
def _(d):
    line(d, [(44, 14), (40, 46), (50, 58), (44, 88), (60, 88)])
    line(d, [(34, 46), (60, 40)], T)
    line(d, [(62, 56), (78, 64)], T)
    line(d, [(66, 70), (80, 60)], T)


@icon("weapon_glitch")
def _(d):
    poly(d, [(14, 36), (80, 36), (80, 48), (46, 48), (40, 72), (26, 72), (30, 48), (14, 48)], fill=False)
    line(d, [(80, 42), (90, 42)], T)
    line(d, [(54, 60), (62, 66), (58, 74), (68, 82)], T)
    line(d, [(70, 58), (80, 66), (76, 76), (86, 84)], T)


@icon("memory_wipe")
def _(d):
    head(d, 46, 58, 1.0)
    for y in (34, 46, 58):
        line(d, [(70, y), (90, y)], T)
    line(d, [(72, 70), (88, 86)], T)
    line(d, [(88, 70), (72, 86)], T)


@icon("sonic_shock")
def _(d):
    poly(d, [(16, 40), (30, 40), (46, 26), (46, 74), (30, 60), (16, 60)])
    arc(d, 46, 50, 16, -50, 50, T)
    arc(d, 46, 50, 28, -50, 50, T)
    arc(d, 46, 50, 40, -50, 50, T)


@icon("distract")
def _(d):
    line(d, [(30, 70), (30, 46), (36, 30), (50, 24), (64, 30), (70, 46), (70, 70)])
    line(d, [(22, 72), (78, 72)])
    circle(d, 50, 82, 6, fill=True)
    line(d, [(84, 30), (92, 24)], T)
    line(d, [(16, 30), (8, 24)], T)


@icon("request_backup")
def _(d):
    for x in (30, 70):
        circle(d, x, 32, 9)
        line(d, [(x - 14, 70), (x - 14, 54), (x, 46), (x + 14, 54), (x + 14, 70)])
    circle(d, 50, 46, 10)
    line(d, [(32, 84), (32, 68), (50, 58), (68, 68), (68, 84)])


@icon("takeover")
def _(d):
    poly(d, [(20, 20), (42, 74), (50, 54), (72, 82), (80, 74), (58, 48), (78, 40)], fill=False)
    circle(d, 74, 22, 8)
    line(d, [(74, 8), (74, 14)], T)
    line(d, [(88, 22), (82, 22)], T)


@icon("malfunction")
def _(d):
    for i in range(8):
        a = math.radians(i * 45)
        ca, sa = math.cos(a), math.sin(a)
        line(d, [(50 + ca * 26, 50 + sa * 26), (50 + ca * 36, 50 + sa * 36)], W * 1.4)
    circle(d, 50, 50, 26)
    circle(d, 50, 50, 9)
    line(d, [(58, 18), (50, 40), (60, 56), (48, 86)], T)


@icon("overload")
def _(d):
    poly(d, [(24, 30), (70, 30), (70, 78), (24, 78)], fill=False)
    poly(d, [(40, 22), (54, 22), (54, 30), (40, 30)])
    bolt(d, 47, 54, 0.8)
    line(d, [(80, 30), (90, 22)], T)
    line(d, [(80, 48), (92, 48)], T)


@icon("blind")
def _(d):
    eye(d, 50, 50, 34, 20)
    circle(d, 50, 50, 9, fill=True)
    line(d, [(18, 80), (82, 20)])


@icon("detonate_grenade")
def _(d):
    circle(d, 46, 58, 24)
    poly(d, [(38, 30), (54, 30), (54, 38), (38, 38)])
    line(d, [(54, 32), (66, 22), (78, 26)], T)
    for a in (-80, -40, 0):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        line(d, [(84 + ca * 4, 22 + sa * 4), (84 + ca * 12, 22 + sa * 12)], T)


@icon("data")
def _(d):
    poly(d, [(24, 14), (64, 14), (78, 28), (78, 86), (24, 86)], fill=False)
    for y in (36, 50, 64):
        line(d, [(36, y), (66, y)], T)


@icon("generic")
def _(d):
    poly(d, [(50, 14), (84, 34), (84, 66), (50, 86), (16, 66), (16, 34)], fill=False)
    line(d, [(36, 40), (50, 54), (36, 66)], T)
    line(d, [(54, 66), (68, 66)], T)


@icon("ram")
def _(d):
    poly(d, [(30, 10), (62, 10), (70, 18), (70, 90), (30, 90)], fill=False)
    for y in (28, 44, 60, 76):
        line(d, [(40, y), (60, y)], T)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, draw in ICONS.items():
        img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        draw(ImageDraw.Draw(img))
        img = img.resize((SIZE, SIZE), Image.LANCZOS)
        img.save(OUT / f"{name}.png", optimize=True)
    print(f"{len(ICONS)} icons -> {OUT}")


if __name__ == "__main__":
    main()
