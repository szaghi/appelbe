# appelbe

>#### Electron transport modified by collisions with fast ions
> A KISS Fortran 2018 reproduction of Appelbe *et al.*, *Phys. Plasmas* **26**, 102704 (2019), Secs. IV–VI: the simple-algebraic closure, the kinetic Fokker–Planck solver behind it, and a LaTeX report comparing every result with the paper.

[![GitHub tag](https://img.shields.io/github/v/tag/szaghi/appelbe)](https://github.com/szaghi/appelbe/tags)
[![GitHub issues](https://img.shields.io/github/issues/szaghi/appelbe)](https://github.com/szaghi/appelbe/issues)
[![License: GPL v3](https://img.shields.io/badge/license-GPL%20v3-blue.svg)](https://github.com/szaghi/appelbe/blob/main/LICENSE.md)

| 🧮 **Simple-algebraic closure**<br>Appendix C fits of the collisionally induced current `j⁰_eα` and heat flow `ζ_eα` (α in DT) | ⚛️ **Kinetic solver**<br>Linearised electron `f₁` equation (Eq. 13) with e–e, e–i and e–fast-ion Fokker–Planck operators | 🔀 **Two solution methods**<br>The paper's Appendix B procedure (`GG + Ω²`) and an equivalent complex form `(G + iωτ) f₁ = g₇` | ✅ **Verified**<br>Epperlein–Haines Z=1 coefficients to 4 digits, exact Lorentz limits, Onsager symmetry to 5e-8 |
|:---:|:---:|:---:|:---:|
| 📊 **Secs. IV–VI reproduced**<br>Heat flow (Figs. 4–5), field advection/generation (Sec. V), isotropic-population effect (Fig. 6) | 🔍 **Direct comparison**<br>Paper figures digitized and overlaid; every number quoted in the text checked | 📄 **Self-updating report**<br>LaTeX/pgfplots PDF built from the last run's results — no hand-copied numbers | ⚡ **KISS**<br>Dense matrices, no LAPACK, one dependency (PENF) — full run in about a minute |

For the full results, methods and discussion see the **[reproduction report](report/appelbe_report.pdf)**.

---

## Authors

- Federico Negro
- Luca Senni
- Stefano Zaghi — [@szaghi](https://github.com/szaghi)
- Claude (Anthropic) — AI assistant

## Copyrights

This project is distributed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html) — see [LICENSE.md](LICENSE.md).

> Anyone interested in using, developing, or contributing to this project is welcome, under the terms of the GPL v3.

The reference paper is **not** distributed: `references/` is git-ignored because the article is publisher-copyrighted. The curves in `report/data/` are numerical data digitized from its figures, kept only to make the comparison reproducible.

---

## Quick start

```bash
git clone https://github.com/szaghi/appelbe && cd appelbe
fobis fetch                   # PENF into src/third_party/
fobis build --mode gnu        # every program under src/ into exe/
fobis rule --ex tests         # verification suite (109 checks)
fobis rule --ex figures       # all drivers -> results/*.dat + gnuplot previews results/*.png
fobis rule --ex report        # report/generated/*.tex + report/appelbe_report.pdf
```

Run everything from the repository root: the drivers write to `./results/`.

### Build modes

| Mode | Flags | Use |
|------|-------|-----|
| `gnu` | `-O2` | production runs, figures, report |
| `gnu-debug` | `-O0 -g3 -fcheck=all -ffpe-trap=invalid,zero,overflow -finit-real=snan` | development: bounds, NaN and FP-exception checks |

```bash
fobis build --lmodes          # list the modes
fobis rule --ls               # list the rules (tests, figures, report)
```

## What is reproduced

| Paper | Content | Driver | Route |
|-------|---------|--------|-------|
| Fig. 2 (Sec. III C) | unmagnetised `j⁰_eα / j⁰_α` for p, α, C⁶⁺ | `appelbe_fig2` | kinetic |
| Fig. 3 (App. C) | kinetic solution vs the algebraic fits, `-3 ≤ log₁₀ωτ ≤ 3` | `appelbe_fig3` | both |
| **Fig. 4** (Sec. IV A) | heat flow, unmagnetised, 3.45 MeV α, vs `T_e` | `appelbe_fig4` | both |
| **Fig. 5** (Sec. IV B) | heat flow vs `ωτ`, flux ⊥ **B**, 1 and 15 keV | `appelbe_fig5` | both |
| **Sec. V A** | field advection velocity `j⁰_eα / (e n_e)` | `appelbe_sec5` | both |
| **Sec. V B** | field generation: C⁶⁺ fast-ignition beam, α flux across ∇T | `appelbe_sec5` | kinetic (+ fits for α) |
| **Fig. 6** (Sec. VI) | `μ∥`, `K∥` vs `n_α/n_e`, isotropic α population | `appelbe_fig6` | kinetic only |
| — | conventional coefficients, Lorentz limits, Onsager, grid convergence | `appelbe_validation` | kinetic |
| — | paper's Appendix B solver vs complex solver | `appelbe_solvers` | kinetic |

## Results at a glance

Deviation from the digitized paper curves (max over the curve, % of its peak; digitization resolution ≈ 0.5%):

| Figure | Kinetic closure | Algebraic closure |
|--------|-----------------|-------------------|
| Fig. 4, components | ≤ 0.8% | ≤ 2.6% |
| Fig. 5, along the flux | 2–4% | 2–6% |
| Fig. 5, orthogonal | minimum within 4% (15 keV) / 14% (1 keV) | similar |
| Fig. 6, all six curves | ≤ 0.2% | — (not covered by the fits) |

Verification of the kinetic solver (no fast ions, `N = 401`):

| Quantity | This code | Reference |
|----------|-----------|-----------|
| `α̂∥` (Z=1) | 0.5061 | 0.5061 (Epperlein & Haines 1986), 0.506 (paper Eq. 42) |
| `β∥` (Z=1) | 0.7029 | 0.7029 (E&H) |
| `κ̂∥` (Z=1) | 3.2031 | 3.2031 (E&H) |
| Lorentz `α̂`, `β`, `κ̂` | 3π/32, 3/2, 128/3π | exact |
| Onsager `τ = μ − 3σ/2` | violated by ≤ 5e-8 | exact |

### Findings about the paper

- **Eqs. (B6)–(B7)** print `(G ± Ω) g₇`: the right-hand sides that follow from Eq. (B5) are `G g₇ₓ + Ω g₇ᵧ` and `G g₇ᵧ − Ω g₇ₓ`.
- **Fig. 2 contradicts Table I** at `v_α/v_Te = 0.5` (−1.34 vs −1.39); the kinetic solver gives −1.385.
- **Fig. 5 is consistent with a kinetic computation**, not with node-wise use of the paper's own fits (1 keV plateau: paper 6.15, kinetic 6.02, fits 6.45 ×10⁻¹⁶ W s keV⁻¹).
- **Sec. V estimates run high**: the α-flux current (6×10¹⁵ A m⁻²) exceeds its own bound (≤ 4.8×10¹⁵); the carbon-beam rate applies `j⁰_eα ≈ −5 j⁰_α` where `v_α/v_Te = 2–3` and the ratio has collapsed to −0.05…−1.7.
- **Weak spot of the algebraic closure**: between the table nodes `v_α/v_Te = 1` and `0.5` (T_e ≈ 0.5–1.9 keV for 3.45 MeV α) it is 7% high on the `q⊥` plateau and 25% shallow at the `q∧` minimum.

## Architecture

```
src/lib/                       library (one module per file)
├── appelbe_constants.F90      CODATA constants, particle masses
├── appelbe_plasma.F90         v_Te, τ_ei (Eq. 14), NRL lnΛ, Eq. (43) coefficient
├── appelbe_velocity_grid.F90  uniform speed grid, 5-point stencils, Simpson weights (Eqs. B11-B19)
├── appelbe_linear_solver.F90  dense Gaussian elimination, real and complex
├── appelbe_kinetic.F90        operator G (Eqs. A8-A13), sources g₇ (Eq. 15), both solvers, moments
├── appelbe_fits.F90           Appendix C tables and rational fits (Eqs. C1-C8)
├── appelbe_closure.F90        heat flows (Eqs. 33-35), advection (40), field generation (43)
└── appelbe_io.F90             results/ tables
src/app/                       one driver per figure/section (appelbe_*)
src/tests/                     test programs (test_*) + assertion helper
scripts/                       run_tests.sh, make_figures.sh, make_report.sh,
                               digitize_paper.py, report_numbers.py, *.gp
report/                        appelbe_report.tex, data/ (digitized paper curves)
```

### Kinetic solver

| Aspect | Choice |
|--------|--------|
| Units | `u = v/v_Te`, distributions per `n/v_Te³`, time in `τ_ei`: every `τ_ei Y_ab n_b` is a pure number |
| Grid | uniform, `N = 401` nodes on `[0, ≈7]`, stretched so a node sits exactly on `u_α` |
| Discretisation | 5-point finite differences, Simpson integrals, `f₁(u₁) = f₁(u₂)`, `f₁(u_N) = 0` (Appendix B) |
| Drives | electric field, temperature gradient, unit fast-ion flux — three right-hand sides, one solve |
| Magnetisation | `f₁ = f₁ₓ + i f₁ᵧ`: real part ⊥ (along drive), imaginary part ∧ (along **b**×drive), as Eq. (27) |

The two methods are selected per call:

```fortran
use appelbe_kinetic, only : kinetic_params, kinetic_operator, kinetic_response, method_complex, method_paper

type(kinetic_params)   :: par
type(kinetic_operator) :: op
type(kinetic_response) :: r

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%u_a = 0.5_R8P
call op%init(par=par)
r = op%response(omega_tau=1._R8P)                        ! (G + iωτ) f₁ = g₇  (default)
r = op%response(omega_tau=1._R8P, method=method_paper)   ! (GG + Ω²) f₁ = ...  (Appendix B)
print *, r%j_nu, r%zeta_nu, r%beta(), r%kappa()          ! complex: (⊥, ∧)
```

| Method | Agreement | Residual in `(G + iωτ) f₁ = g₇` | Cost (N = 1601) |
|--------|-----------|----------------------------------|-----------------|
| `method_complex` | reference | ~1e-11 | 1.1 s / response |
| `method_paper` | ≤ 5e-9 (N=401), ≤ 8e-7 (N=1601) | up to ~7e3× larger (squared condition number) | 0.7 s / response |

### Algebraic closure

```fortran
use appelbe_fits, only : fit_response

complex(R8P) :: j_nu, zeta_nu
call fit_response(v_ratio=0.5_R8P, omega_tau=1._R8P, j_nu=j_nu, zeta_nu=zeta_nu)
! j⁰_eα = Z_α e n_α <v_α> j_nu,   ζ_eα = n_α <v_α> T_e zeta_nu   (T_e in J)
```

`log₁₀ωτ` is clamped to the fitted range `[-3, 3]`; between the six `v_α/v_Te` nodes the fitted values are interpolated linearly in `log(v_α/v_Te)`. Valid for α particles in DT only.

## Report

`fobis rule --ex report` regenerates `report/appelbe_report.pdf` from the current `results/`:

1. `scripts/report_numbers.py` writes `report/generated/` — number macros and table bodies;
2. `latexmk` (forced to pdflatex) compiles `report/appelbe_report.tex`, whose pgfplots figures read `results/*.dat` and `report/data/paper_*.dat` directly.

The digitized curves are refreshed only when needed, with the paper available in `references/`:

```bash
python3 scripts/digitize_paper.py
```

## Requirements

| Tool | Used for |
|------|----------|
| gfortran (tested 16) | build |
| [FoBiS.py](https://github.com/szaghi/FoBiS) ≥ 3.8 | build, dependency fetch, rules |
| [PENF](https://github.com/szaghi/PENF) | kind parameters (fetched automatically) |
| gnuplot (pngcairo) | preview plots |
| Python 3 + NumPy | report numbers; digitizer (+ Pillow, poppler `pdftoppm`) |
| TeX Live (pdflatex, pgfplots, latexmk) | report |

## Reference

B. Appelbe, M. Sherlock, O. El-Amiri, C. Walsh, J. Chittenden, *Modification of classical electron transport due to collisions between electrons and fast ions*, Phys. Plasmas **26**, 102704 (2019), [doi:10.1063/1.5114794](https://doi.org/10.1063/1.5114794).

`appelbe` is a companion of [adam](https://github.com/szaghi/adam): the closure is meant for **FLUME** (MHD), with **PRISM** (PIC) as a source of the fast-ion flux.
