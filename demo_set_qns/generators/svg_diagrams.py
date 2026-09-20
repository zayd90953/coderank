"""SVG diagram primitives — dependency-free (stdlib only).

Why SVG: matplotlib/Pillow are unavailable in this environment, and SVG is
plain text XML — labels, arrows, curves are native, the files are diffable
and reproducible, Flutter renders them via flutter_svg, and correctness can
be VERIFIED programmatically (parse the XML, check the geometry that the
question's answer depends on). A diagram question whose figure is wrong is
worse than no figure, so diagram_questions.py re-derives every answer from
the same parameters used to draw the figure.

Design:
  - Scene collects primitives; render() returns a well-formed SVG string.
  - No randomness inside this module — coordinates come from the caller
    (which uses the shared seeded RNG), so renders are reproducible.
  - Text is XML-escaped; unicode (Greek letters, superscripts) is fine.
  - The selftest at the bottom verifies XML well-formedness + key geometry.

Run selftest:  python demo_set_qns/generators/svg_diagrams.py
"""

from __future__ import annotations

import math
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field

# Fixed palette (works on both light and dark app backgrounds: shapes are
# drawn on a white rounded card inside the SVG itself).
INK = "#1F2937"        # primary lines/labels
ACCENT = "#2563EB"     # highlighted element (the "asked about" one)
RED = "#DC2626"        # second highlight / marked quantities
GREEN = "#059669"      # correct-path highlight in explanations
AMBER = "#D97706"      # tertiary
GRID = "#CBD5E1"       # graph grid
AXIS = "#334155"       # graph axes
CARD_BG = "#FFFFFF"
FONT = "Helvetica, Arial, sans-serif"


def esc(s: str) -> str:
    """XML-escape text content."""
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
             .replace('"', "&quot;"))


def _n(v: float) -> str:
    """Compact number formatting for attributes."""
    if abs(v - round(v)) < 1e-9:
        return str(int(round(v)))
    return f"{v:.2f}".rstrip("0").rstrip(".")


@dataclass
class Scene:
    """A drawing canvas. Coordinates: x right, y down (SVG convention)."""
    width: int
    height: int
    elements: list[str] = field(default_factory=list)

    # -- setup ------------------------------------------------------------
    def card(self) -> "Scene":
        """White rounded background card so diagrams survive dark mode."""
        self.elements.append(
            f'<rect x="2" y="2" width="{self.width - 4}" height="{self.height - 4}" '
            f'rx="12" ry="12" fill="{CARD_BG}" stroke="#E2E8F0" stroke-width="2"/>')
        return self

    # -- primitives ---------------------------------------------------------
    def line(self, x1: float, y1: float, x2: float, y2: float,
             stroke: str = INK, width: float = 2.0, dashed: bool = False) -> "Scene":
        dash = ' stroke-dasharray="6,5"' if dashed else ""
        self.elements.append(
            f'<line x1="{_n(x1)}" y1="{_n(y1)}" x2="{_n(x2)}" y2="{_n(y2)}" '
            f'stroke="{stroke}" stroke-width="{width}" stroke-linecap="round"{dash}/>')
        return self

    def arrow(self, x1: float, y1: float, x2: float, y2: float,
              stroke: str = INK, width: float = 2.0, dashed: bool = False,
              head: float = 9.0) -> "Scene":
        """Line with a filled triangular head at (x2, y2)."""
        self.line(x1, y1, x2, y2, stroke, width, dashed)
        ang = math.atan2(y2 - y1, x2 - x1)
        a1, a2 = ang + math.radians(153), ang - math.radians(153)
        hx1, hy1 = x2 + head * math.cos(a1), y2 + head * math.sin(a1)
        hx2, hy2 = x2 + head * math.cos(a2), y2 + head * math.sin(a2)
        self.elements.append(
            f'<polygon points="{_n(x2)},{_n(y2)} {_n(hx1)},{_n(hy1)} {_n(hx2)},{_n(hy2)}" '
            f'fill="{stroke}"/>')
        return self

    def circle(self, cx: float, cy: float, r: float, stroke: str = INK,
               width: float = 2.0, fill: str = "none") -> "Scene":
        self.elements.append(
            f'<circle cx="{_n(cx)}" cy="{_n(cy)}" r="{_n(r)}" fill="{fill}" '
            f'stroke="{stroke}" stroke-width="{width}"/>')
        return self

    def dot(self, cx: float, cy: float, r: float = 3.5, fill: str = INK) -> "Scene":
        self.elements.append(
            f'<circle cx="{_n(cx)}" cy="{_n(cy)}" r="{_n(r)}" fill="{fill}"/>')
        return self

    def rect(self, x: float, y: float, w: float, h: float, stroke: str = INK,
             width: float = 2.0, fill: str = "none", rounded: float = 0.0) -> "Scene":
        rx = f' rx="{_n(rounded)}" ry="{_n(rounded)}"' if rounded else ""
        self.elements.append(
            f'<rect x="{_n(x)}" y="{_n(y)}" width="{_n(w)}" height="{_n(h)}" '
            f'fill="{fill}" stroke="{stroke}" stroke-width="{width}"{rx}/>')
        return self

    def polygon(self, pts: list[tuple[float, float]], stroke: str = INK,
                width: float = 2.0, fill: str = "none") -> "Scene":
        p = " ".join(f"{_n(x)},{_n(y)}" for x, y in pts)
        self.elements.append(
            f'<polygon points="{p}" fill="{fill}" stroke="{stroke}" '
            f'stroke-width="{width}" stroke-linejoin="round"/>')
        return self

    def polyline(self, pts: list[tuple[float, float]], stroke: str = INK,
                 width: float = 2.5, dashed: bool = False) -> "Scene":
        p = " ".join(f"{_n(x)},{_n(y)}" for x, y in pts)
        dash = ' stroke-dasharray="6,5"' if dashed else ""
        self.elements.append(
            f'<polyline points="{p}" fill="none" stroke="{stroke}" '
            f'stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"{dash}/>')
        return self

    def path(self, d: str, stroke: str = INK, width: float = 2.0,
             fill: str = "none", dashed: bool = False) -> "Scene":
        dash = ' stroke-dasharray="6,5"' if dashed else ""
        self.elements.append(
            f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"'
            f'{dash}/>')
        return self

    def arc_path(self, cx: float, cy: float, r: float, a1_deg: float,
                 a2_deg: float, stroke: str = INK, width: float = 2.0) -> "Scene":
        """Circular arc from angle a1 to a2 (degrees, math convention: 0 = +x,
        CCW positive — converted to SVG's y-down coordinates)."""
        x1 = cx + r * math.cos(math.radians(a1_deg))
        y1 = cy - r * math.sin(math.radians(a1_deg))
        x2 = cx + r * math.cos(math.radians(a2_deg))
        y2 = cy - r * math.sin(math.radians(a2_deg))
        sweep = 0 if (a2_deg - a1_deg) % 360 <= 180 else 1
        self.elements.append(
            f'<path d="M {_n(x1)},{_n(y1)} A {_n(r)},{_n(r)} 0 0 {sweep} '
            f'{_n(x2)},{_n(y2)}" fill="none" stroke="{stroke}" stroke-width="{width}"/>')
        return self

    def angle_mark(self, cx: float, cy: float, r: float, a1_deg: float,
                   a2_deg: float, stroke: str = AMBER) -> "Scene":
        self.arc_path(cx, cy, r, a1_deg, a2_deg, stroke, 1.6)
        return self

    def text(self, x: float, y: float, s: str, size: int = 15, color: str = INK,
             anchor: str = "middle", bold: bool = False, italic: bool = False) -> "Scene":
        w = ' font-weight="bold"' if bold else ""
        it = ' font-style="italic"' if italic else ""
        self.elements.append(
            f'<text x="{_n(x)}" y="{_n(y)}" font-family="{FONT}" font-size="{size}" '
            f'fill="{color}" text-anchor="{anchor}"{w}{it}>{esc(s)}</text>')
        return self

    # -- circuit symbols ------------------------------------------------------
    def resistor(self, x1: float, y1: float, x2: float, y2: float,
                 label: str = "", stroke: str = INK, zig: float = 7.0) -> "Scene":
        """Zig-zag resistor between two points, label offset perpendicular."""
        self.line(x1, y1, x2, y2, stroke, 2.0)
        dx, dy = x2 - x1, y2 - y1
        L = math.hypot(dx, dy)
        if L == 0:
            return self
        ux, uy = dx / L, dy / L          # along
        px, py = -uy, ux                  # perpendicular
        frac = [0.30, 0.40, 0.50, 0.60, 0.70]
        side = [1, -1, 1, -1, 1]
        pts = [(x1, y1)]
        for f, s in zip(frac, side):
            bx, by = x1 + f * dx, y1 + f * dy
            pts.append((bx + s * zig * px, by + s * zig * py))
        pts.append((x2, y2))
        self.polyline(pts, stroke, 2.0)
        if label:
            mx, my = x1 + 0.5 * dx + 18 * px, y1 + 0.5 * dy + 18 * py
            self.text(mx, my + 5, label, 15, stroke, bold=True)
        return self

    def battery(self, x1: float, y1: float, x2: float, y2: float,
                label: str = "", stroke: str = INK) -> "Scene":
        """Battery symbol (long plate = +) at midpoint of the segment."""
        self.line(x1, y1, x2, y2, stroke, 2.0)
        dx, dy = x2 - x1, y2 - y1
        L = math.hypot(dx, dy)
        if L == 0:
            return self
        ux, uy = dx / L, dy / L
        px, py = -uy, ux
        mx, my = (x1 + x2) / 2, (y1 + y2) / 2
        # erase centre, draw plates
        self.line(mx - 1.6 * ux * 14, my - 1.6 * uy * 14,
                  mx + 1.6 * ux * 14, my + 1.6 * uy * 14, CARD_BG, 4.0)
        # long plate (+) and short plate (-)
        for off, half, wdt in ((-5, 12, 2.6), (5, 6, 2.6)):
            ax, ay = mx + off * ux, my + off * uy
            self.line(ax - half * px, ay - half * py, ax + half * px, ay + half * py,
                      stroke, wdt)
        self.dot(mx - 5 * ux - 12 * px, my - 5 * uy - 12 * py, 1.0, CARD_BG)
        if label:
            self.text(mx + 20 * px + 12 * ux, my + 20 * py + 12 * uy + 5,
                      label, 15, stroke, bold=True)
        return self

    def dot_junction(self, x: float, y: float) -> "Scene":
        self.dot(x, y, 4.0, INK)
        return self

    # -- graphs ---------------------------------------------------------------
    def axes(self, x0: float, y0: float, w: float, h: float,
             x_label: str = "", y_label: str = "", grid: bool = False,
             nx: int = 4, ny: int = 4) -> "Scene":
        if grid:
            for i in range(1, nx + 1):
                self.line(x0 + w * i / nx, y0 - h - 8, x0 + w * i / nx, y0,
                          GRID, 1.0)
            for j in range(1, ny + 1):
                self.line(x0, y0 - h * j / ny, x0 + w + 8, y0 - h * j / ny,
                          GRID, 1.0)
        self.arrow(x0 - 6, y0, x0 + w + 14, y0, AXIS, 2.2)          # x axis
        self.arrow(x0, y0 + 6, x0, y0 - h - 14, AXIS, 2.2)          # y axis
        if x_label:
            self.text(x0 + w / 2, y0 + 30, x_label, 14, AXIS)
        if y_label:
            self.text(x0 - 14, y0 - h / 2, y_label, 14, AXIS)
        return self

    # -- output ----------------------------------------------------------------
    def render(self) -> str:
        body = "\n".join(self.elements)
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.width}" '
                f'height="{self.height}" viewBox="0 0 {self.width} {self.height}">\n'
                f"{body}\n</svg>\n")

    def save(self, folder: "Path") -> str:  # noqa: F821 - Path via caller
        raise NotImplementedError  # caller writes; kept out to avoid IO in lib


def write_svg(folder, name: str, scene: Scene) -> str:
    """Write scene to folder/name; returns the filename (schema `diagram`)."""
    folder.mkdir(parents=True, exist_ok=True)
    (folder / name).write_text(scene.render(), encoding="utf-8")
    return name


# =============================================================================
# Selftest — XML well-formedness + geometry checks for every primitive.
# =============================================================================
def _selftest() -> None:
    # 1. render is well-formed XML with svg root
    s = Scene(300, 200).card()
    s.line(10, 10, 100, 80).arrow(10, 100, 150, 100, RED).circle(200, 60, 30, ACCENT)
    s.dot(200, 60, 4, RED).rect(20, 120, 60, 40, rounded=6).text(150, 170, "A<B & C")
    s.polygon([(1, 1), (2, 2), (3, 1)]).polyline([(0, 0), (5, 5)])
    s.path("M 1,1 L 2,2").arc_path(150, 100, 40, 0, 90).angle_mark(150, 100, 30, 0, 45)
    root = ET.fromstring(s.render())
    assert root.tag.endswith("svg") and root.get("width") == "300"

    # 2. escaping: label containing < > & must survive round-trip
    s2 = Scene(100, 50).text(50, 25, "F < ma & q > 0")
    assert "F &lt; ma &amp; q &gt; 0" in s2.render()
    ET.fromstring(s2.render())

    # 3. arrowhead geometry: head tip sits exactly at the endpoint
    x2, y2 = 200.0, 100.0
    s3 = Scene(300, 200).arrow(50, 100, x2, y2)
    pts = [e for e in s3.elements if e.startswith('<polygon')]
    assert pts and pts[0].startswith(f'<polygon points="{_n(x2)},{_n(y2)}')

    # 4. battery: two plates drawn (long + short) as <line> elements with
    #    distinct half-lengths -> verify stroke-width of plates present
    s4 = Scene(300, 100).battery(20, 50, 280, 50, "12 V")
    assert 'stroke-width="2.6"' in s4.render() and "12 V" in s4.render()

    # 5. resistor zig-zag: polyline has 7 points (2 ends + 5 zigzags)
    s5 = Scene(300, 100).resistor(20, 50, 280, 50, "R")
    poly = [e for e in s5.elements if e.startswith('<polyline')][0]
    npts = len(poly.split('points="')[1].split('"')[0].split())
    assert npts == 7 and ">R<" in s5.render()

    # 6. dashed flag appears
    s6 = Scene(200, 100).line(10, 10, 190, 90, dashed=True)
    assert 'stroke-dasharray="6,5"' in s6.render()

    # 7. determinism: identical calls -> identical output
    def build() -> str:
        sc = Scene(200, 100).card().arrow(10, 50, 180, 50)
        sc.circle(100, 50, 20).text(100, 30, "μ")
        return sc.render()
    assert build() == build()

    # 8. number formatting compacts ints
    assert _n(4.0) == "4" and _n(4.25) == "4.25" and _n(-0.005) == "-0.01"

    print("svg_diagrams selftest: 8/8 checks passed")


if __name__ == "__main__":
    _selftest()
