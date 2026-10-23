# appelbe

>#### Electron transport modified by collisions with fast ions
> A KISS Fortran 2018 reproduction of Appelbe *et al.*, *Phys. Plasmas* **26**, 102704 (2019), Secs. III C–VI: the simple-algebraic closure, the kinetic Fokker–Planck solver behind it, and a LaTeX report comparing every result with the paper.

[![GitHub tag](https://img.shields.io/github/v/tag/szaghi/appelbe)](https://github.com/szaghi/appelbe/tags)
[![Docs](https://img.shields.io/badge/docs-vitepress-orange)](https://szaghi.github.io/appelbe/)
[![GitHub issues](https://img.shields.io/github/issues/szaghi/appelbe)](https://github.com/szaghi/appelbe/issues)
[![License: GPL v3](https://img.shields.io/badge/license-GPL%20v3-blue.svg)](https://github.com/szaghi/appelbe/blob/main/LICENSE.md)

| 🧮 **Simple-algebraic closure**<br>Appendix C fits of the collisionally induced current `j⁰_eα` and heat flow `ζ_eα` (α in DT) | ⚛️ **Kinetic solver**<br>Linearised electron `f₁` equation (Eq. 13) with e–e, e–i and e–fast-ion Fokker–Planck operators | 🔀 **Two solution methods**<br>The paper's Appendix B procedure (`GG + Ω²`) and an equivalent complex form `(G + iωτ) f₁ = g₇` | ✅ **Verified**<br>Epperlein–Haines Z=1 coefficients to 4 digits, exact Lorentz limits, Onsager symmetry to 5e-8 |
|:---:|:---:|:---:|:---:|
| 📊 **Secs. III C–VI reproduced**<br>All six figures, Tables I–IV, footnote 30, field advection/generation (Sec. V) | 🔍 **Direct comparison**<br>Paper curves extracted from its vector graphics (≈1e-4 of the axis span) and compared point by point | 📄 **Self-updating report**<br>LaTeX/pgfplots PDF built from the last run's results — no hand-copied numbers | ⚡ **KISS**<br>Dense matrices, no LAPACK, one dependency (PENF) — full run in about four minutes |

The **[documentation](https://szaghi.github.io/appelbe/)** has a tutorial, a cookbook, the reference and the API; the
**[reproduction report](report/appelbe_report.pdf)** has the full results, methods and discussion.

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
fobis build --mode static-gnu # the library alone: lib/libappelbe.a, use appelbe
fobis rule --ex tests         # verification suite (120 checks)
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
| Fig. 1 (Sec. III C) | electron `f₁` from e–α collisions, unmagnetised and `ωτ = 10` | `appelbe_fig1` | kinetic |
| Fig. 2 (Sec. III C) | unmagnetised `j⁰_eα / j⁰_α` for p, α, C⁶⁺ (dense, and at the paper's 25 samples) | `appelbe_fig2` | kinetic |
| Fig. 3, Tables I–IV | `j_ν`, `ζ_ν` vs `ωτ` at the paper's legend speeds and at the six table nodes, vs fits | `appelbe_fig3` | both |
| Footnote 30 | broad energy spectra vs a monoenergetic population at the mean energy | `appelbe_footnote30` | kinetic |
| **Fig. 4** (Sec. IV A) | heat flow, unmagnetised, 3.45 MeV α, vs `T_e` | `appelbe_fig4` | both |
| **Fig. 5** (Sec. IV B) | heat flow vs `ωτ`, flux ⊥ **B**, 1 and 15 keV | `appelbe_fig5` | both |
| **Sec. V A** | field advection velocity `j⁰_eα / (e n_e)` | `appelbe_sec5` | both |
| **Sec. V B** | field generation: C⁶⁺ fast-ignition beam, α flux across ∇T | `appelbe_sec5` | kinetic (+ fits for α) |
| **Fig. 6** (Sec. VI) | `μ∥`, `K∥` vs `n_α/n_e`, isotropic α population | `appelbe_fig6` | kinetic only |
| — | conventional coefficients, Lorentz limits, Onsager, grid convergence | `appelbe_validation` | kinetic |
| — | paper's Appendix B solver vs complex solver | `appelbe_solvers` | kinetic |

## Results at a glance

The paper does not state several choices behind its figures; the comparison reconstructs them (the *paper's set-up*,
`src/lib/appelbe_paper.F90`): an isotropic α population with `n_α/n_e = 10⁻³` kept in the collision operator, a coarse
speed grid (`u ∈ [0, 5]`, 199 nodes) with no node at `v_α`, the speed 1/3 printed as 0.33, and the Epperlein–Haines
*fitted* `β` in Fig. 5. Emulating them, **every curve of the paper is reproduced to ≤ 1.6% of its peak** (curves
extracted from the paper's vector graphics, accuracy ≈ 1e-4 of the axis span); max deviation, % of peak:

| Figure | Converged (this work) | Paper's numerics emulated | Algebraic closure |
|--------|-----------------------|---------------------------|-------------------|
| Fig. 1, `f₁⊥` at `ωτ = 10` | 18 (lobe depth) | 1.6 | — |
| Fig. 2, at the paper's samples | ≤ 0.044 abs. (C) | ≤ 0.006 abs. | — |
| Fig. 3 | ≤ 0.015 abs. (`j_ν`) | ≤ 0.0024 abs. | fits miss the figure by ≤ 0.009 |
| Fig. 4 | ≤ 0.57 | ≤ 0.46 | ≤ 3.1 |
| Fig. 5 (E&H `β`), 1 keV / 15 keV | 5.1 / 0.28 | 0.83 / 0.08 | 22 / 3.2 |
| Fig. 6 | ≤ 0.02 | ≤ 0.04 | — |

The converged solution is the physical one; the large converged deviations are the paper's discretisation error. The
algebraic closure's 22% at 1 keV is its node spacing (`j_ν` has a minimum between the nodes 1 and 0.5), not a paper
discrepancy.

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
- **The fast-ion runs keep `n_α/n_e = 10⁻³`** in the operator, not the `n_α ≪ n_e` limit of Sec. III: with it Fig. 2
  matches for p, α and C at once (carbon RMS 0.21 → 0.01).
- **Fig. 2 is a polyline through 25 temperatures**: it has no sample between `v_α/v_Te = 0.44` and 1, misses the
  minimum of the α curve there, and only appears to contradict Table I.
- **Fig. 5 uses the Epperlein–Haines fitted `β`** (their Table III), whose `β⊥` form is wrong at small `ωτ` (Sadler
  2021, Davies 2021) and puts `q∧` off by 18–29%; with it the figure is reproduced to 0.3% at 15 keV.
- **The paper's speed grid is coarse and unaligned** (h = 5/198, no node at `v_α`): its O(h) error makes Fig. 1's
  negative lobe 10% deeper and shifts Fig. 2 by up to 0.04 (carbon); "0.33" in Fig. 3 and Table I is 1/3.
- **Footnote 30** (broad spectra act as monoenergetic to 1%) holds for moderate spreads at `v_α/v_Te ≤ 0.5`, fails at
  `v_α/v_Te = 1` and for the slowing-down distribution (4–5%).
- **NRL Coulomb logarithms give `lnΛ_ee = lnΛ_ei`**, so the unit ratios of the solver are the paper's too.
- **Fig. 5 is consistent with a kinetic computation**, not with node-wise use of the paper's own fits (1 keV plateau: paper 6.15, kinetic 6.04, fits 6.43 ×10⁻¹⁶ W s keV⁻¹).
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
├── appelbe_distributions.F90  fast-ion energy spectra (Gaussian, flat, slowing-down) for footnote 30
├── appelbe_paper.F90          the paper's set-up, inferred from its figures
├── appelbe_fits.F90           Appendix C tables and rational fits (Eqs. C1-C8)
├── appelbe_closure.F90        heat flows (Eqs. 33-35), advection (40), field generation (43)
└── appelbe_io.F90             results/ tables
src/app/                       one driver per figure/section (appelbe_*)
src/tests/                     test programs (test_*) + assertion helper
scripts/                       run_tests.sh, make_figures.sh, make_report.sh,
                               digitize_paper.py, report_numbers.py, *.gp
report/                        appelbe_report.tex, data/ (curves extracted from the paper and Davies 2021)
```

### Kinetic solver

| Aspect | Choice |
|--------|--------|
| Units | `u = v/v_Te`, distributions per `n/v_Te³`, time in `τ_ei`: every `τ_ei Y_ab n_b` is a pure number |
| Grid | uniform, `N = 401` nodes on `[0, ≈7]`, stretched so a node sits exactly on `u_α` |
| Discretisation | 5-point finite differences, Simpson integrals, `f₁(u₁) = f₁(u₂)`, `f₁(u_N) = 0` (Appendix B) |
| Drives | electric field, temperature gradient, unit fast-ion flux — three right-hand sides, one solve |
| Fast ions | monoenergetic (closed-form I/J integrals), or any speed distribution `F(u)` passed to `init` (quadrature) |
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
2. `latexmk` (forced to pdflatex) compiles `report/appelbe_report.tex`, whose pgfplots figures read `results/*.dat` and `report/data/*.dat` directly.

The extracted curves are refreshed only when needed, with the source documents in `references/` (git-ignored): the
paper (`appelbe-2019.pdf`) and the OSTI accepted manuscript of Davies *et al.*, Phys. Plasmas 28 (2021), whose
Epperlein–Haines curve cross-checks our transcription of E&H 1986 Table III (`davies-2021.pdf`). Both are vector PDFs read with `mutool trace`:

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
| Python 3 + NumPy | report numbers; curve extraction (+ `mutool` from MuPDF) |
| TeX Live (pdflatex, pgfplots, latexmk) | report |

## Reference

B. Appelbe, M. Sherlock, O. El-Amiri, C. Walsh, J. Chittenden, *Modification of classical electron transport due to collisions between electrons and fast ions*, Phys. Plasmas **26**, 102704 (2019), [doi:10.1063/1.5114794](https://doi.org/10.1063/1.5114794).

`appelbe` is a companion of [adam](https://github.com/szaghi/adam): the closure is meant for **FLUME** (MHD), with **PRISM** (PIC) as a source of the fast-ion flux.
