"""Generate the LaTeX numbers and tables of the report from the results of the last run.

Reads ``results/*.dat`` (written by the Fortran drivers) and ``report/data/paper_*.dat`` (digitized from Appelbe et
al. 2019 by ``scripts/digitize_paper.py``) and writes ``report/generated/*.tex``: a macro file with every number quoted
in the text and one file per table. The report therefore always reflects the last execution.

Usage (from the repository root, after ``fobis rule --ex figures``)::

    python3 scripts/report_numbers.py
"""

from __future__ import annotations

import logging
import math
import subprocess
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


def compare(x_ours: np.ndarray, y_ours: np.ndarray, paper_file: str, xlog: bool = False) -> tuple[float, float]:
    """Compare one of our curves with a digitized paper curve.

    Our curve is interpolated at the digitized abscissae inside its range.

    Parameters
    ----------
    x_ours, y_ours : np.ndarray
        Our curve.
    paper_file : str
        Digitized file stem inside report/data (without ``paper_`` and ``.dat``).
    xlog : bool
        Interpolate in log10(x).

    Returns
    -------
    tuple[float, float]
        Max and RMS of |ours - paper| normalised by max |paper|, in percent.
    """
    paper = load(PAPER / f"paper_{paper_file}.dat")
    xp, yp = paper[:, 0], paper[:, 1]
    xo, xq = (np.log10(x_ours), np.log10(xp)) if xlog else (x_ours, xp)
    order = np.argsort(xo)
    inside = (xq >= xo.min()) & (xq <= xo.max())
    diff = np.interp(xq[inside], xo[order], y_ours[order]) - yp[inside]
    scale = np.abs(yp).max()
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


def macros_and_tables() -> None:  # noqa: PLR0915
    """Build every macro and table."""
    macros: dict[str, str] = {}
    val = load_validation()

    commit = subprocess.run(["git", "describe", "--always", "--dirty"], capture_output=True, text=True, check=False)
    macros["GitCommit"] = commit.stdout.strip() or "unknown"

    # verification table
    rows = [
        ("Lorentz gas $\\hat\\alpha$", "lorentz_alpha", "exact, $3\\pi/32$", 5),
        ("Lorentz gas $\\beta$", "lorentz_beta", "exact, $3/2$", 5),
        ("Lorentz gas $\\hat\\kappa$", "lorentz_kappa", "exact, $128/3\\pi$", 4),
        ("$Z=1$, $\\hat\\alpha_\\parallel$", "z1_alpha_par", "E\\&H (1986)", 4),
        ("$Z=1$, $\\beta_\\parallel$", "z1_beta_par", "E\\&H (1986)", 4),
        ("$Z=1$, $\\hat\\kappa_\\parallel$", "z1_kappa_par", "E\\&H (1986)", 4),
        ("$Z=1$, $\\hat\\alpha_\\parallel$", "z1_alpha_par_eq42", "paper, Eq.~(42)", 3),
    ]
    lines = []
    for label, key, source, digits in rows:
        value, reference = val[key]
        lines.append(f"{label} & {fix(value, digits + 1)} & {fix(reference, digits)} & {source} & "
                     f"{sci(abs(value - reference) / reference, 1)} \\\\")
    write("tab_validation.tex", "\n".join(lines) + "\n")
    macros["OnsagerViolation"] = sci(val["onsager_max_rel_violation"][0], 1)
    macros["ConvAlpha"] = sci(val["conv_alpha_par_401_vs_1601"][0], 1)
    macros["ConvBeta"] = sci(val["conv_beta_par_401_vs_1601"][0], 1)
    macros["ConvKappa"] = sci(val["conv_kappa_par_401_vs_1601"][0], 1)
    macros["ZoneAlpha"] = fix(val["z1_alpha_par"][0], 4)
    macros["ZoneBeta"] = fix(val["z1_beta_par"][0], 4)
    macros["ZoneKappa"] = fix(val["z1_kappa_par"][0], 4)

    # grid convergence (complex method against 1601 nodes)
    conv = load(RESULTS / "convergence.dat")
    lines = [f"{int(row[0])} & {omega_label(row[1])} & " + " & ".join(sci(v, 1) for v in row[2:6]) + " \\\\"
             for row in conv if row[1] in (0.0, 1.0, 1.0e3)]
    write("tab_convergence.tex", "\n".join(lines) + "\n")
    at = {(int(r[0]), r[1]): r for r in conv}
    macros["ConvJfourOone"] = sci(at[(401, 1.0)][4], 1)
    macros["ConvJeightOone"] = sci(at[(801, 1.0)][4], 1)
    macros["ConvZfourOone"] = sci(at[(401, 1.0)][5], 1)
    macros["ConvZeightOone"] = sci(at[(801, 1.0)][5], 1)

    # solver comparison
    sol = load(RESULTS / "solvers.dat")
    lines = [f"{int(row[0])} & {omega_label(row[1])} & {sci(row[2:6].max(), 1)} & {sci(row[6], 1)} & "
             f"{sci(row[7], 1)} & {fix(row[8], 3)} & {fix(row[9], 3)} \\\\"
             for row in sol if row[1] in (0.0, 1.0e-2, 1.0, 1.0e2)]
    write("tab_solvers.tex", "\n".join(lines) + "\n")
    magnetised = sol[sol[:, 1] > 0]
    macros["SolverMaxDiff"] = sci(magnetised[:, 2:6].max(), 1)
    macros["SolverMaxDiffFourOone"] = sci(magnetised[magnetised[:, 0] == 401][:, 2:6].max(), 1)
    macros["ResidualRatioMax"] = sci((magnetised[:, 7] / magnetised[:, 6]).max(), 0)
    big = sol[sol[:, 0] == 1601]
    macros["TimeComplexBig"] = fix(big[:, 8].mean(), 2)
    macros["TimePaperBig"] = fix(big[big[:, 1] > 0][:, 9].mean(), 2)

    # Fig. 3: kinetic versus Appendix C fits
    f3 = load(RESULTS / "fig3_summary.dat")
    lines = [f"{row[0]:.3f} & " + " & ".join(fix(v, 3) for v in row[1:5]) + " \\\\" for row in f3]
    write("tab_fig3.tex", "\n".join(lines) + "\n")

    # direct comparison with the digitized figures
    f2 = load(RESULTS / "fig2.dat")
    f4 = load(RESULTS / "fig4.dat")
    f51 = load(RESULTS / "fig5_Te01keV.dat")
    f515 = load(RESULTS / "fig5_Te15keV.dat")
    f6 = load(RESULTS / "fig6.dat")
    cases = [
        ("Fig.~2", "proton", f2[:, 0], f2[:, 1], None, "fig2_proton", True),
        ("Fig.~2", "$\\alpha$", f2[:, 0], f2[:, 2], None, "fig2_alpha", True),
        ("Fig.~2", "C$^{6+}$", f2[:, 0], f2[:, 3], None, "fig2_carbon", True),
        ("Fig.~4", "$j^0_{e\\alpha}$ heat flow", f4[:, 0], f4[:, 1], f4[:, 4], "fig4_q_j", False),
        ("Fig.~4", "$\\zeta_{e\\alpha}$ heat flow", f4[:, 0], f4[:, 2], f4[:, 5], "fig4_q_zeta", False),
        ("Fig.~4", "sum", f4[:, 0], f4[:, 3], f4[:, 6], "fig4_q_sum", False),
        ("Fig.~5", "$q_{e\\perp}$, 1 keV", f51[:, 0], f51[:, 1], f51[:, 3], "fig5_perp_Te1keV", False),
        ("Fig.~5", "$q_{e\\perp}$, 15 keV", f515[:, 0], f515[:, 1], f515[:, 3], "fig5_perp_Te15keV", False),
        ("Fig.~5", "$q_{e\\wedge}$, 1 keV", f51[:, 0], f51[:, 2], f51[:, 4], "fig5_wedge_Te1keV", False),
        ("Fig.~5", "$q_{e\\wedge}$, 15 keV", f515[:, 0], f515[:, 2], f515[:, 4], "fig5_wedge_Te15keV", False),
        ("Fig.~6", "$K_\\parallel$, 1 keV", f6[:, 0], f6[:, 1], None, "fig6_K_1keV", True),
        ("Fig.~6", "$\\mu_\\parallel$, 1 keV", f6[:, 0], f6[:, 2], None, "fig6_mu_1keV", True),
        ("Fig.~6", "$K_\\parallel$, 5 keV", f6[:, 0], f6[:, 3], None, "fig6_K_5keV", True),
        ("Fig.~6", "$\\mu_\\parallel$, 5 keV", f6[:, 0], f6[:, 4], None, "fig6_mu_5keV", True),
        ("Fig.~6", "$K_\\parallel$, 10 keV", f6[:, 0], f6[:, 5], None, "fig6_K_10keV", True),
        ("Fig.~6", "$\\mu_\\parallel$, 10 keV", f6[:, 0], f6[:, 6], None, "fig6_mu_10keV", True),
    ]
    lines = []
    for fig, curve, x, y_kin, y_fit, stem, xlog in cases:
        kin_max, kin_rms = compare(x, y_kin, stem, xlog)
        if y_fit is None:
            fit_txt = "--- & ---"
        else:
            fit_max, fit_rms = compare(x, y_fit, stem, xlog)
            fit_txt = f"{fix(fit_max, 1)} & {fix(fit_rms, 1)}"
        lines.append(f"{fig} & {curve} & {fix(kin_max, 1)} & {fix(kin_rms, 1)} & {fit_txt} \\\\")
    write("tab_digitized.tex", "\n".join(lines) + "\n")

    # Fig. 5 plateaus (x = -3) and wedge minima: paper (digitized), kinetic, algebraic fits [W s keV^-1]
    for tag, ours in (("One", f51), ("Fifteen", f515)):
        label = "Te1keV" if tag == "One" else "Te15keV"
        perp = load(PAPER / f"paper_fig5_perp_{label}.dat")
        wedge = load(PAPER / f"paper_fig5_wedge_{label}.dat")
        macros[f"FivePlateauPaper{tag}"] = sci(perp[np.argmin(perp[:, 0]), 1], 2)
        macros[f"FivePlateauKin{tag}"] = sci(ours[0, 1], 2)
        macros[f"FivePlateauFit{tag}"] = sci(ours[0, 3], 2)
        macros[f"FiveMinPaper{tag}"] = sci(wedge[:, 1].min(), 2)
        macros[f"FiveMinKin{tag}"] = sci(ours[:, 2].min(), 2)
        macros[f"FiveMinFit{tag}"] = sci(ours[:, 4].min(), 2)
        macros[f"FiveMinPaperX{tag}"] = fix(wedge[np.argmin(wedge[:, 1]), 0], 2)
        macros[f"FiveMinKinX{tag}"] = fix(ours[np.argmin(ours[:, 2]), 0], 2)

    # internal consistency of the paper: Table I (omega tau = 0 column) versus its Fig. 2 alpha curve
    table_i = {1.0: -1.42, 0.5: -1.39, 0.33: -1.21, 0.25: -1.13, 0.1: -1.02}
    paper_alpha = load(PAPER / "paper_fig2_alpha.dat")
    lines = []
    for v, tab in table_i.items():
        v_fig = min(v, paper_alpha[:, 0].max())
        fig2 = float(np.interp(np.log10(v_fig), np.log10(paper_alpha[:, 0]), paper_alpha[:, 1]))
        ours = float(np.interp(np.log10(v), np.log10(f2[:, 0]), f2[:, 2]))
        note = f" (at {v_fig:.2f})" if v_fig < v else ""
        lines.append(f"{v:g} & {fix(tab, 2)} & {fix(fig2, 3)}{note} & {fix(ours, 3)} \\\\")
    write("tab_fig2_consistency.tex", "\n".join(lines) + "\n")

    # paper-quoted numbers versus ours
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
    write("tab_quotes.tex", "\n".join(f"{a} & {b} & {c} & {d} \\\\" for a, b, c, d in quotes) + "\n")

    # Sec. V tables
    write("tab_carbon.tex", "\n".join(
        f"{row[0]:.0f} & {fix(row[1], 2)} & {fix(row[2], 3)} & {fix(row[3], 2)} & {sci(row[5], 1)} \\\\"
        for row in carbon) + "\n")
    write("tab_gradient.tex", "\n".join(
        f"{row[0]:.0f} & {fix(row[1], 2)} & {sci(row[2], 2)} & {sci(row[3], 2)} & {sci(row[4], 2)} & "
        f"{sci(row[4] * row[0]**2.5, 2)} \\\\" for row in grad) + "\n")
    write("tab_advection.tex", "\n".join(
        f"{row[0]:.0f} & {row[1]:.0f} & " + " & ".join(sci(v, 2) for v in row[2:6]) + " \\\\" for row in adv) + "\n")

    # \ensuremath instead of $...$ so that the macros work both in text and inside math
    body = {k: f"\\ensuremath{{{v[1:-1]}}}" if v.startswith("$") and v.endswith("$") else v for k, v in macros.items()}
    write("numbers.tex", "".join(f"\\newcommand{{\\{k}}}{{{v}}}\n" for k, v in body.items()))


def main() -> None:
    """Entry point."""
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    macros_and_tables()


if __name__ == "__main__":
    main()
