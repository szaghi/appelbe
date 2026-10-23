"""Generate the LaTeX numbers and tables of the report from the results of the last run.

Reads ``results/*.dat`` (written by the Fortran drivers) and ``report/data/*.dat`` (extracted from the figures of
Appelbe et al. 2019 and of Davies et al. 2021 by ``scripts/digitize_paper.py``) and writes ``report/generated/*.tex``:
a macro file with every number quoted in the text and one file per table, plus ``report/generated/fig5_eh_*.dat``
(Fig. 5 re-formed with the Epperlein-Haines fitted beta, the paper's choice). The report therefore always reflects the
last execution.

Usage (from the repository root, after ``fobis rule --ex figures``)::

    python3 scripts/report_numbers.py
"""

from __future__ import annotations

import logging
import math
import subprocess
from collections.abc import Callable
from pathlib import Path

import numpy as np

log = logging.getLogger(__name__)

RESULTS = Path("results")
PAPER = Path("report/data")
OUT = Path("report/generated")

KEV_J = 1.602176634e-16
M_E = 9.1093837015e-31
M_ALPHA = 6.6446573357e-27
E_ALPHA_J = 3.45e3 * KEV_J
Z_ALPHA = 2.0
# Epperlein & Haines, Phys. Fluids 29, 1029 (1986), Table III, Z = 1: fits of beta_perp and beta_wedge
EH_PERP = (1.05e3, 6.33, 3.71e3, 4.11e3, 5.15e2)  # beta'_0, beta'_1, b'_0, b'_1, b'_2
EH_WEDGE = (2.54, 1.5, 2.87, 3.27, 7.09)  # beta''_0, beta''_1, b''_0, b''_1, b''_2

Macros = dict[str, str]


def load(path: Path) -> np.ndarray:
    """Load a whitespace table, skipping '#' lines.

    Parameters
    ----------
    path : Path
        File to read.

    Returns
    -------
    np.ndarray
        2-D array (rows, columns).
    """
    return np.atleast_2d(np.loadtxt(path, comments="#"))


def load_validation() -> dict[str, tuple[float, float]]:
    """Read results/validation.dat into {key: (value, reference)}.

    Returns
    -------
    dict[str, tuple[float, float]]
        Validation entries.
    """
    entries: dict[str, tuple[float, float]] = {}
    for line in (RESULTS / "validation.dat").read_text().splitlines():
        if line.startswith("#") or not line.strip():
            continue
        key, value, reference = line.split()
        entries[key] = (float(value), float(reference))
    return entries


def sci(x: float, digits: int = 2) -> str:
    """Format a number as LaTeX scientific notation.

    Parameters
    ----------
    x : float
        Value.
    digits : int
        Decimal digits of the mantissa.

    Returns
    -------
    str
        e.g. ``$-4.79\\times10^{15}$``.
    """
    if x == 0.0:
        return "$0$"
    exponent = math.floor(math.log10(abs(x)))
    mantissa = x / 10.0**exponent
    if exponent == 0:
        return f"${mantissa:.{digits}f}$"
    return f"${mantissa:.{digits}f}\\times10^{{{exponent}}}$"


def fix(x: float, digits: int = 3) -> str:
    """Format a number in fixed notation inside math mode.

    Parameters
    ----------
    x : float
        Value.
    digits : int
        Decimal digits.

    Returns
    -------
    str
        e.g. ``$0.506$``.
    """
    return f"${x:.{digits}f}$"


def spline(x: np.ndarray, y: np.ndarray) -> Callable[[np.ndarray], np.ndarray]:
    """Natural cubic spline through (x, y), x increasing.

    Our curves are sampled every 0.1 in log10(omega tau); linear interpolation would add errors of 1e-3 relative where
    the agreement with the paper is itself at that level.

    Parameters
    ----------
    x, y : np.ndarray
        Nodes.

    Returns
    -------
    Callable[[np.ndarray], np.ndarray]
        The interpolant.
    """
    n = len(x)
    h = np.diff(x)
    a = np.zeros((n, n))
    r = np.zeros(n)
    a[0, 0] = a[-1, -1] = 1.0
    for i in range(1, n - 1):
        a[i, i - 1:i + 2] = [h[i - 1], 2.0 * (h[i - 1] + h[i]), h[i]]
        r[i] = 6.0 * ((y[i + 1] - y[i]) / h[i] - (y[i] - y[i - 1]) / h[i - 1])
    m = np.linalg.solve(a, r)

    def evaluate(t: np.ndarray) -> np.ndarray:
        t = np.asarray(t, dtype=float)
        k = np.clip(np.searchsorted(x, t) - 1, 0, n - 2)
        hk, left, right = h[k], x[k + 1] - t, t - x[k]
        return ((m[k] * left**3 + m[k + 1] * right**3) / (6.0 * hk) + (y[k] / hk - m[k] * hk / 6.0) * left
                + (y[k + 1] / hk - m[k + 1] * hk / 6.0) * right)

    return evaluate


def paper_curve(stem: str) -> np.ndarray:
    """A curve extracted from the paper, sorted by abscissa.

    Parameters
    ----------
    stem : str
        File stem inside report/data (``paper_<stem>.dat``).

    Returns
    -------
    np.ndarray
        (n, 2) array.
    """
    data = load(PAPER / f"paper_{stem}.dat")
    return data[np.argsort(data[:, 0])]


def vertices(stem: str) -> np.ndarray:
    """Vertices of a polyline curve of the paper (points closer than 1e-3 decade merged).

    Parameters
    ----------
    stem : str
        File stem inside report/data.

    Returns
    -------
    np.ndarray
        (n, 2) array of vertices.
    """
    data = paper_curve(stem)
    lx = np.log10(data[:, 0])
    groups = np.split(np.arange(len(lx)), np.where(np.diff(lx) > 1.0e-3)[0] + 1)
    return np.array([[10.0 ** lx[g].mean(), data[g, 1].mean()] for g in groups])


def deviation(x_ours: np.ndarray, y_ours: np.ndarray, paper: np.ndarray, xlog: bool = False) -> np.ndarray:
    """Our curve minus the paper's, at the paper's abscissae inside our range (spline interpolation).

    Parameters
    ----------
    x_ours, y_ours : np.ndarray
        Our curve.
    paper : np.ndarray
        (n, 2) paper curve.
    xlog : bool
        Interpolate in log10(x).

    Returns
    -------
    np.ndarray
        Differences.
    """
    xo, xq = (np.log10(x_ours), np.log10(paper[:, 0])) if xlog else (x_ours, paper[:, 0])
    order = np.argsort(xo)
    inside = (xq >= xo.min()) & (xq <= xo.max())
    return spline(xo[order], y_ours[order])(xq[inside]) - paper[inside, 1]


def compare(x_ours: np.ndarray, y_ours: np.ndarray, stem: str, xlog: bool = False) -> tuple[float, float]:
    """Max and RMS deviation from a paper curve, in percent of the largest |paper| value.

    Parameters
    ----------
    x_ours, y_ours : np.ndarray
        Our curve.
    stem : str
        Paper curve stem (``paper_<stem>.dat``).
    xlog : bool
        Interpolate in log10(x).

    Returns
    -------
    tuple[float, float]
        Max and RMS of |ours - paper| / max |paper|, in percent.
    """
    paper = paper_curve(stem)
    diff = deviation(x_ours, y_ours, paper, xlog)
    scale = np.abs(paper[:, 1]).max()
    return 100.0 * np.abs(diff).max() / scale, 100.0 * math.sqrt(float(np.mean(diff**2))) / scale


def write(name: str, text: str) -> None:
    """Write one generated file.

    Parameters
    ----------
    name : str
        File name inside report/generated.
    text : str
        Content.
    """
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / name).write_text(text)
    log.info("wrote %s", OUT / name)


def table(name: str, rows: list[str]) -> None:
    """Write a table body (rows already formatted, ``\\\\`` appended).

    Parameters
    ----------
    name : str
        File name inside report/generated.
    rows : list[str]
        Table rows without the line terminator.
    """
    write(name, "".join(f"{row} \\\\\n" for row in rows))


def omega_label(value: float) -> str:
    """Hall parameter formatted for a table cell (0 printed as 0).

    Parameters
    ----------
    value : float
        omega tau.

    Returns
    -------
    str
        Formatted cell.
    """
    return sci(value, 0) if value > 0.0 else "$0$"


def eh_beta(chi: np.ndarray) -> np.ndarray:
    """Epperlein-Haines fitted thermoelectric tensor at Z = 1, complex (perp, wedge) (their Sec. III E, Table III).

        beta_perp  = (beta'_1 chi + beta'_0) / (chi^3 + b'_2 chi^2 + b'_1 chi + b'_0)^(8/9)
        beta_wedge = chi (beta''_1 chi + beta''_0) / (chi^3 + b''_2 chi^2 + b''_1 chi + b''_0)

    Parameters
    ----------
    chi : np.ndarray
        Hall parameter omega tau.

    Returns
    -------
    np.ndarray
        beta_perp + i beta_wedge.
    """
    p0, p1, q0, q1, q2 = EH_PERP
    w0, w1, r0, r1, r2 = EH_WEDGE
    perp = (p1 * chi + p0) / (((chi + q2) * chi + q1) * chi + q0) ** (8.0 / 9.0)
    wedge = chi * (w1 * chi + w0) / (((chi + r2) * chi + r1) * chi + r0)
    return perp + 1j * wedge


def heat_flow(j: np.ndarray, zeta: np.ndarray, beta: np.ndarray) -> np.ndarray:
    """Normalised heat flow q / (n_a <v_a> T_keV) [W s keV^-1] of Eqs. (34)-(35), complex (perp, wedge).

    Parameters
    ----------
    j, zeta, beta : np.ndarray
        Complex j_nu, zeta_nu and beta.

    Returns
    -------
    np.ndarray
        Complex heat flow.
    """
    return KEV_J * (Z_ALPHA * (beta + 2.5) * j + zeta)


def fig5_variants(data: np.ndarray) -> dict[str, np.ndarray]:
    """Complex q of a fig5 results table for every combination of closure and thermoelectric tensor.

    Parameters
    ----------
    data : np.ndarray
        results/fig5_Te*.dat: x, q (4), beta, j, zeta (converged), j, zeta (fits), j, zeta, beta (paper's grid).

    Returns
    -------
    dict[str, np.ndarray]
        ``kinetic`` (converged closure, exact beta), ``eh_perp`` (converged, E&H beta_perp, exact beta_wedge), ``eh``
        (converged, E&H beta), ``paper`` (paper's grid, E&H beta: the paper's numerics), ``fit`` (Appendix C fits,
        E&H beta).
    """
    chi = 10.0 ** data[:, 0]

    def c(k: int) -> np.ndarray:
        return data[:, k] + 1j * data[:, k + 1]

    beta, j, zeta = c(5), c(7), c(9)
    eh = eh_beta(chi)
    return {"kinetic": heat_flow(j, zeta, beta), "eh_perp": heat_flow(j, zeta, eh.real + 1j * beta.imag),
            "eh": heat_flow(j, zeta, eh), "paper": heat_flow(c(15), c(17), eh), "fit": heat_flow(c(11), c(13), eh)}


def verification(macros: Macros) -> None:
    """Conventional coefficients, grid convergence, solver comparison.

    Parameters
    ----------
    macros : Macros
        Macro dictionary, updated.
    """
    val = load_validation()
    rows = [
        ("Lorentz gas $\\hat\\alpha$", "lorentz_alpha", "exact, $3\\pi/32$", 5),
        ("Lorentz gas $\\beta$", "lorentz_beta", "exact, $3/2$", 5),
        ("Lorentz gas $\\hat\\kappa$", "lorentz_kappa", "exact, $128/3\\pi$", 4),
        ("$Z=1$, $\\hat\\alpha_\\parallel$", "z1_alpha_par", "E\\&H (1986)", 4),
        ("$Z=1$, $\\beta_\\parallel$", "z1_beta_par", "E\\&H (1986)", 4),
        ("$Z=1$, $\\hat\\kappa_\\parallel$", "z1_kappa_par", "E\\&H (1986)", 4),
        ("$Z=1$, $\\hat\\alpha_\\parallel$", "z1_alpha_par_eq42", "paper, Eq.~(42)", 3),
    ]
    table("tab_validation.tex", [
        f"{label} & {fix(val[key][0], digits + 1)} & {fix(val[key][1], digits)} & {source} & "
        f"{sci(abs(val[key][0] - val[key][1]) / val[key][1], 1)}" for label, key, source, digits in rows])
    macros["OnsagerViolation"] = sci(val["onsager_max_rel_violation"][0], 1)
    macros["ZoneAlpha"] = fix(val["z1_alpha_par"][0], 4)
    macros["ZoneBeta"] = fix(val["z1_beta_par"][0], 4)
    macros["ZoneKappa"] = fix(val["z1_kappa_par"][0], 4)

    conv = load(RESULTS / "convergence.dat")
    table("tab_convergence.tex", [f"{int(row[0])} & {omega_label(row[1])} & " + " & ".join(sci(v, 1) for v in row[2:6])
                                  for row in conv if row[1] in (0.0, 1.0, 1.0e3)])
    at = {(int(r[0]), r[1]): r for r in conv}
    macros["ConvJfourOone"] = sci(at[(401, 1.0)][4], 1)
    macros["ConvJeightOone"] = sci(at[(801, 1.0)][4], 1)

    sol = load(RESULTS / "solvers.dat")
    table("tab_solvers.tex", [f"{int(row[0])} & {omega_label(row[1])} & {sci(row[2:6].max(), 1)} & {sci(row[6], 1)} & "
                              f"{sci(row[7], 1)} & {fix(row[8], 3)} & {fix(row[9], 3)}"
                              for row in sol if row[1] in (0.0, 1.0e-2, 1.0, 1.0e2)])
    magnetised = sol[sol[:, 1] > 0]
    macros["SolverMaxDiff"] = sci(magnetised[:, 2:6].max(), 1)
    macros["SolverMaxDiffFourOone"] = sci(magnetised[magnetised[:, 0] == 401][:, 2:6].max(), 1)
    macros["ResidualRatioMax"] = sci((magnetised[:, 7] / magnetised[:, 6]).max(), 0)
    big = sol[sol[:, 0] == 1601]
    macros["TimeComplexBig"] = fix(big[:, 8].mean(), 2)
    macros["TimePaperBig"] = fix(big[big[:, 1] > 0][:, 9].mean(), 2)


def extraction(macros: Macros) -> None:
    """Accuracy of the curve extraction: the dotted f0 of Fig. 1 against exp(-u^2).

    Parameters
    ----------
    macros : Macros
        Macro dictionary, updated.
    """
    f0 = paper_curve("fig1_f0")
    err = f0[:, 1] - np.exp(-f0[:, 0] ** 2)
    slope = -2.0 * f0[:, 0] * np.exp(-f0[:, 0] ** 2)
    coef, *_ = np.linalg.lstsq(np.c_[np.ones_like(err), slope, np.exp(-f0[:, 0] ** 2)], err, rcond=None)
    span = 2.4  # Fig. 1 y axis, -1.3 to 1.1
    macros["ExtractRms"] = sci(math.sqrt(float(np.mean(err**2))) / span, 0)
    macros["ExtractBias"] = sci(np.abs(coef).max() / span, 0)


def fig1(macros: Macros) -> list[tuple[str, float, float, float, float]]:
    """Fig. 1: f1 curves, converged and on the paper's grid.

    Parameters
    ----------
    macros : Macros
        Macro dictionary, updated.

    Returns
    -------
    list[tuple[str, float, float, float, float]]
        (curve, max %, RMS % converged, max %, RMS % paper's grid) rows for the summary table.
    """
    labels = [("f1_wt0", "$f_1$, $\\ot=0$"), ("f1perp_wt10", "$f_{1\\perp}$, $\\ot=10$"),
              ("f1wedge_wt10", "$f_{1\\wedge}$, $\\ot=10$")]
    runs = [load(RESULTS / "fig1.dat"), load(RESULTS / "fig1_paper.dat")]
    rows = []
    for k, (stem, name) in enumerate(labels):
        paper = paper_curve(f"fig1_{stem}")
        paper = paper[paper[:, 0] <= 3.0]
        cells = []
        for run in runs:
            diff = np.interp(paper[:, 0], run[:, 0], run[:, 2 + k]) - paper[:, 1]  # solver grid, dense enough
            cells += [100.0 * float(np.abs(diff).max()), 100.0 * math.sqrt(float(np.mean(diff**2)))]
        rows.append((f"Fig.~1 & {name}", *cells))
    u_nominal = math.sqrt(E_ALPHA_J * M_E / (2.0 * KEV_J * M_ALPHA))
    macros["FigOneUnominal"] = fix(u_nominal, 3)
    macros["FigOneMinPaper"] = fix(paper_curve("fig1_f1perp_wt10")[:, 1].min(), 3)
    macros["FigOneMinOurs"] = fix(runs[0][:, 3].min(), 3)
    macros["FigOneMinGrid"] = fix(runs[1][:, 3].min(), 3)
    return rows


def fig2(macros: Macros) -> None:
    """Fig. 2: comparison at the paper's 25 samples, residual pattern, and the Table I 'inconsistency'.

    Parameters
    ----------
    macros : Macros
        Macro dictionary, updated.
    """
    species = [("proton", "proton"), ("alpha", "$\\alpha$"), ("carbon", "C$^{6+}$")]
    samples = load(RESULTS / "fig2_samples.dat")
    dense = load(RESULTS / "fig2.dat")
    rows = []
    pattern: dict[float, list[str]] = {}
    for k, (stem, name) in enumerate(species):
        vert = vertices(f"fig2_{stem}")
        cells = []
        diffs = []
        for col, tag in ((1 + k, "Zero"), (4 + k, ""), (7 + k, "Grid")):
            ours = np.interp(np.log(vert[:, 0]), np.log(samples[::-1, 0]), samples[::-1, col])
            diff = ours - vert[:, 1]
            diffs.append(diff)
            rms = math.sqrt(float(np.mean(diff**2)))
            cells += [fix(np.abs(diff).max(), 4), fix(rms, 4)]
            macros[f"FigTwoRms{tag}{stem.capitalize()}"] = fix(rms, 4)
        rows.append(f"{name} & {len(vert)} & " + " & ".join(cells))
        for v in (1.0, 0.3290, 0.2736):
            i = int(np.argmin(np.abs(vert[:, 0] - v)))
            pattern.setdefault(v, [f"{vert[i, 0]:.3f}"]).extend([fix(diffs[1][i], 4), fix(diffs[2][i], 4)])
    table("tab_fig2.tex", rows)
    table("tab_shift.tex", [" & ".join(row) for row in pattern.values()])
    macros["FigTwoSamples"] = str(len(vertices("fig2_carbon")))

    # Table I against Fig. 2: the paper's curve is a straight line between its samples 0.442 and 1
    table_i = {1.0: -1.42, 0.5: -1.39, 1.0 / 3.0: -1.21, 0.25: -1.13, 0.1: -1.02}
    alpha = vertices("fig2_alpha")
    exact = spline(np.log(dense[:, 0]), dense[:, 5])
    rows = []
    for v, tab in table_i.items():
        fig = float(np.interp(np.log(v), np.log(alpha[:, 0]), alpha[:, 1]))
        chord = float(np.interp(np.log(v), np.log(samples[::-1, 0]), samples[::-1, 8]))
        rows.append(f"{'1/3' if abs(v - 1.0 / 3.0) < 1e-9 else f'{v:g}'} & {fix(tab, 2)} & {fix(fig, 3)} & "
                    f"{fix(chord, 3)} & {fix(float(exact(np.log(v))), 3)}")
    table("tab_fig2_consistency.tex", rows)
    lv = np.log(np.linspace(0.1, 1.0, 2001))
    macros["FigTwoMinAlpha"] = fix(float(exact(lv).min()), 3)
    macros["FigTwoMinAlphaAt"] = fix(float(np.exp(lv[np.argmin(exact(lv))])), 2)


def fig3(macros: Macros) -> None:
    """Fig. 3 and Tables I-IV: kinetic against the paper's figure, against the fits, and fits against the figure.

    Parameters
    ----------
    macros : Macros
        Macro dictionary, updated.
    """
    comps = [("j", "perp", 1), ("j", "wedge", 2), ("zeta", "perp", 3), ("zeta", "wedge", 4)]
    rows = []
    worst = {"j": [0.0, 0.0], "zeta": [0.0, 0.0]}
    for v, label in ((1.0, "1"), (1.0 / 3.0, "0.33"), (0.2, "0.2"), (0.05, "0.05")):
        ours = load(RESULTS / f"fig3_paper_v{v:5.3f}.dat")
        cells = []
        for panel, comp, col in comps:
            paper = paper_curve(f"fig3_{panel}_{comp}_v{label}")
            dev = [float(np.abs(deviation(ours[:, 0], ours[:, col + 4 * g], paper)).max()) for g in (0, 1)]
            cells.append(f"{fix(dev[0], 4)} & {fix(dev[1], 4)}")
            worst[panel] = [max(a, b) for a, b in zip(worst[panel], dev, strict=True)]
        rows.append(f"{'1/3' if label == '0.33' else label} & " + " & ".join(cells))
    table("tab_fig3_paper.tex", rows)
    macros["FigThreeWorstJ"] = fix(worst["j"][0], 4)
    macros["FigThreeWorstZeta"] = fix(worst["zeta"][0], 3)
    macros["FigThreeGridJ"] = fix(worst["j"][1], 4)
    macros["FigThreeGridZeta"] = fix(worst["zeta"][1], 3)

    summary = load(RESULTS / "fig3_summary.dat")
    table("tab_fig3.tex", [("1/3" if abs(row[0] - 1.0 / 3.0) < 1e-9 else f"{row[0]:.3f}") + " & "
                           + " & ".join(f"{fix(row[1 + c], 3)} & {fix(row[5 + c], 3)}" for c in range(4))
                           for row in summary])

    # the Appendix C fits against the paper's own figure, at the two legend speeds that are table nodes
    rows = []
    for label, node in (("1", "1.000"), ("0.33", "0.333")):
        fits = load(RESULTS / f"fig3_v{node}.dat")
        cells = []
        for panel, comp, col in comps:
            diff = deviation(fits[:, 0], fits[:, 4 + col], paper_curve(f"fig3_{panel}_{comp}_v{label}"))
            cells.append(fix(np.abs(diff).max(), 4))
        rows.append(f"{'1/3' if label == '0.33' else label} & " + " & ".join(cells))
    table("tab_fits_vs_figure.tex", rows)


def fig5(macros: Macros) -> list[tuple[str, float, float, float, float]]:
    """Fig. 5: heat flow with every closure and beta; the beta inferred from the paper.

    Parameters
    ----------
    macros : Macros
        Macro dictionary, updated.

    Returns
    -------
    list[tuple[str, float, float, float, float]]
        (label, max %, RMS % converged with E&H beta, max %, RMS % paper's numerics) summary rows.
    """
    rows = []
    for tag, temp in (("01", "1"), ("15", "15")):
        data = load(RESULTS / f"fig5_Te{tag}keV.dat")
        variants = fig5_variants(data)
        for key in ("eh", "paper", "fit"):
            q = variants[key]
            np.savetxt(OUT / f"fig5_{key}_Te{tag}keV.dat", np.c_[data[:, 0], q.real, q.imag],
                       header=f"x q_perp q_wedge ({key}: Epperlein-Haines fitted beta) [W s keV^-1]")
        name = "One" if temp == "1" else "Fifteen"
        for comp in ("perp", "wedge"):
            stem = f"fig5_{comp}_Te{temp}keV"
            res = {key: compare(data[:, 0], (q.real if comp == "perp" else q.imag), stem)
                   for key, q in variants.items()}
            sym = "\\perp" if comp == "perp" else "\\wedge"
            rows.append((f"Fig.~5 & $q_{{e{sym}}}$, {temp} keV", *res["eh"], *res["paper"], *res["fit"],
                         *res["kinetic"]))
            cap = "Perp" if comp == "perp" else "Wedge"
            for key, macro in (("kinetic", "Kin"), ("eh_perp", "EHperp"), ("eh", "EH"), ("paper", "Grid"),
                               ("fit", "Fit")):
                macros[f"Five{cap}{name}{macro}"] = fix(res[key][0], 2)
    macros["FiveUnominal"] = fix(math.sqrt(E_ALPHA_J * M_E / (KEV_J * M_ALPHA)), 3)

    # beta inferred from the paper's 15 keV curves with the paper's closure (kinetic, paper's grid)
    data = load(RESULTS / "fig5_Te15keV.dat")
    x = data[:, 0]
    j = spline(x, data[:, 15])
    jw = spline(x, data[:, 16])
    z = spline(x, data[:, 17])
    zw = spline(x, data[:, 18])
    bp = spline(x, data[:, 5])
    bw = spline(x, data[:, 6])
    perp, wedge = paper_curve("fig5_perp_Te15keV"), paper_curve("fig5_wedge_Te15keV")
    lines = []
    worst = 0.0
    for chi in (0.04, 0.1, 0.25, 0.63, 1.6, 4.0):
        xx = math.log10(chi)
        q = (np.interp(xx, perp[:, 0], perp[:, 1]) + 1j * np.interp(xx, wedge[:, 0], wedge[:, 1])) / KEV_J
        beta = (q - (z(xx) + 1j * zw(xx))) / (Z_ALPHA * (j(xx) + 1j * jw(xx))) - 2.5
        fit = complex(eh_beta(np.array(chi)))
        worst = max(worst, abs(beta.real - fit.real), abs(beta.imag - fit.imag))
        lines.append(f"{chi:g} & {fix(float(bp(xx)), 3)} & {fix(beta.real, 3)} & {fix(fit.real, 3)} & "
                     f"{fix(float(bw(xx)), 3)} & {fix(beta.imag, 3)} & {fix(fit.imag, 3)}")
    table("tab_beta.tex", lines)
    macros["BetaInferWorst"] = fix(worst, 3)

    # cross-check: the Epperlein-Haines curve of Davies et al. Fig. 4(a) against Table III, (beta(0) - beta_perp)/chi
    davies = load(PAPER / "davies2021_fig4a_EH_beta_new.dat")
    chi = davies[1:, 0]
    beta0 = float(eh_beta(np.array(0.0)).real)
    macros["EHBetaParFit"] = fix(beta0, 4)
    macros["EHBetaNewZero"] = fix((beta0 - float(eh_beta(np.array(1.0e-4)).real)) / 1.0e-4, 3)
    macros["DaviesCheck"] = fix(float(np.abs((beta0 - eh_beta(chi).real) / chi - davies[1:, 1]).max()), 3)
    return rows


def interpolation(macros: Macros) -> None:
    """Algebraic closure at 1 keV (v_a/v_Te = 0.688, between the nodes 1 and 0.5): interpolation against fit error.

    The heat flow of Fig. 5 (Epperlein-Haines beta) is formed with: the kinetic closure at 0.688; the kinetic values at the
    nodes 1 and 0.5 interpolated like the fits (linearly in log v); the Appendix C fits; and the two mixed cases.

    Parameters
    ----------
    macros : Macros
        Macro dictionary, updated.
    """
    data = load(RESULTS / "fig5_Te01keV.dat")
    x = data[:, 0]
    eh = eh_beta(10.0**x)
    node1, node5 = load(RESULTS / "fig3_v1.000.dat"), load(RESULTS / "fig3_v0.500.dat")
    t = math.log(math.sqrt(E_ALPHA_J * M_E / (KEV_J * M_ALPHA)) / 0.5) / math.log(2.0)

    def c(a: np.ndarray, k: int) -> np.ndarray:
        return a[:, k] + 1j * a[:, k + 1]

    j_int, z_int = t * c(node1, 9) + (1 - t) * c(node5, 9), t * c(node1, 11) + (1 - t) * c(node5, 11)
    cases = [("kinetic at $v_\\alpha/v_{Te}=0.688$", c(data, 15), c(data, 17)),
             ("kinetic node values, interpolated", j_int, z_int),
             ("Appendix~C fits, interpolated", c(data, 11), c(data, 13)),
             ("$j^\\nu$ interpolated, $\\zeta^\\nu$ kinetic", j_int, c(data, 17)),
             ("$j^\\nu$ kinetic, $\\zeta^\\nu$ interpolated", c(data, 15), z_int)]
    rows = []
    for label, j, z in cases:
        q = heat_flow(j, z, eh)
        rows.append(f"{label} & {fix(compare(x, q.real, 'fig5_perp_Te1keV')[0], 2)} & "
                    f"{fix(compare(x, q.imag, 'fig5_wedge_Te1keV')[0], 2)}")
    table("tab_interp.tex", rows)
    i = int(np.argmin(np.abs(x + 3.0)))
    macros["InterpJkin"] = fix(float(data[i, 15]), 3)
    macros["InterpJone"] = fix(float(node1[i, 9]), 3)
    macros["InterpJhalf"] = fix(float(node5[i, 9]), 3)


def footnote30(macros: Macros) -> None:
    """Footnote 30: broad energy spectra against the monoenergetic population at the mean energy.

    Parameters
    ----------
    macros : Macros
        Macro dictionary, updated.
    """
    rows: dict[str, list[str]] = {}
    names = {"gauss_0.2": "Gaussian, $\\sigma_E/\\bar E=0.2$", "gauss_0.4": "Gaussian, $\\sigma_E/\\bar E=0.4$",
             "flat_0.3": "flat, $\\pm30\\%$", "flat_0.6": "flat, $\\pm60\\%$", "slowing_down": "slowing-down"}
    worst_moderate = 0.0
    for line in (RESULTS / "footnote30.dat").read_text().splitlines():
        if line.startswith("#"):
            continue
        label, *rest = line.split()
        v = np.array(rest, dtype=float)
        jb, jm = v[4] + 1j * v[5], v[6] + 1j * v[7]
        zb, zm = v[8] + 1j * v[9], v[10] + 1j * v[11]
        dj, dz = 100.0 * abs(jb - jm) / abs(jm), 100.0 * abs(zb - zm) / abs(zm)
        key = f"{label}@{v[0]:g}"
        cell = rows.setdefault(key, [names[label], f"{v[0]:g}", f"{v[1]:.3f}", "0", "0"])
        cell[3] = f"{max(float(cell[3]), dj):.2f}"
        cell[4] = f"{max(float(cell[4]), dz):.2f}"
        if label != "slowing_down" and v[0] <= 0.5:
            worst_moderate = max(worst_moderate, dj, dz)
    order = sorted(rows.values(), key=lambda r: (float(r[1]), list(names.values()).index(r[0])))
    table("tab_footnote30.tex", [" & ".join(r[:3]) + f" & ${r[3]}$ & ${r[4]}$" for r in order])
    macros["FootWorstModerate"] = fix(worst_moderate, 1)


def electrons(macros: Macros) -> None:
    """Non-Maxwellian electron f0 (appelbe_electrons): the reference distortion and the largest changes of the scans.

    Parameters
    ----------
    macros : Macros
        Macro dictionary, updated.
    """
    prof = load(RESULTS / "electrons_profile.dat")
    window = (prof[:, 1] >= 1.0) & (prof[:, 1] <= 4.0)
    macros["ElPeakF"] = fix(100.0 * float(np.abs(prof[window, 5]).max()), 2)
    macros["ElPeakDf"] = fix(100.0 * float(np.abs(prof[window, 6]).max()), 1)
    macros["ElSlopeMin"] = fix(float(prof[window, 7].min()), 3)
    macros["ElSlopeMax"] = fix(float(prof[window, 7].max()), 3)
    scans = {name: load(RESULTS / f"electrons_scan_{name}.dat") for name in ("A", "u0", "w")}
    ref = scans["w"][np.argmin(np.abs(scans["w"][:, 0] - 0.25))]
    macros["ElTsTwo"] = fix(100.0 * (ref[1] - 1.0), 2)
    macros["ElTsThree"] = fix(100.0 * (ref[2] - 1.0), 2)
    macros["ElTkin"] = fix(100.0 * (ref[3] - 1.0), 2)
    for col, name in ((8, "Sigma"), (9, "Kappa"), (10, "J"), (11, "Zeta")):
        macros[f"ElRef{name}"] = fix(100.0 * ref[col], 2)
    every = np.vstack(list(scans.values()))
    macros["ElTsMax"] = fix(100.0 * float(np.abs(every[:, 1] - 1.0).max()), 1)
    macros["ElSlopeMinAll"] = fix(float(every[:, 4].min()), 2)
    macros["ElSlopeMaxAll"] = fix(float(every[:, 5].max()), 2)
    macros["ElWtOneMax"] = fix(100.0 * float(np.abs(every[:, 12:16]).max()), 1)
    rows = []
    labels = {"A": "$A$", "u0": "$u_0$", "w": "$w$"}
    for col, name in ((8, "$\\sigma$"), (9, "$\\kappa$"), (10, "$j^\\nu$"), (11, "$\\zeta^\\nu$")):
        cells = [name]
        for key, data in scans.items():
            for offset in (0, 8):
                i = int(np.argmax(np.abs(data[:, col + offset])))
                cells.append(f"${100.0 * data[i, col + offset]:+.1f}$ ({labels[key]} $= {data[i, 0]:g}$)")
        rows.append(" & ".join(cells))
    table("tab_electrons.tex", rows)


def nrl(macros: Macros) -> None:
    """NRL Coulomb logarithms: lambda_ei - lambda_ee for T_e > 10 Z^2 eV.

    Parameters
    ----------
    macros : Macros
        Macro dictionary, updated.
    """
    n_cm3 = 1.0e25
    diffs = []
    for te in (1.0e3, 1.0e4):
        lee = 23.5 - math.log(n_cm3**0.5 * te**-1.25) - math.sqrt(1.0e-5 + (math.log(te) - 2.0) ** 2 / 16.0)
        lei = 24.0 - math.log(n_cm3**0.5 / te)
        diffs.append(abs(lei - lee))
    macros["NrlDiff"] = sci(max(diffs), 0)


def summary(macros: Macros, fig1_rows: list[tuple[str, float, float, float, float]],
            fig5_rows: list[tuple[str, float, float, float, float, float, float, float, float]]) -> None:
    """Deviation from every extracted curve, and the numbers quoted in the paper's text.

    Parameters
    ----------
    macros : Macros
        Macro dictionary, updated.
    fig1_rows : list[tuple[str, float, float, float, float]]
        Fig. 1 rows: (label, converged max, RMS, paper's grid max, RMS).
    fig5_rows : list[tuple[str, float, float, float, float, float, float, float, float]]
        Fig. 5 rows: (label, converged/E&H max, RMS, paper's numerics max, RMS, fits/E&H max, RMS, exact beta max, RMS).
    """
    f2 = load(RESULTS / "fig2.dat")
    f4 = load(RESULTS / "fig4.dat")
    f51 = load(RESULTS / "fig5_Te01keV.dat")
    f515 = load(RESULTS / "fig5_Te15keV.dat")
    f6 = load(RESULTS / "fig6.dat")

    def cell(m: float, r: float) -> str:
        return f"{fix(m, 2)} ({fix(r, 2)})"

    lines = [f"{label} & {cell(a, b)} & {cell(c, d)} & ---" for label, a, b, c, d in fig1_rows]
    for label, col, stem in (("Fig.~4 & $j^0_{e\\alpha}$ heat flow", 1, "fig4_q_j"),
                             ("Fig.~4 & $\\zeta_{e\\alpha}$ heat flow", 2, "fig4_q_zeta"), ("Fig.~4 & sum", 3, "fig4_q_sum")):
        lines.append(f"{label} & {cell(*compare(f4[:, 0], f4[:, col], stem))} & "
                     f"{cell(*compare(f4[:, 0], f4[:, col + 8], stem))} & {cell(*compare(f4[:, 0], f4[:, col + 3], stem))}")
    lines += [f"{row[0]} & {cell(row[1], row[2])} & {cell(row[3], row[4])} & {cell(row[5], row[6])}" for row in fig5_rows]
    for k, (coef, temp) in enumerate((("K", 1), ("\\mu", 1), ("K", 5), ("\\mu", 5), ("K", 10), ("\\mu", 10))):
        stem = f"fig6_{'K' if coef == 'K' else 'mu'}_{temp}keV"
        lines.append(f"Fig.~6 & ${coef}_\\parallel$, {temp} keV & {cell(*compare(f6[:, 0], f6[:, 1 + k], stem, True))} & "
                     f"{cell(*compare(f6[:, 0], f6[:, 7 + k], stem, True))} & ---")
    table("tab_digitized.tex", lines)
    macros["FigFourGridMax"] = fix(max(compare(f4[:, 0], f4[:, c + 8], s_)[0] for c, s_ in
                                       ((1, "fig4_q_j"), (2, "fig4_q_zeta"), (3, "fig4_q_sum"))), 2)

    # Fig. 5 plateaus (x = -3) and wedge minima: paper, kinetic, algebraic fits [W s keV^-1]
    for tag, ours in (("One", f51), ("Fifteen", f515)):
        label = "Te1keV" if tag == "One" else "Te15keV"
        perp, wedge = paper_curve(f"fig5_perp_{label}"), paper_curve(f"fig5_wedge_{label}")
        macros[f"FivePlateauPaper{tag}"] = sci(perp[0, 1], 2)
        macros[f"FivePlateauKin{tag}"] = sci(ours[0, 1], 2)
        macros[f"FivePlateauFit{tag}"] = sci(ours[0, 3], 2)
        macros[f"FiveMinPaper{tag}"] = sci(wedge[:, 1].min(), 2)
        macros[f"FiveMinKin{tag}"] = sci(ours[:, 2].min(), 2)
        macros[f"FiveMinFit{tag}"] = sci(ours[:, 4].min(), 2)

    val = load_validation()
    flux = 1.0e34
    q_lo = float(np.interp(1.5, f4[:, 0], f4[:, 3])) * flux
    q_hi = float(np.interp(10.0, f4[:, 0], f4[:, 3])) * flux
    adv = load(RESULTS / "sec5_advection.dat")
    u_max = float(np.hypot(adv[:, 2], adv[:, 3]).max())
    carbon = load(RESULTS / "sec5_carbon.dat")
    grad = load(RESULTS / "sec5_gradient.dat")
    f6_1e3 = f6[np.argmin(np.abs(np.log10(f6[:, 0]) + 3.0))]
    f6_1e2 = f6[np.argmin(np.abs(np.log10(f6[:, 0]) + 2.0))]
    v_2kev = math.sqrt(E_ALPHA_J * M_E / (2.0 * KEV_J * M_ALPHA))
    scaled = grad[:, 4] * grad[:, 0] ** 2.5
    quotes = [
        ("$v_\\alpha/v_{Te}$, 3.45 MeV $\\alpha$, 2 keV", "III C", "$0.48$", fix(v_2kev, 3)),
        ("$\\hat\\alpha_\\parallel$ ($Z=1$)", "Eq.~(42)", "$0.506$", fix(val["z1_alpha_par"][0], 4)),
        ("$j^0_{e\\alpha}/j^0_\\alpha$, $\\alpha$, $v_\\alpha/v_{Te}\\to0$", "Eq.~(32)", "$-1$",
         fix(f2[0, 2], 3) + " at $0.1$"),
        ("$j^0_{e\\alpha}/j^0_\\alpha$, C$^{6+}$, $v_\\alpha/v_{Te}\\to0$", "Eq.~(32)", "$-5$",
         fix(f2[0, 3], 3) + " at $0.1$"),
        ("heat flow, $\\alpha$ flux $10^{34}$, 1.5--10 keV", "IV A", "$10^{19}$--$10^{20}$ W\\,m$^{-2}$",
         f"{sci(q_lo, 1)}--{sci(q_hi, 1)}"),
        ("$\\alpha$ energy flux, same flux", "IV A", "$5\\times10^{21}$ W\\,m$^{-2}$", sci(flux * E_ALPHA_J, 1)),
        ("advection speed, $n_\\alpha/n_e=10^{-3}$, $\\langle v_\\alpha\\rangle=10^7$", "V A",
         "up to $10^{4}$ m\\,s$^{-1}$", sci(u_max, 1) + " (max)"),
        ("C$^{6+}$ beam, $j^0_{e\\alpha}/j^0_\\alpha$ at 1/2/5/10 keV", "V B", "$\\approx-5$",
         "/".join(fix(v, 2) for v in carbon[:, 2])),
        ("C$^{6+}$ beam, $\\partial B_\\theta/\\partial t$, 1--10 keV", "V B", "$10^{13}$--$10^{15}$ T\\,s$^{-1}$",
         f"{sci(carbon[:, 5].min(), 1)}--{sci(carbon[:, 5].max(), 1)}"),
        ("$|j^0_{e\\alpha}|$, $\\alpha$ flux $10^{34}$, 1--10 keV", "V B", "$6\\times10^{15}$ A\\,m$^{-2}$",
         f"{sci(abs(grad[:, 2]).min(), 1)}--{sci(abs(grad[:, 2]).max(), 1)}"),
        ("$T_{keV}^{5/2}\\,\\partial B_\\theta/\\partial t$, same, 1--10 keV", "V B", "$6\\times10^{13}$ T\\,s$^{-1}$",
         f"{sci(scaled.min(), 1)}--{sci(scaled.max(), 1)}"),
        ("$1-K_\\parallel/K^0_\\parallel$, $n_\\alpha/n_e=10^{-3}$, worst $T_e$", "VI", "$<1\\%$",
         fix(100.0 * (1.0 - f6_1e3[1:].min()), 2) + "\\%"),
        ("$1-\\mu_\\parallel/\\mu^0_\\parallel$, $n_\\alpha/n_e=10^{-2}$, worst $T_e$", "VI", "significant",
         fix(100.0 * (1.0 - f6_1e2[1:].min()), 1) + "\\%"),
    ]
    table("tab_quotes.tex", [f"{a} & {b} & {c} & {d}" for a, b, c, d in quotes])

    table("tab_carbon.tex", [f"{row[0]:.0f} & {fix(row[1], 2)} & {fix(row[2], 3)} & {fix(row[3], 2)} & {sci(row[5], 1)}"
                             for row in carbon])
    table("tab_gradient.tex", [f"{row[0]:.0f} & {fix(row[1], 2)} & {sci(row[2], 2)} & {sci(row[3], 2)} & "
                               f"{sci(row[4], 2)} & {sci(row[4] * row[0]**2.5, 2)}" for row in grad])
    table("tab_advection.tex", [f"{row[0]:.0f} & {row[1]:.0f} & " + " & ".join(sci(v, 2) for v in row[2:6])
                                for row in adv])


def main() -> None:
    """Entry point."""
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    macros: Macros = {}
    commit = subprocess.run(["git", "describe", "--always", "--dirty"], capture_output=True, text=True, check=False)
    macros["GitCommit"] = commit.stdout.strip() or "unknown"
    OUT.mkdir(parents=True, exist_ok=True)
    verification(macros)
    extraction(macros)
    fig1_rows = fig1(macros)
    fig2(macros)
    fig3(macros)
    fig5_rows = fig5(macros)
    interpolation(macros)
    footnote30(macros)
    electrons(macros)
    nrl(macros)
    summary(macros, fig1_rows, fig5_rows)
    # \ensuremath instead of $...$ so that the macros work both in text and inside math
    body = {k: f"\\ensuremath{{{v[1:-1]}}}" if v.startswith("$") and v.endswith("$") else v for k, v in macros.items()}
    write("numbers.tex", "".join(f"\\newcommand{{\\{k}}}{{{v}}}\n" for k, v in body.items()))


if __name__ == "__main__":
    main()
