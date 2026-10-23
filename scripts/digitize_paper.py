"""Extract the curves of the figures of Appelbe et al., Phys. Plasmas 26, 102704 (2019) from the paper's vector graphics.

The figures of the paper PDF (references/appelbe-2019.pdf, git-ignored) are vector drawings: every curve is a filled
outline of the stroked line (one closed path for a solid line, one closed sub-path per dash for a dashed line), and the
axis ticks are thin filled rectangles. ``mutool trace`` dumps these paths with their colours in page coordinates.

For each panel the axes are calibrated by a least-squares fit of the detected tick positions to the tick values read
from the figure (the residual is checked), and each curve is reduced to its centre line: at the abscissa of every
outline vertex, the midpoint of the two crossings of the outline (exact on the straight segments of a polyline, whatever
the slope). No pixel rendering is involved, so the accuracy is set by the PDF coordinates (1e-3 pt, i.e. about 1e-5 of
an axis span) and the stroke joins (a few 1e-4 of the span), two orders of magnitude better than a 300 dpi raster.

The same extraction gives the Epperlein-Haines fit of (beta_par - beta_perp)/chi at Z = 1 from Fig. 4(a) of Davies et
al., Phys. Plasmas 28, 012305 (2021) (references/davies-2021.pdf, the OSTI accepted manuscript, git-ignored), where the
curves are stroked polylines and are taken as they are. It is needed to re-form the paper's Fig. 5 with the
Epperlein-Haines beta_perp that the paper used.

Output: ``report/data/<source>_<panel>_<curve>.dat``, one file per curve, with a provenance header.

Usage (from the repository root)::

    python3 scripts/digitize_paper.py
"""

from __future__ import annotations

import logging
import re
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from xml.etree import ElementTree as ET

import numpy as np

log = logging.getLogger(__name__)

PDF = Path("references/appelbe-2019.pdf")
DAVIES = Path("references/davies-2021.pdf")
OUT = Path("report/data")

BLUE = "0 0 1"
RED = "1 0 0"
CYAN = "0 1 1"
MAGENTA = "1 0 1"
BLACK = "0 0 0"
GREEN_FIG1 = "0 .49804 0"
GREEN = "0 .50196 0"
DAVIES_BLUE = ".878906 .765625 0 0"

Point = tuple[float, float]


@dataclass
class Curve:
    """One curve of a panel.

    Parameters
    ----------
    label : str
        Output label (``paper_<panel>_<label>.dat``).
    colour : str
        Fill colour of the outline as written by ``mutool trace``.
    style : str
        ``solid`` (one closed outline), ``dashed`` (many dash outlines), ``dotted`` (many dot outlines) or ``stroke``
        (a stroked polyline, taken as it is).
    """

    label: str
    colour: str
    style: str = "solid"


@dataclass
class Panel:
    """One plot panel.

    Parameters
    ----------
    name : str
        Output file stem (``paper_<name>_<curve>.dat``).
    page : int
        PDF page (1-based) holding the figure.
    region : tuple[float, float, float, float]
        Search box (x0, x1, y0, y1) in page points (y downwards) enclosing the axis frame and its ticks.
    xticks, yticks : list[float]
        Tick values read from the figure, in increasing page coordinate (left to right, top to bottom).
    xlog : bool
        Logarithmic x axis.
    curves : list[Curve]
        Curves to extract.
    pdf : Path
        Source document.
    source : str
        Output file prefix.
    """

    name: str
    page: int
    region: tuple[float, float, float, float]
    xticks: list[float]
    yticks: list[float]
    xlog: bool = False
    curves: list[Curve] = field(default_factory=list)
    pdf: Path = PDF
    source: str = "paper"


def ticks(*values: float) -> list[float]:
    """Tick values as a list (helper for the panel table).

    Parameters
    ----------
    *values : float
        Tick values.

    Returns
    -------
    list[float]
        The values.
    """
    return list(values)


PANELS = [
    Panel("fig1", 6, (60, 310, 500, 640), ticks(0, 0.5, 1, 1.5, 2, 2.5, 3), ticks(1, 0.5, 0, -0.5, -1),
          curves=[Curve("f0", BLACK, "dotted"), Curve("f1_wt0", BLUE), Curve("f1perp_wt10", RED),
                  Curve("f1wedge_wt10", GREEN_FIG1)]),
    Panel("fig2", 6, (320, 570, 90, 220), ticks(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0),
          ticks(1, 0, -1, -2, -3, -4, -5, -6, -7), xlog=True,
          curves=[Curve("proton", CYAN), Curve("alpha", MAGENTA), Curve("carbon", BLACK)]),
    Panel("fig3_j", 6, (320, 570, 370, 500), ticks(-3, -2, -1, 0, 1, 2, 3), ticks(1.5, 1, 0.5, 0, -0.5, -1, -1.5),
          curves=[Curve("perp_v1", BLUE), Curve("perp_v0.33", RED), Curve("perp_v0.2", CYAN),
                  Curve("perp_v0.05", BLACK), Curve("wedge_v1", BLUE, "dashed"), Curve("wedge_v0.33", RED, "dashed"),
                  Curve("wedge_v0.2", CYAN, "dashed"), Curve("wedge_v0.05", BLACK, "dashed")]),
    Panel("fig3_zeta", 6, (320, 570, 505, 625), ticks(-3, -2, -1, 0, 1, 2, 3), ticks(15, 10, 5, 0),
          curves=[Curve("perp_v1", BLUE), Curve("perp_v0.33", RED), Curve("perp_v0.2", CYAN),
                  Curve("perp_v0.05", BLACK), Curve("wedge_v1", BLUE, "dashed"), Curve("wedge_v0.33", RED, "dashed"),
                  Curve("wedge_v0.2", CYAN, "dashed"), Curve("wedge_v0.05", BLACK, "dashed")]),
    Panel("fig4", 7, (55, 310, 530, 665), ticks(2, 4, 6, 8, 10, 12, 14), ticks(3e-14, 2e-14, 1e-14, 0, -1e-14, -2e-14),
          curves=[Curve("q_j", BLUE), Curve("q_zeta", GREEN), Curve("q_sum", RED, "dashed")]),
    Panel("fig5_perp", 8, (55, 310, 95, 225), ticks(-3, -2, -1, 0, 1, 2, 3),
          ticks(9e-16, 8.5e-16, 8e-16, 7.5e-16, 7e-16, 6.5e-16, 6e-16, 5.5e-16),
          curves=[Curve("Te1keV", BLUE), Curve("Te15keV", GREEN)]),
    Panel("fig5_wedge", 8, (55, 310, 240, 365), ticks(-3, -2, -1, 0, 1, 2, 3),
          ticks(2e-17, 0, -2e-17, -4e-17, -6e-17, -8e-17, -10e-17),
          curves=[Curve("Te1keV", BLUE), Curve("Te15keV", GREEN)]),
    Panel("fig6", 9, (320, 570, 90, 215), [k * 10.0**e for e in (-4, -3, -2) for k in range(1, 10)] + [0.1],
          ticks(1, 0.95, 0.9, 0.85, 0.8), xlog=True,
          curves=[Curve("K_1keV", BLUE), Curve("mu_1keV", BLUE, "dashed"), Curve("K_5keV", RED),
                  Curve("mu_5keV", RED, "dashed"), Curve("K_10keV", BLACK), Curve("mu_10keV", BLACK, "dashed")]),
    Panel("fig4a", 18, (220, 420, 70, 215), ticks(0, 2, 4, 6, 8, 10), ticks(0.8, 0.6, 0.4, 0.2, 0, -0.2),
          curves=[Curve("EH_beta_new", DAVIES_BLUE, "stroke")], pdf=DAVIES, source="davies2021"),
]


@dataclass
class Path2D:
    """A filled path in page coordinates (points, y downwards).

    Parameters
    ----------
    colour : str
        Fill or stroke colour.
    subs : list[list[Point]]
        Sub-paths (closed outlines for filled paths).
    stroked : bool
        Stroked path (a polyline) rather than a filled one.
    """

    colour: str
    subs: list[list[Point]]
    stroked: bool = False

    def bbox(self) -> tuple[float, float, float, float]:
        """Bounding box (x0, x1, y0, y1).

        Returns
        -------
        tuple[float, float, float, float]
            The box.
        """
        pts = np.array([p for s in self.subs for p in s])
        return float(pts[:, 0].min()), float(pts[:, 0].max()), float(pts[:, 1].min()), float(pts[:, 1].max())


def trace(pdf: Path, page: int) -> list[Path2D]:
    """Filled and stroked paths of one PDF page, from ``mutool trace``.

    Parameters
    ----------
    pdf : Path
        Document.
    page : int
        1-based page number.

    Returns
    -------
    list[Path2D]
        Paths in page coordinates; Bezier segments are replaced by their end points (curves are polylines).
    """
    xml = subprocess.run(["mutool", "trace", str(pdf), str(page)], check=True, capture_output=True, text=True).stdout
    root = ET.fromstring("<root>" + re.sub(r"<\?xml[^>]*\?>", "", xml) + "</root>")
    paths = []
    for el in root.iter():
        if el.tag not in ("fill_path", "stroke_path"):
            continue
        a, b, c, d, e, f = map(float, el.get("transform", "1 0 0 1 0 0").split())
        subs: list[list[Point]] = []
        for node in el:
            if node.tag == "moveto":
                subs.append([])
            if node.tag in ("moveto", "lineto"):
                x, y = float(node.get("x", "0")), float(node.get("y", "0"))
            elif node.tag == "curveto":
                x, y = float(node.get("x3", "0")), float(node.get("y3", "0"))
            else:
                continue
            subs[-1].append((a * x + c * y + e, b * x + d * y + f))
        if subs:
            paths.append(Path2D(el.get("color", ""), subs, el.tag == "stroke_path"))
    return paths


def inside(box: tuple[float, float, float, float], region: tuple[float, float, float, float]) -> bool:
    """Whether a bounding box lies within a region.

    Parameters
    ----------
    box, region : tuple[float, float, float, float]
        (x0, x1, y0, y1) boxes.

    Returns
    -------
    bool
        True if box is inside region.
    """
    return box[0] >= region[0] and box[1] <= region[1] and box[2] >= region[2] and box[3] <= region[3]


def calibrate(panel: Panel, paths: list[Path2D]) -> tuple[np.ndarray, np.ndarray, tuple[float, float, float, float]]:
    """Fit the page-to-data maps of both axes to the tick marks.

    Ticks are thin black rectangles (< 0.3 pt thick, < 5 pt long) touching the bottom (x ticks) or left (y ticks) frame
    line; the frame is the extent of the long black lines in the region.

    Parameters
    ----------
    panel : Panel
        Panel description.
    paths : list[Path2D]
        Paths of the page.

    Returns
    -------
    tuple[np.ndarray, np.ndarray, tuple[float, float, float, float]]
        Linear maps (slope, intercept) page -> data (log10 data for a log axis) for x and y, and the frame box.
    """
    black = [p for p in paths if p.colour in (BLACK, "0 0 0 1") and inside(p.bbox(), panel.region)]
    # the frame is drawn as thin rectangles, one rectangular outline of up to 16 vertices, or stroked segments; ticks
    # are thin rectangles or stroked segments (one sub-path each)
    boxes = [p.bbox() for p in black if sum(len(s) for s in p.subs) <= 16]
    boxes += [Path2D(p.colour, [s]).bbox() for p in black for s in p.subs if len(s) <= 5]
    lines = [b for b in boxes if b[1] - b[0] > 100 or b[3] - b[2] > 60]
    frame = (min(r[0] for r in lines), max(r[1] for r in lines), min(r[2] for r in lines), max(r[3] for r in lines))
    rects = [b for b in boxes if b[1] - b[0] < 5 and b[3] - b[2] < 5]
    xt = sorted({round(0.5 * (r[0] + r[1]), 3) for r in rects
                 if r[1] - r[0] < 0.3 and r[3] - r[2] < 5 and abs(r[3] - frame[3]) < 0.3})
    yt = sorted({round(0.5 * (r[2] + r[3]), 3) for r in rects
                 if r[3] - r[2] < 0.3 and r[1] - r[0] < 5 and abs(r[0] - frame[0]) < 0.3})
    maps = []
    for name, pos, values, logscale in (("x", xt, panel.xticks, panel.xlog), ("y", yt, panel.yticks, False)):
        if len(pos) != len(values):
            raise SystemExit(f"{panel.name}: found {len(pos)} {name} ticks at {pos}, expected {len(values)}")
        target = np.log10(values) if logscale else np.array(values)
        coef = np.polyfit(pos, target, 1)
        span = abs(target[-1] - target[0])
        residual = float(np.abs(np.polyval(coef, pos) - target).max()) / span
        if residual > 1e-3:
            raise SystemExit(f"{panel.name}: {name} ticks not evenly mapped (residual {residual:.1e} of span)")
        log.info("%s: %s axis from %d ticks, max residual %.1e of the span", panel.name, name, len(pos), residual)
        maps.append(coef)
    return maps[0], maps[1], frame


def opposite_points(poly: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """For each vertex of a stroke outline, its projection on the nearest antiparallel edge and the distance to it.

    A stroke outline runs forward along one side of the line and back along the other, so the edge facing a vertex
    across the stroke is antiparallel to the local outline direction; same-side edges (parallel) are ignored, as are the
    two edges meeting at the vertex considered (the end caps, perpendicular, fail the antiparallel test).

    Parameters
    ----------
    poly : np.ndarray
        Closed outline (n, 2), without the repeated closing vertex.

    Returns
    -------
    tuple[np.ndarray, np.ndarray]
        Projections (n, 2) and distances (n,); the distance is inf where no antiparallel edge exists.
    """
    n = len(poly)
    a, b = poly, np.roll(poly, -1, axis=0)
    edge = b - a
    length2 = np.maximum((edge**2).sum(axis=1), 1e-12)
    unit = edge / np.sqrt(length2)[:, None]
    tangent = np.roll(poly, -1, axis=0) - np.roll(poly, 1, axis=0)
    tangent /= np.maximum(np.linalg.norm(tangent, axis=1), 1e-12)[:, None]
    proj = np.zeros_like(poly)
    dist = np.full(n, np.inf)
    for i in range(n):
        t = np.clip(((poly[i] - a) * edge).sum(axis=1) / length2, 0.0, 1.0)
        foot = a + t[:, None] * edge
        d = np.linalg.norm(foot - poly[i], axis=1)
        d[[i, i - 1]] = np.inf
        d[(unit @ tangent[i]) > -0.5] = np.inf
        j = int(np.argmin(d))
        proj[i], dist[i] = foot[j], d[j]
    return proj, dist


def centre_line(curve: Curve, path: Path2D) -> list[Point]:
    """Centre line of a stroked curve from its filled outline (page coordinates).

    Solid and dashed lines: the midpoint of every outline vertex and its projection on the opposite side of the stroke
    (exact on straight segments, whatever the slope; vertices whose opposite side is not one stroke width away, such
    as the corners of the end caps, are skipped). Dotted lines: the centroid of each dot.

    Parameters
    ----------
    curve : Curve
        Curve description.
    path : Path2D
        Its outline.

    Returns
    -------
    list[Point]
        Centre-line points sorted by abscissa.
    """
    if curve.style == "stroke":
        return sorted(path.subs[0])
    if curve.style == "dotted":
        # centroid of the distinct vertices (the closing vertex repeats the first one)
        return sorted((float(np.mean([p[0] for p in set(s)])), float(np.mean([p[1] for p in set(s)])))
                      for s in path.subs)
    found = []
    for sub in path.subs:
        poly = np.array(sub)
        if np.allclose(poly[0], poly[-1]):
            poly = poly[:-1]
        if len(poly) >= 4:
            found.append((poly, *opposite_points(poly)))
    width = float(np.median(np.concatenate([d[np.isfinite(d)] for _, _, d in found])))
    points = set()
    for poly, proj, dist in found:
        keep = np.abs(dist - width) < 0.15 * width
        a, edge = poly, np.roll(poly, -1, axis=0) - poly
        length2 = np.maximum((edge**2).sum(axis=1), 1e-12)
        for p, q in zip(poly[keep], proj[keep], strict=True):
            mid = 0.5 * (p + q)
            # a centre-line point is half a stroke width from the whole outline; a wrong pairing at a dash end is not
            # (solid lines keep their end points, the cap centres, which are exact)
            t = np.clip(((mid - a) * edge).sum(axis=1) / length2, 0.0, 1.0)
            if curve.style == "solid" or np.linalg.norm(a + t[:, None] * edge - mid, axis=1).min() >= 0.4 * width:
                points.add((round(float(mid[0]), 4), round(float(mid[1]), 4)))
    return sorted(points)


def digitize(panel: Panel, paths: list[Path2D]) -> None:
    """Extract every curve of a panel and write ``report/data/paper_<name>_<curve>.dat``.

    Parameters
    ----------
    panel : Panel
        Panel description.
    paths : list[Path2D]
        Paths of the page.
    """
    xmap, ymap, frame = calibrate(panel, paths)
    for curve in panel.curves:
        # the plotted curve is the widest path of its colour and style; legend samples are short
        candidates = [p for p in paths if p.colour == curve.colour and inside(p.bbox(), panel.region)
                      and p.stroked == (curve.style == "stroke") and sum(len(s) for s in p.subs) > 16]
        if curve.style != "stroke":
            candidates = [p for p in candidates if (len(p.subs) > 1) == (curve.style != "solid")]
        path = max(candidates, key=lambda p: p.bbox()[1] - p.bbox()[0])
        line = [(x, y) for x, y in centre_line(curve, path)
                if frame[0] <= x <= frame[1] and frame[2] <= y <= frame[3]]
        out = OUT / f"{panel.source}_{panel.name}_{curve.label}.dat"
        with out.open("w") as f:
            f.write(f"# Extracted from the vector graphics of {panel.pdf.name}: {panel.name}, curve {curve.label} "
                    f"(PDF page {panel.page}, {'polyline' if curve.style == 'stroke' else 'outline centre line'}).\n")
            f.write("# x y\n")
            for x, y in line:
                xd = float(np.polyval(xmap, x))
                f.write(f"{10.0**xd if panel.xlog else xd:.8e} {float(np.polyval(ymap, y)):.8e}\n")
        log.info("%s %s: %d points", panel.name, curve.label, len(line))


def main() -> None:
    """Digitize every panel."""
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    for pdf in (PDF, DAVIES):
        if not pdf.exists():
            raise SystemExit(f"{pdf} not found: the source documents are needed (they are git-ignored)")
    OUT.mkdir(parents=True, exist_ok=True)
    pages: dict[tuple[Path, int], list[Path2D]] = {}
    for panel in PANELS:
        key = (panel.pdf, panel.page)
        if key not in pages:
            pages[key] = trace(*key)
        digitize(panel, pages[key])


if __name__ == "__main__":
    main()
