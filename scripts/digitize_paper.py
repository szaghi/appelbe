"""Digitize curves from the figures of Appelbe et al., Phys. Plasmas 26, 102704 (2019).

The paper PDF (references/appelbe-2019.pdf, git-ignored) is rendered at 300 dpi with ``pdftoppm``; each figure is
calibrated from its axis frame (the frame corners carry the axis-limit labels in all digitized figures), curves are
extracted by colour, legends are masked, and solid/dashed curves of the same colour are separated by their vertical
order. Output: ``report/data/paper_<panel>_<curve>.dat``, one file per curve, with a provenance header.

Usage (from the repository root)::

    python3 scripts/digitize_paper.py

Accuracy is limited by line width (about 3 px at 300 dpi, i.e. 0.3-0.6 % of the axis span).
"""

from __future__ import annotations

import logging
import subprocess
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
from PIL import Image

log = logging.getLogger(__name__)

PDF = Path("references/appelbe-2019.pdf")
OUT = Path("report/data")
DPI = 300

# reference colours (RGB) of the MATLAB line styles in the paper
BLUE = (0, 0, 255)
GREEN = (0, 128, 0)
RED = (255, 0, 0)
CYAN = (0, 255, 255)
MAGENTA = (255, 0, 255)
BLACK = (0, 0, 0)


@dataclass
class Panel:
    """One plot panel: page, crop box, axis limits, curves and legend masks.

    Parameters
    ----------
    name : str
        Output file stem (``paper_<name>_<curve>.dat``).
    page : int
        PDF page (1-based) holding the figure.
    box : tuple[int, int, int, int]
        Crop box (left, top, right, bottom) in 300-dpi pixels enclosing exactly one axis frame.
    xlim, ylim : tuple[float, float]
        Axis limits at the frame edges.
    xlog : bool
        Logarithmic x axis.
    curves : list[tuple[str, tuple[int, int, int], str]]
        (curve label, colour, selector) with selector ``single``, ``upper`` or ``lower``.
    masks : list[tuple[float, float, float, float]]
        Legend boxes to ignore, as frame fractions (x0, y0, x1, y1), y measured downwards from the top.
    """

    name: str
    page: int
    box: tuple[int, int, int, int]
    xlim: tuple[float, float]
    ylim: tuple[float, float]
    xlog: bool = False
    curves: list[tuple[str, tuple[int, int, int], str]] = field(default_factory=list)
    masks: list[tuple[float, float, float, float]] = field(default_factory=list)


PANELS = [
    Panel("fig2", 6, (1365, 380, 2420, 1040), (0.1, 1.0), (-7.0, 1.0), xlog=True,
          curves=[("proton", CYAN, "single"), ("alpha", MAGENTA, "single"), ("carbon", BLACK, "single")],
          masks=[(0.80, 0.40, 1.00, 0.60)]),
    Panel("fig4", 7, (250, 2200, 1275, 2900), (1.0, 15.0), (-2.0e-14, 3.0e-14),
          curves=[("q_j", BLUE, "single"), ("q_zeta", GREEN, "single"), ("q_sum", RED, "single")],
          masks=[(0.0, 0.0, 0.25, 0.35)]),
    Panel("fig5_perp", 8, (250, 370, 1275, 960), (-3.0, 3.0), (5.0e-16, 9.0e-16),
          curves=[("Te1keV", BLUE, "single"), ("Te15keV", GREEN, "single")],
          masks=[(0.0, 0.0, 0.30, 0.25)]),
    Panel("fig5_wedge", 8, (250, 960, 1275, 1580), (-3.0, 3.0), (-1.0e-16, 2.0e-17),
          curves=[("Te1keV", BLUE, "single"), ("Te15keV", GREEN, "single")],
          masks=[]),
    Panel("fig6", 9, (1300, 370, 2420, 980), (1.0e-4, 1.0e-1), (0.8, 1.0), xlog=True,
          curves=[("K_1keV", BLUE, "upper"), ("mu_1keV", BLUE, "lower"),
                  ("K_5keV", RED, "upper"), ("mu_5keV", RED, "lower"),
                  ("K_10keV", BLACK, "upper"), ("mu_10keV", BLACK, "lower")],
          masks=[(0.0, 0.40, 0.40, 0.72)]),
]


def render(page: int, workdir: Path) -> Image.Image:
    """Render one PDF page at ``DPI`` with pdftoppm.

    Parameters
    ----------
    page : int
        1-based page number.
    workdir : Path
        Directory for the temporary PNG.

    Returns
    -------
    Image.Image
        The rendered page (RGB).
    """
    stem = workdir / f"page{page}"
    subprocess.run(["pdftoppm", "-f", str(page), "-l", str(page), "-r", str(DPI), "-png", "-singlefile",
                    str(PDF), str(stem)], check=True)
    return Image.open(f"{stem}.png").convert("RGB")


def find_frame(dark: np.ndarray) -> tuple[int, int, int, int]:
    """Locate the axis frame as the extreme long dark rows/columns of a crop.

    Parameters
    ----------
    dark : np.ndarray
        Boolean mask of dark pixels.

    Returns
    -------
    tuple[int, int, int, int]
        (left, top, right, bottom) pixel indices of the frame lines.
    """
    rows = np.where(dark.mean(axis=1) > 0.5)[0]
    top, bottom = int(rows[0]), int(rows[-1])
    # horizontal extent: the longest dark run along the top frame line (vertical frame lines can be faint)
    cols = np.where(dark[top])[0]
    breaks = np.where(np.diff(cols) > 1)[0]
    starts = np.concatenate(([0], breaks + 1))
    ends = np.concatenate((breaks, [cols.size - 1]))
    longest = int(np.argmax(ends - starts))
    return int(cols[starts[longest]]), top, int(cols[ends[longest]]), bottom


def colour_mask(rgb: np.ndarray, colour: tuple[int, int, int]) -> np.ndarray:
    """Pixels close to a reference colour (anti-aliasing tolerant).

    Parameters
    ----------
    rgb : np.ndarray
        Image array (H, W, 3), integers.
    colour : tuple[int, int, int]
        Reference colour.

    Returns
    -------
    np.ndarray
        Boolean mask.
    """
    if colour == BLACK:
        return (rgb.sum(axis=2) < 180) & ((rgb.max(axis=2) - rgb.min(axis=2)) < 40)
    return np.sqrt(((rgb - np.array(colour)) ** 2).sum(axis=2)) < 90


def clusters(rows: np.ndarray) -> list[float]:
    """Centres of runs of consecutive row indices (one run per line crossing a column).

    Parameters
    ----------
    rows : np.ndarray
        Sorted row indices of matching pixels in one column.

    Returns
    -------
    list[float]
        Run centres, top to bottom.
    """
    if rows.size == 0:
        return []
    breaks = np.where(np.diff(rows) > 2)[0]
    starts = np.concatenate(([0], breaks + 1))
    ends = np.concatenate((breaks, [rows.size - 1]))
    return [0.5 * (rows[s] + rows[e]) for s, e in zip(starts, ends, strict=True)]


def digitize(panel: Panel, page_img: Image.Image) -> None:
    """Extract every curve of a panel and write ``report/data/paper_<name>_<curve>.dat``.

    Parameters
    ----------
    panel : Panel
        Panel description.
    page_img : Image.Image
        Rendered page.
    """
    rgb = np.asarray(page_img.crop(panel.box)).astype(int)
    left, top, right, bottom = find_frame(rgb.sum(axis=2) < 300)
    width, height = right - left, bottom - top
    margin = 15  # skip the frame lines and the inward tick marks (about 10 px long)
    masked = np.zeros(rgb.shape[:2], dtype=bool)
    for x0, y0, x1, y1 in panel.masks:
        masked[top + int(y0 * height):top + int(y1 * height), left + int(x0 * width):left + int(x1 * width)] = True

    def to_x(col: float) -> float:
        t = (col - left) / width
        if panel.xlog:
            lo, hi = np.log10(panel.xlim[0]), np.log10(panel.xlim[1])
            return float(10.0 ** (lo + t * (hi - lo)))
        return panel.xlim[0] + t * (panel.xlim[1] - panel.xlim[0])

    def to_y(row: float) -> float:
        return panel.ylim[1] - (row - top) / height * (panel.ylim[1] - panel.ylim[0])

    OUT.mkdir(parents=True, exist_ok=True)
    for label, colour, selector in panel.curves:
        match = colour_mask(rgb, colour) & ~masked
        path = OUT / f"paper_{panel.name}_{label}.dat"
        points = 0
        previous: float | None = None
        with path.open("w") as out:
            out.write(f"# Digitized from Appelbe et al., Phys. Plasmas 26, 102704 (2019): {panel.name}, curve {label} "
                      f"(PDF page {panel.page}, {DPI} dpi, frame {left},{top},{right},{bottom} px in crop).\n")
            out.write("# x y\n")
            for col in range(left + margin, right - margin + 1, 4):
                rows = np.where(match[top + margin:bottom - margin, col])[0] + top + margin
                centres = clusters(rows)
                if selector == "single" and len(centres) >= 1:
                    # follow the curve: the crossing closest to the previous one (stray text, ticks rejected)
                    row = min(centres, key=lambda c: abs(c - previous)) if previous is not None else centres[0]
                    if previous is not None and abs(row - previous) > 0.08 * height:
                        continue
                elif selector in ("upper", "lower") and len(centres) == 2:
                    row = centres[0] if selector == "upper" else centres[1]
                else:
                    continue
                previous = row
                out.write(f"{to_x(col):.6e} {to_y(row):.6e}\n")
                points += 1
        log.info("%s %s: %d points", panel.name, label, points)


def main() -> None:
    """Digitize every panel."""
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    if not PDF.exists():
        raise SystemExit(f"{PDF} not found: the paper is needed (it is git-ignored)")
    with tempfile.TemporaryDirectory() as tmp:
        pages: dict[int, Image.Image] = {}
        for panel in PANELS:
            if panel.page not in pages:
                pages[panel.page] = render(panel.page, Path(tmp))
            digitize(panel, pages[panel.page])


if __name__ == "__main__":
    main()
