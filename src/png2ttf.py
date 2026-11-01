
import fontforge
import sys
import re

raw_file, output_file, family = sys.argv[1:4]

SPACING = int(sys.argv[4])
SPACE_WIDTH = int(sys.argv[5])

WIDTH = 4096
HEIGHT = 16
SCALE = 64
EM = 1024
AUTHOR_COPYRIGHT = "Philipp Schwarz (github.com/philipp-schwarz)"

with open(raw_file, "rb") as f:
    pixels = f.read()

background = pixels[0:4]

def is_pixel(x, y):
    offset = (y * WIDTH + x) * 4
    p = pixels[offset:offset + 4]

    if p[3] == 0:
        return False

    if background[3] == 0:
        return True

    return p != background

def trace_contours(occupied):
    """Return the boundary loops of a set of unit pixels."""
    edges = set()

    def add_edge(start, end):
        reverse = (end, start)
        if reverse in edges:
            edges.remove(reverse)
        else:
            edges.add((start, end))

    for x, y in occupied:
        # Edges are directed with the filled area on their left.
        if (x, y - 1) not in occupied:
            add_edge((x, y), (x + 1, y))
        if (x + 1, y) not in occupied:
            add_edge((x + 1, y), (x + 1, y + 1))
        if (x, y + 1) not in occupied:
            add_edge((x + 1, y + 1), (x, y + 1))
        if (x - 1, y) not in occupied:
            add_edge((x, y + 1), (x, y))

    outgoing = {}
    for start, end in edges:
        outgoing.setdefault(start, []).append(end)

    # Prefer a left turn at shared vertices so diagonally touching pixels
    # remain separate contours instead of producing a self-crossing outline.
    turn_rank = {1: 0, 0: 1, 3: 2, 2: 3}
    contours = []
    while edges:
        first = next(iter(edges))
        start, end = first
        contour = [start]
        edges.remove(first)
        previous, current = start, end

        while current != start:
            contour.append(current)
            candidates = [point for point in outgoing.get(current, [])
                          if (current, point) in edges]
            if not candidates:
                break

            in_dir = ((current[0] - previous[0]),
                      (current[1] - previous[1]))
            def rank(point):
                out_dir = (point[0] - current[0], point[1] - current[1])
                directions = ((1, 0), (0, 1), (-1, 0), (0, -1))
                turn = (directions.index(out_dir) - directions.index(in_dir)) % 4
                return turn_rank[turn]

            next_point = min(candidates, key=rank)
            edges.remove((current, next_point))
            previous, current = current, next_point

        if current == start:
            contours.append(contour)

    return contours

font = fontforge.font()
font.encoding = "UnicodeFull"
font.em = EM
font.ascent = EM
font.descent = 0

font.familyname = family
font.fullname = family
font.fontname = re.sub(r"[^a-zA-Z0-9_-]", "", family)
font.version = "1.0"
font.copyright = AUTHOR_COPYRIGHT
font.appendSFNTName("English (US)", "Designer", AUTHOR_COPYRIGHT)

for code in range(256):
    glyph = font.createChar(code)
    pen = glyph.glyphPen()

    # Leerzeichen separat behandeln
    if code == 32:
        glyph.width = SPACE_WIDTH * SCALE
        continue

    occupied_pixels = {
        (x, 15 - y)
        for y in range(16)
        for x in range(16)
        if is_pixel(code * 16 + x, y)
    }
    used = [x for x, _ in occupied_pixels]

    if used:
        min_x = min(used)
        max_x = max(used) + 1
        width = max_x - min_x
    else:
        min_x = 0
        width = 0

    normalized_pixels = {(x - min_x, y) for x, y in occupied_pixels}
    for contour in trace_contours(normalized_pixels):
        pen.moveTo((contour[0][0] * SCALE, contour[0][1] * SCALE))
        for x, y in contour[1:]:
            pen.lineTo((x * SCALE, y * SCALE))
        pen.closePath()

    glyph.width = (width + SPACING) * SCALE
    glyph.correctDirection()

font.generate(output_file)
print("Fertig:", output_file)

