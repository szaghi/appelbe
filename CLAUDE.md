# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project purpose and state

`appelbe` replicates the **simple-algebraic closure** of Appelbe et al. (2019): the electron current and heat
flow that collisions with a drifting fast-ion population induce in a quasineutral plasma. It is a companion
to `~/fortran/adam`, specifically:

- **FLUME** (MHD): the consumer of the new Ohm's-law, induction and heat-flow terms.
- **PRISM** (with PIC): a natural source of the fast-ion flux `n_α⟨v_α⟩` as a particle moment.

The current code is a **fast, simple reproduction of Secs. IV–VI**. The goals are simplicity and
maintainability, not performance: dense matrices, no parallelism, no LAPACK. When wiring into adam, read
`~/fortran/adam/CLAUDE.md` first. It defines the realm and component architecture, and it forbids new
`*_global` singletons.

## Commands

```bash
fobis fetch                       # clone PENF into src/third_party/ (the only dependency)
fobis build --mode gnu            # -O2; builds every program under src/ into exe/ (no single target)
fobis build --mode gnu-debug      # -fcheck=all, FP traps (invalid, zero, overflow), -finit-real=snan
fobis rule --ex tests             # scripts/run_tests.sh: runs every exe/test_*, stops on first failure
fobis rule --ex figures           # scripts/make_figures.sh: every exe/appelbe_* -> results/, then gnuplot previews
fobis rule --ex report            # scripts/make_report.sh: report/generated/*.tex + report/appelbe_report.pdf
python3 scripts/digitize_paper.py # refresh report/data/paper_*.dat from the paper PDF (needs references/)
./exe/test_fits                   # run one test program directly
./exe/appelbe_fig5                # run one driver; writes results/fig5_Te01keV.dat, results/fig5_Te15keV.dat
```

- Run everything from the repo root: the drivers write to `./results/`, and the scripts assume the root.
- The fobos rules call bash scripts, because fobis rules do not run through a shell (a `for` loop inside a
  rule fails).
- The full figure run takes about a minute; `appelbe_solvers` (sweep up to 1601 nodes) is most of it.
- LAPACK is not used on purpose. Only the `liblapack.so.3` runtime is installed (no `-dev` symlink), and the
  self-contained elimination in `appelbe_linear_solver.F90` is fast enough.
- Plots: gnuplot for previews (`results/*.png`); the report uses pgfplots reading `results/*.dat` directly.
  The system matplotlib is broken (NumPy 1/2 ABI mismatch); NumPy and PIL themselves work (digitizer).
- `make_report.sh` forces pdflatex with `-e '$pdflatex=...'`: the user's `~/.latexmkrc` maps `$pdflatex` to
  xelatex. Do not edit the user's rc.
- The Python scripts follow the user's Ruff conventions (`ruff check scripts` must pass).

## Architecture

There are two routes to the same closure `(j_nu, zeta_nu)`, and they deliberately coexist:

1. **Algebraic closure** (`src/lib/appelbe_fits.F90`): the Appendix C tables. It is valid only for α in DT.
2. **Kinetic solver** (`src/lib/appelbe_kinetic.F90`): Eq. (13) discretized as in Appendix B. It is
   required for Sec. VI (the isotropic F₀ is not in the fits), for β⊥ and β∧ (the paper never tabulates
   them), for other species (carbon in Sec. V), and to validate route 1.

The kinetic solver has **two interchangeable methods**, selected by `response(ωτ, method=...)`:

- `method_complex` (default): one complex solve of `(G + iωτ) f₁ = g₇`, with f₁ = f₁ₓ + i f₁ᵧ and
  `b×f₁ = i f₁`. The real part is ⊥ (along the drive), the imaginary part is ∧ (along b×drive): exactly the
  Eq. (27) convention, so tensor algebra is complex arithmetic (β = μ/σ − 5/2; Eqs. (34)–(35) are one
  complex product).
- `method_paper`: the paper's Appendix B procedure, `(GG + Ω²) f₁ₓ = G g₇ₓ`, `(GG + Ω²) f₁ᵧ = −Ω g₇ₓ`, with GG
  by matrix multiplication, and `G f₁ = g₇` at ωτ = 0 (Eq. B8). The printed Eqs. (B6)–(B7) read
  "(G ± Ω) g₇ₓ,ᵧ", which drops the cross-component coupling; the implemented form follows from Eq. (B5).
- They agree to ~1e-9 at 401 nodes (~1e-7 at 1601; `test_solvers`). The paper's residual is up to ~1e4
  larger (squared condition number), but it is ~2x cheaper (real arithmetic).

The rest of the library and tooling:

- `appelbe_closure.F90` turns a closure into physics: the heat flows of Eqs. (33)–(35), advection (40)
  and generation (43). `appelbe_plasma.F90` holds τ_ei (Eq. 14), NRL lnΛ, and the Eq. (43) coefficient.
- Drivers `src/app/appelbe_*.F90` write `results/*.dat` (one `#` header line): `fig2` to `fig6`, `sec5`
  (`sec5.txt` plus `sec5_{advection,carbon,gradient}.dat`), `validation`, `solvers` (+ `convergence.dat`).
  Figs. 2 and 3 are outside Secs. IV–VI: Fig. 2 underpins Sec. V B and Fig. 3 validates route 1.
- Report pipeline: `scripts/digitize_paper.py` → `report/data/paper_<fig>_<curve>.dat` (committed; derived
  from the git-ignored PDF). `scripts/report_numbers.py` → `report/generated/` (macros and table bodies,
  git-ignored). `report/appelbe_report.tex` reads `../results/`, `data/` and `generated/`, so every number in
  the PDF comes from the last run. Table bodies are pulled in with `\inputtable` (the `\@@input`
  primitive): LaTeX's robust `\input` breaks a following `\bottomrule`. Number macros use `\ensuremath`.

Kinetic-solver design points that are not obvious from any single file:

- **Normalized units:** u = v/v_Te, each distribution normalized by its own n/v_Te³, time in τ_ei. Every
  `τ_ei Y_ab n_b` becomes a pure number (`k_i`, `k_e`, `k_a`, see the module header). The drive vectors
  are dimensionless via λ = v_Te τ_ei.
- **One solve, three right-hand sides:** `response(ωτ)` solves the E drive, the ∇T drive, and a
  **unit** fast-ion flux (n_α/n_e = 1, γ_α = 1, allowed because the response is linear). It returns σ, μ,
  τ, K in Epperlein–Haines units, plus `j_nu` and `zeta_nu` in Appendix C normalization.
- `kinetic_params%n_ratio` controls **only** the isotropic F₀ inside the operator (Sec. VI). Flux runs
  keep it at 0, which is the paper's n_α ≪ n_e assumption.
- **Boundary conditions:** the operator is assembled row by row on the full grid, then reduced. `f(1) = f(2)`
  folds column 1 into column 2 and `f(n) = 0` drops column n.
- **Node alignment at u_a (essential):** `init` stretches u_max by < half a cell so a node sits exactly on
  u_a, and `heaviside` treats |x| ≤ 1e-8 h as the origin (value 1/2). Without alignment the fast-ion moments
  carry an erratic O(h) error stuck at ~3e-3; without the tolerance, rounding makes the step randomly 0/1 at
  the aligned node (2% jumps at v_a/v_Te = 0.6–0.7; regression checks in `test_fast_ions`). With both, the
  moments converge at second order (~2e-4 at 401 nodes). The δ functions of F₀, F₁ are unit-area hats;
  `u_a ≥ 4h` is enforced, so the `v_a/v_Te = 0.025` table row cannot run on the default grid.
- **Coulomb logarithms:** all ratios default to 1 (`lnl_ee_ratio = lnl_ea_ratio = 1`). The paper used NRL
  values with unstated ratios. This is the most likely source of the 1–2% residual against its tables.

## Validation status

Measured on 2026-09-30. `fobis rule --ex tests` runs 109 checks, and all pass in both modes. The full
comparison is in `report/appelbe_report.pdf`; the key results:

- **Conventional coefficients, Z = 1:** α∥ = 0.5061, β∥ = 0.7029, κ∥ = 3.2031, the Epperlein–Haines (1986)
  values (α∥ matches Eq. 42). Lorentz limits exact (3π/32, 3/2, 128/3π). Onsager τ = μ − (3/2)σ holds to
  5e-8 over ωτ = 0–1e3. Converged 401 vs 1601 nodes to 1e-7.
- **Kinetic vs Appendix C (Fig. 3):** max |Δj| ≤ 0.017 and |Δζ| ≤ 0.11 (about 1% of the ranges). The ∧ sign
  convention is **pinned**: with Eq. (27), j∧ < 0 and ζ∧ > 0, as in the tables.
- **Direct comparison with digitized paper curves** (max deviation, % of curve max): Fig. 4 ≤ 0.8%
  (components), Fig. 5 q⊥ 2–4%, Fig. 6 ≤ 0.2% (all six curves; the earlier "1 keV is 3% low" note came from
  misreading a low-resolution render and was wrong). Fig. 5 q∧: minima within 4% (15 keV) and 14% (1 keV),
  flanks shifted ~0.1 decade in ωτ, possibly because the paper used E&H *fitted* β⊥, β∧.
- **Paper internal inconsistency:** Fig. 2 (α) gives −1.337 at v_a/v_Te = 0.5, its own Table I gives −1.39;
  the kinetic solver gives −1.385. Our α curve has a converged minimum ≈ −1.50 near v_a/v_Te = 0.8, where the
  paper's Fig. 2 rises monotonically.
- **Paper's Fig. 5 was computed kinetically, not from its fits:** at 1 keV its low-ωτ plateau is 6.15e-16,
  our kinetic value 6.02e-16, the interpolated fits 6.45e-16.
- **Algebraic closure weak spot:** between the nodes v_a/v_Te = 1 and 0.5 (T_e ≈ 0.5–1.9 keV for 3.45 MeV α)
  it is 7% high on the q⊥ plateau and 25% shallow at the q∧ minimum (1 keV), relative to the kinetic
  solution. For FLUME, regenerate a denser table with the kinetic solver or fit in 2-D.
- **Sec. V:**
  - Advection: |u_adv| is (2–3)×10⁴ m/s, and the ⊥ component reverses sign across ωτ ≈ 1. The paper
    says "up to 10⁴" (half its own 2(n_α/n_e)⟨v_α⟩ estimate).
  - Scenario C: j⁰_eα = −(3.6–4.8)×10¹⁵ A/m² (the paper's 6×10¹⁵ exceeds the bound Z_α e flux·max|j_ν|),
    and dB/dt·T_keV^{5/2} is (2–3.5)×10¹³ (the paper says 6×10¹³).
  - Scenario B (carbon beam): at 1–2 keV the beam has v_a/v_Te = 2–3, beyond Fig. 2. There
    j⁰_eα/j⁰_α collapses (−0.05 at 1 keV, −1.7 at 2 keV). The paper's blanket "≈ −5" overestimates the
    low-T end, so the kinetic rates are 3×10¹²–6×10¹³ T/s against the paper's 10¹³–10¹⁵.

## Reference

`references/appelbe-2019.pdf` is git-ignored (`references/*`) because it is publisher-copyrighted. Never
force-add it.

> B. Appelbe, M. Sherlock, O. El-Amiri, C. Walsh, J. Chittenden, *Modification of classical electron
> transport due to collisions between electrons and fast ions*, Phys. Plasmas **26**, 102704 (2019),
> doi:10.1063/1.5114794

Equation numbers below are the paper's. Cite them in code comments. Everything marked **[verified]** was
recomputed in a session on 2026-09-30. Everything marked **[inference]** is not stated in the paper.

## Paper summary

### Physics in one paragraph

Three species: thermal electrons `e`, thermal ions `i`, and a dilute nonthermal fast-ion population `α`
(any fast ion, not only alphas). If the fast-ion distribution is **anisotropic** (it has a net flux), e–α
Coulomb collisions perturb the electron distribution away from Maxwellian, even for `n_α ≪ n_e`. This
perturbation drives an electron current `ξ_eα` and heat flow `ζ_eα`. The electron current does **not**
cancel the fast-ion current `j⁰_α`, so there is a net **collisionally induced current** `j⁰_eα = ξ_eα + j⁰_α`
that enters Ohm's law, the heat-flow equation and the induction equation. The isotropic part of the α
distribution drives no transport (Sec. VI).

### Assumptions (Sec. II)

A code must check or document each of these:

- Quasineutral `n_e = Z_i n_i + Z_α n_α`, with `n_α ≪ n_e`. The F₀ (isotropic α) effect on the
  conventional coefficients is below 1% for `n_α/n_e ≲ 10⁻³` and significant for `n_α/n_e ≳ 10⁻²`
  (Fig. 6). Beyond that point the closure is incomplete.
- `T_e ~ T_i` and `E_α ≫ T_e`, so fast ions slow on electrons and α–i collisions are dropped.
- Time scales `τ_αe ≫ τ_ei` (Eq. 5): the electrons are quasi-steady (`∂f₁/∂t = 0`), so the closure is
  **local and instantaneous**. For alphas, also `τ_⟨σv⟩ ≫ τ_ei` (Eq. 7).
- Length scales `v_α τ_ei ≪ l_f` (Eq. 6).
- Thermal ions and the e–i fluid are **at rest**. The results are in the ion rest frame, and a moving fluid
  needs a frame transformation. `j_T` is frame-invariant.
- Electron `f₂` and higher are neglected (no pressure anisotropy). `f₀` is Maxwellian (Eq. 4) with
  `v_Te = √(2T_e/m_e)`.
- The calculations use `T_i = T_e` and `n_e = Z_i n_i`.

### Kinetic model (Sec. III, Appendices A and B), i.e. the non-algebraic route

- The Cartesian-tensor expansion `f_e = f₀ + f₁·v/v + …` (Eq. 2) gives the steady `f₁` equation (Eq. 8).
  The collision terms are Shkarofsky's: `C_ei1 = −Y_ei n_i f₁/v³` (Eq. 9), `C_ee1` (Eq. A2), `C_eα1`
  (Eq. A5), where `Y_ab = (1/4π)(q_a q_b/ε₀ m_a)² ln Λ_ab` (Eq. A1).
- The fast ions use the same expansion, `F_α = F₀ + F₁·v/v` (Eq. 11). It is valid even far from isotropic
  provided `F₀ ≥ |F₁|`.
- The result is the linear integro-differential equation (Eq. 13), with scalar coefficients `g₁…g₆`
  (Eqs. A8–A13) and a vector source `g₇` (Eq. 15). `g₇` is linear in `∇n_e`, `∇T_e`, `E` and `F₁`.
- The electron-ion collision time is `τ_ei = 3√π v_Te³ / (4 Y_ei n_i)` (Eq. 14). **[verified]** It is
  identical to Braginskii's `τ_e`. The Hall parameter is `ωτ` with `ω = eB/m_e`.
- Solver (Appendix B): with `b = ẑ`, the equation splits into `(GG+Ω²)f₁ₓ = (G+Ω)g₇ₓ`,
  `(GG+Ω²)f₁ᵧ = (G−Ω)g₇ᵧ` and `Gf₁z = g₇z` (Eqs. B6–B8). It uses a uniform grid on `[0, v_max]` with N odd,
  boundary conditions `f₁(∞)=0` and `∂f₁/∂v(0)=0`, 5-point finite differences, Simpson's rule for the
  integrals, and LU decomposition.
- Moments: `ξ_eα = −(4πe/3)∫v³f₁dv` (Eq. 16), `ζ_eα = (2πm_e/3)∫v⁵f₁dv` (Eq. 17), and
  `j⁰_α = n_α Z_α e⟨v_α⟩ = (4πZ_α e/3)∫v³F₁dv` (Eq. 20).

This route is only needed to **regenerate or extend the fits**, for example to other fast-ion species.

### Transport relations (Sec. III B)

These relations are the output side of the closure.

```
E   = −∇P_e/(e n_e) + σ⁻¹·(j_T − j⁰_eα) − (1/e) β·∇T_e                               (23)
q_e = −κ·∇T_e − (T_e/e)(β + 5/2 I)·(j_T − j⁰_eα) + ζ_eα                              (24)
∂B/∂t = (1/e n_e)∇T_e×∇n_e + (1/e)∇×[β·∇T_e]
        − ∇×{(1/e n_e)[j_T×B + (1/e n_e) α·j_T]}
        + ∇×{(1/e n_e)[j⁰_eα×B + (1/e n_e) α·j⁰_eα]}                                 (39)
```

- `σ, β, κ, α` are the **conventional** coefficients, meaning Epperlein & Haines (1986) with no fast ions.
  Using them is justified only for `n_α ≪ n_e` (Sec. VI).
- Tensor convention (Eq. 27): `φ·s = φ∥(b·s)b + φ⊥ b×(s×b) + φ∧ b×s`. The resistivity `α` uses a **minus**
  sign on the `∧` term (Eq. 38), and σ⁻¹ follows Eq. (28). Getting these signs wrong is the most likely bug.
- Unlike `j_T = ∇×B/μ₀`, `j⁰_eα` is an **independent source**: it acts on B regardless of the existing
  current or field.
- **Advection** (Eq. 40): `∂B/∂t = ∇×(j⁰_eα/(e n_e) × B)`, so `u_adv = j⁰_eα/(e n_e) ≈ (2n_α/n_e)⟨v_α⟩`
  for alphas. Its direction flips with ωτ (Fig. 3).
- **Generation** in an unmagnetized plasma (Eq. 41): `∂B/∂t = ∇T_e×∇n_e/(e n_e) + ∇×[α∥ j⁰_eα/(e n_e)²]`.
  The first term is the Biermann battery. The second generates B from zero even when `j_T = 0`.
- For Z_i = 1, `α∥ = 0.506 m_e n_e/τ_ei` (Eq. 42). In cylindrical coordinates with an axial `j⁰_eα(r)`:
  `∂B_θ/∂t = 1.65×10⁻⁹ (lnΛ_ei/T_keV^{3/2}) [−∂j⁰_eα/∂r + (3/2)(j⁰_eα/T_keV) ∂T_keV/∂r]` in T s⁻¹
  (Eq. 43). **[verified]** The prefactor follows from Eqs. (10), (14) and (42) with SI constants and
  evaluates to 1.6503×10⁻⁹.
- Heat flow, unmagnetized (Eq. 33): `q_e = (T_e/e)(β∥ + 5/2) j⁰_eα + ζ_eα`. The `j⁰_eα` term opposes the
  α flux, `ζ_eα` is parallel to it, and `ζ_eα` wins (Fig. 4). Magnetized, with the flux ⊥ B, see
  Eqs. (34) and (35). `q_e⊥` **increases** with ωτ, because `j⁰_α` is not magnetized (large Larmor
  radius). This heat flow is not suppressed by magnetization.

### The simple-algebraic closure (Sec. III C and Appendix C)

**This closure is what the repo implements.** For a monoenergetic fast-ion population
(`F₀ = n_α δ(v−v_α)/4πv²` and `F₁ = γ_α F₀ û_α`, Eqs. 29 and 30), with `v_α = √(2E_α/m_α)`, anisotropy
`γ_α ∈ [0,1]` and `⟨v_α⟩ = (γ_α/3) v_α û_α` (Eq. 31), the results are:

- `f₁`, `ξ_eα` and `ζ_eα` are all proportional to the fast-ion flux `n_α⟨v_α⟩`. They are independent of
  `n_e` (for `n_α ≪ n_e`) and depend only on `v_α/v_Te` and `ωτ`.
- The paper's footnote 30 states that a broad-energy distribution is well represented (to about 1%) by a
  monoenergetic one, provided `v_α` uses the **mean** energy and `⟨v_α⟩` is preserved.
- Unmagnetized limit for any species as `v_α/v_Te → 0`: `j⁰_eα/j⁰_α ≈ 1 − Z_α/Z_i` (Eq. 32). This gives
  −1 for α in DT and −5 for C⁶⁺ (Fig. 2).

Appendix C gives fits **for α particles in DT only**, with Z_α = 2, Z_i = 1 (average D-T ion), and lnΛ
from the NRL formulary. `⊥` means along the α flux, which is assumed ⊥ B. `∧` means along `b×û_α`.

```
(j⁰_eα)⊥ = Z_α e n_α⟨v_α⟩ j⊥ν        (C1)     (ζ_eα)⊥ = n_α⟨v_α⟩ T_e ζ⊥ν     (C3)
(j⁰_eα)∧ = Z_α e n_α⟨v_α⟩ j∧ν        (C2)     (ζ_eα)∧ = n_α⟨v_α⟩ T_e ζ∧ν     (C4)

j⊥ν = (p1 x³ + p2 x² + p3 x + p4) / (x⁴ + q1 x³ + q2 x² + q3 x + q4)                 (C5)
j∧ν = (r1 x² + r2 x + r3)         / (x⁴ + s1 x³ + s2 x² + s3 x + s4)                 (C6)
ζ⊥ν, ζ∧ν: same forms with primed coefficients                                        (C7, C8)
x = log10(ωτ), valid for −3 ≤ x ≤ 3
```

`T_e` in (C3) and (C4) is in **joules**, which makes `ζ⊥ν` and `ζ∧ν` dimensionless. **[verified]** With
β∥ ≈ 0.71 at 15 keV, Eq. (33) plus the tables reproduce Fig. 5's `q_e⊥/(n_α⟨v_α⟩T_keV) ≈ 5.6×10⁻¹⁶ W s keV⁻¹`.
The ωτ → ∞ limit gives `q_e⊥/(n_α⟨v_α⟩T_e) → (5/2)·2 = 5`, matching Fig. 5's high-ωτ plateau.

Coefficient tables, transcribed from a 220-dpi render and **[verified]** against endpoint limits (see below).
Columns are `v_α/v_Te | ωτ=0 value | coefficients`.

```
Table I   j⊥ν :  va/vTe  wt=0    p1     p2     p3     p4     q1     q2     q3     q4
                 1      -1.42   9.72   7.68  41.49   9.40   2.59  26.80  18.53  19.55
                 0.5    -1.39   8.71   9.15  36.13   6.13   2.82  23.32  16.81  18.25
                 0.33   -1.21   8.17   9.63  33.78   6.63   2.45  22.75  16.32  18.11
                 0.25   -1.13   7.98   9.80  33.07   6.92   2.27  22.68  16.21  18.19
                 0.1    -1.02   7.74  10.16  32.96   7.73   2.00  23.10  16.31  18.77
                 0.025  -0.99   7.70  10.25  32.98   7.90   1.94  23.20  16.34  18.90

Table II  j∧ν :  va/vTe  wt=0    r1      r2      r3      s1     s2     s3     s4
                 1       0      0.1145  0.1201 -1.074  0.993  2.213  1.252  1.170
                 0.5     0      0.1509  0.0895 -1.410  0.523  2.314  1.382  1.559
                 0.33    0      0.1447  0.0660 -1.377  0.465  2.406  1.456  1.659
                 0.25    0      0.1396  0.0527 -1.354  0.457  2.449  1.488  1.693
                 0.1     0      0.1307  0.0450 -1.283  0.461  2.459  1.496  1.699
                 0.025   0      0.1293  0.0445 -1.269  0.461  2.459  1.496  1.698

Table III ζ⊥ν :  va/vTe  wt=0    p1'     p2'    p3'     p4'    q1'   q2'    q3'    q4'
                 1      14.10  -14.06  61.74  -81.46  35.16  6.84  26.99  23.01  16.38
                 0.5    12.30  -12.82  56.77  -74.79  31.06  6.81  27.34  22.94  16.59
                 0.33   11.14  -11.68  51.80  -68.22  28.16  6.81  27.39  22.93  16.62
                 0.25   10.68  -11.22  49.80  -65.57  27.01  6.81  27.41  22.93  16.63
                 0.1    10.08  -10.60  47.02  -61.91  25.49  6.81  27.41  22.93  16.63
                 0.025   9.96  -10.48  46.50  -61.23  25.21  6.81  27.41  22.93  16.63

Table IV  ζ∧ν :  va/vTe  wt=0    r1'      r2'      r3'    s1'    s2'    s3'    s4'
                 1       0      -0.6999  -0.5442  6.606  1.552  3.133  2.013  1.356
                 0.5     0      -0.5771  -0.4996  5.471  1.531  2.983  1.868  1.274
                 0.33    0      -0.519   -0.4577  4.920  1.528  2.962  1.849  1.262
                 0.25    0      -0.4964  -0.4404  4.706  1.527  2.955  1.843  1.259
                 0.1     0      -0.4680  -0.4157  4.437  1.526  2.953  1.841  1.258
                 0.025   0      -0.4627  -0.4110  4.387  1.526  2.953  1.841  1.258
```

Endpoint checks for all 24 rows (**[verified]**, and they belong in the unit tests):

- The fit at `x = −3` reproduces the `ωτ=0` column to within 0.8%. The worst row is `v_α/v_Te = 0.025`
  (j⊥), at 0.71%. An earlier note said "0.7%", and the test caught that as an overstatement.
- At `x = +3`: `j⊥ν → 1` (0.991 to 0.996), because electron current is suppressed and only `j⁰_α` remains.
  `j∧ν`, `ζ⊥ν` and `ζ∧ν` go to 0.
- At `x = 0` for `v_α/v_Te = 1`: `j⊥ν = 0.481`, `j∧ν = −0.918`, `ζ⊥ν = 2.147`, `ζ∧ν = 4.872`.
- The fits overshoot slightly: `j⊥ν` peaks at 1.005 and `ζ⊥ν(x=3) ≈ −0.056`.

Mapping the node values to temperature for 3.45 MeV α: `v_α/v_Te = √(E_α m_e/(T_e m_α)) ≈ 0.688/√T_keV`
**[verified]**. The nodes 1 → 0.025 therefore cover T_e ≈ 0.47 keV → 755 keV, and the paper's example
point, 2 keV, gives 0.486.

### Implementation decisions the paper leaves open (as implemented)

1. **Interpolation in `v_α/v_Te`** is unspecified by the paper. Fig. 3's legend even uses values (1, 0.33,
   0.2, 0.05) that differ from the table nodes. *Implemented*: linear in `log(v_α/v_Te)` on the fitted
   **values**, with the nearest node used outside [0.025, 1] (`fit_response`). *Known weakness*: between
   the widely spaced nodes 1 and 0.5 (T_e ≈ 0.5–1.9 keV for 3.45 MeV α) the interpolated closure departs
   visibly from the kinetic one (Fig. 5 at 1 keV).
2. **Outside `−3 ≤ x ≤ 3`**: *implemented* by clamping x to [−3, 3]. This is continuous everywhere, and
   ωτ = 0 maps to x = −3, within 0.8% of the tabulated column. `log10(0)` is never evaluated.
3. **General 3D orientation [inference]**: the paper only treats flux ⊥ B. Decompose `⟨v_α⟩` with Eq. (27),
   using the `ωτ=0` value for the component along `b` (electrons are unmagnetized along B), `j⊥ν` and `ζ⊥ν`
   for `b×(û×b)`, and `j∧ν` and `ζ∧ν` for `b×û`. The **handedness is now pinned**: the kinetic solver,
   built on the Eq. (27) convention, reproduces the signs of Tables II and IV (`test_fast_ions`). This is
   not implemented yet, because it is needed only for coupling to FLUME; the reproduction uses flux ⊥ B.
4. **Species other than α in DT**: the fits do not apply. The only algebraic information is Eq. (32)
   (unmagnetized, `v_α/v_Te → 0`) and Fig. 2. *Implemented*: use the kinetic solver (see Sec. V B carbon).
5. **Conventional coefficients**: *implemented* by computing them with the same kinetic solver (with no
   fast ions), which reproduces Epperlein & Haines exactly for Z = 1. For FLUME, use a fit of the same
   E&H data, so that the closure and the background transport are consistent.

### Paper errata and quirks

- Sec. V B writes current densities as `A m⁻³` (`j⁰_α = 3.4×10¹⁷`, `j⁰_eα ≈ 6×10¹⁵`). They are `A m⁻²`.
- The same section quotes `j⁰_eα ≈ 6×10¹⁵ A m⁻²` for an α flux of 10³⁴ m⁻² s⁻¹. But `Z_α e n_α⟨v_α⟩` is
  3.2×10¹⁵, and |j⊥ν| ≤ 1.42, so the tables give |j⁰_eα| ≈ (3.2–4.5)×10¹⁵. The paper shows no arithmetic.
  Treat its `6×10¹³ T_keV^{-5/2} T s⁻¹` estimate as order-of-magnitude only; it also implies lnΛ ≈ 4.
- Eqs. (B6)–(B7) print "(G ± Ω) g₇ₓ,ᵧ". The right-hand sides that follow from Eq. (B5) are G g₇ₓ + Ω g₇ᵧ and
  G g₇ᵧ − Ω g₇ₓ (implemented in `solve_paper`).
- Fig. 2 contradicts Table I at v_α/v_Te = 0.5 (−1.34 against −1.39); the kinetic solver sides with Table I.
- The "anchors" below are the paper's own estimates. Several are measured high (see Validation status and
  `report/appelbe_report.pdf`), so never use them as benchmarks.

### Order-of-magnitude anchors (sanity checks, not golden values)

- NIF hotspot: α flux ~10³⁴ m⁻² s⁻¹ and T_e 1–10 keV give e–α heat flow 10¹⁹–10²⁰ W m⁻². That is
  comparable to conduction losses, and below the α energy flux (~5×10²¹ W m⁻²).
- B advection with `n_α/n_e ~ 10⁻³` and `⟨v_α⟩ ≤ 10⁷ m s⁻¹` gives `u_adv` up to ~10⁴ m s⁻¹.
- Ion fast ignition, with 200 MeV C⁶⁺, `j⁰_α = 3.4×10¹⁷ A m⁻²`, `j⁰_eα ≈ −5 j⁰_α`, r = 10 μm and
  T_e 1–10 keV, gives `∂B/∂t` of 10¹³–10¹⁵ T s⁻¹ from Eq. (43).
