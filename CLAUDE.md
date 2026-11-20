# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project purpose and state

`appelbe` replicates the **simple-algebraic closure** of Appelbe et al. (2019): the electron current and heat
flow that collisions with a drifting fast-ion population induce in a quasineutral plasma. It is a companion
to `~/fortran/adam`, specifically:

- **FLUME** (MHD): the consumer of the new Ohm's-law, induction and heat-flow terms.
- **PRISM** (with PIC): a natural source of the fast-ion flux `n_α⟨v_α⟩` as a particle moment.

The current code is a **fast, simple reproduction of Secs. III C–VI** (all six figures, Tables I–IV, footnote 30).
Beyond the paper, the solver accepts **any electron f₀** (analytic or tabulated). This is for L. Senni's ECE/TS
discrepancy work (IAC-CNR, INDACO code; talk `references/ICFDT8_LS.pdf`), and it is now the first goal. See "Non-Maxwellian
electrons" below.
The goals are simplicity and maintainability, not performance: dense matrices, no parallelism, no LAPACK. When wiring into adam, read
`~/fortran/adam/CLAUDE.md` first. It defines the realm and component architecture, and it forbids new
`*_global` singletons.

## Commands

```bash
fobis fetch                       # clone PENF into src/third_party/ (the only dependency)
fobis build --mode gnu            # -O2; the drivers src/app/appelbe_* into bin/ (no single target)
fobis build --mode gnu-debug      # -fcheck=all, FP traps (invalid, zero, overflow), -finit-real=snan
fobis build --mode tests-gnu      # the tests src/tests/test_* into exe/ (tests-gnu-debug: debug flags)
fobis rule --ex tests             # scripts/run_tests.sh (scaffold-managed): runs every executable in exe/, PASS/FAIL each
fobis rule --ex makecoverage-analysis  # what CI runs: tests-gnu-debug with coverage, docs/public/coverage.json
fobis rule --ex figures           # scripts/make_figures.sh: every bin/appelbe_* -> results/, then gnuplot previews
fobis rule --ex report            # make_report.sh: report/generated/*.tex, report/appelbe_report.pdf, docs/public/figures/*.svg
fobis build --mode static-gnu     # the library alone: lib/libappelbe.a + lib/mod (use appelbe, the umbrella module)
fobis rule --ex docs-examples     # scripts/docs_examples.py: build/run docs/examples/src -> snippets/, output/
cd docs && npm install && npm run docs:dev   # the VitePress site (formal regenerates docs/api/ first)
python3 scripts/digitize_paper.py # refresh report/data/*.dat from the vector PDFs in references/ (needs mutool)
./exe/test_fits                   # run one test program directly
./bin/appelbe_fig5                # run one driver; writes results/fig5_Te01keV.dat, results/fig5_Te15keV.dat
./bin/appelbe_electrons f0.dat    # tabulated electron f0 (columns u_L, f0): readouts printed, results/electrons_table_*
fobis fetch -f fobos-gui          # the GUI's deps (PENF, FIGURE v0.8.0 + its native layer: CMake) into src/gui/third_party/
fobis build -f fobos-gui --mode gui-gnu        # bin/gui/appelbe-gui (gui-gnu-debug: debug flags, bin/gui-debug/)
fobis build -f fobos-gui --mode gui-tests-gnu  # the GUI's headless tests src/gui/tests/test_gui_* into exe/gui/
fobis rule -f fobos-gui --ex gui-tests         # scripts/run_gui_tests.sh exe/gui (run from the root: tests read src/gui/share)
fobis build -f fobos-gui --mode gui-release-gnu && scripts/package_gui.sh  # build/package/appelbe-gui-vX.Y.Z-<os>-<arch>.*
bin/gui-release/appelbe-gui --self-test        # headless self-check of the (packaged) program, exit 0 when ok
bin/gui/appelbe-gui --screenshots docs/public/gui  # the user guide's pictures, headless (after interface changes)
python3 scripts/gui_help.py       # the Help window's text from docs/guide/gui-user.md (run_gui_tests.sh checks it)
```

- Run everything from the repo root: the drivers write to `./results/`, and the scripts assume the root.
- The fobos rules call bash scripts, because fobis rules do not run through a shell (a `for` loop inside a
  rule fails).
- The full figure run takes about four minutes (`appelbe_fig3`, `appelbe_solvers`, `appelbe_footnote30` dominate).
- LAPACK is not used on purpose. Only the `liblapack.so.3` runtime is installed (no `-dev` symlink), and the
  self-contained elimination in `appelbe_linear_solver.F90` is fast enough.
- Plots: gnuplot for previews (`results/*.png`); the report uses pgfplots reading `results/*.dat` directly.
  The system matplotlib **and SciPy** are broken (NumPy 1/2 ABI mismatch); NumPy itself works (the report script has
  its own cubic spline).
- Curve extraction (`digitize_paper.py`) reads the paper's figures as **vector graphics** (`mutool trace`): curves are
  filled stroke outlines, reduced to centre lines; axes are calibrated from the tick marks (residual <= 1.1e-4 of the
  span). Accuracy checked on Fig. 1's dotted `f0 = exp(-u^2)`: bias 1e-5, scatter 2e-4 of the span. No raster step.
- `make_report.sh` forces pdflatex with `-e '$pdflatex=...'`: the user's `~/.latexmkrc` maps `$pdflatex` to
  xelatex. Do not edit the user's rc.
- The Python scripts follow the user's Ruff conventions (`ruff check scripts` must pass).
- Documentation: VitePress in `docs/`, structured like foresight (guide/, manual/tutorial + cookbook, api/ by formal,
  `.github/workflows/docs.yml` deploys to Pages). Every code block of the tutorial/cookbook is a program in
  `docs/examples/src/` (`!run` / `!region` markers); its snippets and outputs are generated and committed, so the CI
  needs no Fortran. After changing the API or results, rerun `docs-examples` and `report`.
- **Figures: one source.** The report's pgfplots figures are the site's figures. Each `tikzpicture` has
  `\tikzsetnextfilename{<name>}`; TikZ `external` (pdflatex `-shell-escape`) writes `report/figures/<name>.pdf`
  (git-ignored, emptied before each build: `external` checks the code, not the data), and `make_report.sh` converts
  each to `docs/public/figures/<name>.svg` (`pdftocairo -svg`, committed). The docs captions repeat the report's.
  Never draw a docs-only figure: add it to the report.

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
- `appelbe_paper.F90` holds **the paper's set-up, inferred from its figures**: `paper_n_ratio = 1e-3`, its speed grid
  (`init_paper`: u in [0, 5], 199 nodes, no node at u_a), the 25 samples of Fig. 2, the Fig. 3 speeds (1, 1/3, 0.2,
  0.05). `appelbe_distributions.F90` holds energy spectra (Gaussian, flat, slowing-down) for footnote 30.
- Drivers `src/app/appelbe_*.F90` write `results/*.dat` (one `#` header line). Figure drivers write the converged
  solution and the same on the paper's grid ("paper's numerics"): `fig1` (+ `fig1_paper`), `fig2` (dense +
  `fig2_samples`: n_a/n_e = 0, 1e-3, paper grid), `fig3` (table nodes vs fits + `fig3_paper_v*` at the legend speeds),
  `fig4`, `fig5` (j, zeta, beta converged, fitted and on the paper grid), `fig6`, `footnote30`, `sec5`
  (`sec5.txt` plus `sec5_{advection,carbon,gradient}.dat`), `validation`, `solvers` (+ `convergence.dat`), `electrons`
  (`electrons_profile.dat`, `electrons_f1.dat`, `electrons_scan_{A,u0,w}.dat`; previews by `scripts/electrons.gp`).
- Report pipeline: `scripts/digitize_paper.py` → `report/data/paper_<fig>_<curve>.dat` and
  `report/data/davies2021_fig4a_EH_beta_new.dat` (committed; derived from the git-ignored PDFs
  `references/appelbe-2019.pdf` and `references/davies-2021.pdf`, the OSTI accepted manuscript of Davies et al., Phys.
  Plasmas 28 (2021), doi:10.1063/5.0023445). `scripts/report_numbers.py` → `report/generated/` (macros, table
  bodies and `fig5_{eh,paper,fit}_*.dat`, git-ignored). `report/appelbe_report.tex` reads `../results/`, `data/` and
  `generated/`, so every number in the PDF comes from the last run. Table bodies are pulled in with `\inputtable` (the `\@@input`
  primitive): LaTeX's robust `\input` breaks a following `\bottomrule`. Number macros use `\ensuremath`.

Kinetic-solver design points that are not obvious from any single file:

- **Normalized units:** u = v/v_Te, each distribution normalized by its own n/v_Te³, time in τ_ei. Every
  `τ_ei Y_ab n_b` becomes a pure number (`k_i`, `k_e`, `k_a`, see the module header). The drive vectors
  are dimensionless via λ = v_Te τ_ei.
- **One solve, three right-hand sides:** `response(ωτ)` solves the E drive, the ∇T drive, and a
  **unit** fast-ion flux (n_α/n_e = 1, γ_α = 1, allowed because the response is linear). It returns σ, μ,
  τ, K in Epperlein–Haines units, plus `j_nu` and `zeta_nu` in Appendix C normalization.
- `kinetic_params%n_ratio` controls **only** the isotropic F₀ inside the operator (Sec. VI). The paper's own
  fast-ion runs used **1e-3** (`paper_n_ratio`; drivers of Figs. 1–5 use it). Sec. V estimates use 0, the n_α ≪ n_e
  limit the paper states.
- **Distributed fast ions** (footnote 30): `op%init(..., distribution=f, shape_params=p)` with `f` of the
  `speed_distribution` interface (pure, explicit parameter array: no host association, so no gfortran trampoline /
  executable stack). F₁ has the shape of F₀; I/J integrals by the grid quadrature; responses are normalised by
  `op%u_flux` = 4π∫u³F du, and `op%u_energy` = sqrt(4π∫u⁴F du) is the mean-energy speed. Converges to the δ result as
  σ². Spectra must be resolved by the grid (logistic edges of 0.1 E₀, not 0.03, at u ≈ 0.25 and 801 nodes).
- **Boundary conditions:** the operator is assembled row by row on the full grid, then reduced. `f(1) = f(2)`
  folds column 1 into column 2 and `f(n) = 0` drops column n.
- **Node alignment at u_a (essential):** `init` stretches u_max by < half a cell so a node sits exactly on
  u_a, and `heaviside` treats |x| ≤ 1e-8 h as the origin (value 1/2). Without alignment the fast-ion moments
  carry an erratic O(h) error stuck at ~3e-3; without the tolerance, rounding makes the step randomly 0/1 at
  the aligned node (2% jumps at v_a/v_Te = 0.6–0.7; regression checks in `test_fast_ions`). With both, the
  moments converge at second order (~2e-4 at 401 nodes). The δ functions of F₀, F₁ are unit-area hats;
  `u_a ≥ 4h` is enforced (0.5h with `align=.false.`), so the `v_a/v_Te = 0.025` table row cannot run on the default grid (`appelbe_fig3` uses
  1001 nodes with u_max = 5 for it, 701 nodes for 0.05; u_max = 5 changes j, ζ by < 1e-8).
- **`init(..., align=.false.)`** keeps the grid as given (no node on u_a): Heaviside steps jump between nodes and the
  moments carry an O(h) error that depends on where u_a sits in its cell. It exists only to emulate the paper
  (`init_paper`); never use it for physics.
- **Coulomb logarithms:** all ratios default to 1 (`lnl_ee_ratio = lnl_ea_ratio = 1`). This **is** the paper's
  choice: the NRL formulary (2019, Richardson) gives λ_ee = λ_ei to ~1e-5 for T_e ≫ e² eV, and λ_eα takes the e–i
  form (v_α < v_Te). An earlier note blaming the ratios for the residual against the tables was wrong.

## Validation status

Measured on 2026-10-23. `fobis rule --ex tests` runs 178 checks (150 then; on 2026-11-20 `test_errors` added 24 and `test_electrons` 4, plus
the expected failure `test_xfail_init_stop`), and all pass in both modes (`gnu-debug` traps FP
overflow: keep distribution code overflow-safe, see `logistic` in `appelbe_distributions`). Also 150/150 with ifx 2026.2
and nvfortran 26.9 (`static-intel`, `static-nvf`; 2026-11-19), after the nvfortran workaround in `solve_paper` (an
explicit `allocate` instead of `b = rhs(2:n-1, :)`, which nvfortran miscompiles there). The full comparison is in
`report/appelbe_report.pdf`; the key results:

- **Conventional coefficients, Z = 1:** α∥ = 0.5061, β∥ = 0.7029, κ∥ = 3.2031, the Epperlein–Haines (1986)
  values (α∥ matches Eq. 42). Lorentz limits exact (3π/32, 3/2, 128/3π). Onsager τ = μ − (3/2)σ holds to
  5e-8 over ωτ = 0–1e3. Converged 401 vs 1601 nodes to 1e-7.
- **The paper's set-up, reconstructed** (each finding tested on several figures; see report Sec. 5):
  - its fast-ion runs keep an isotropic F₀ with **n_α/n_e = 1e-3** in the operator. Evidence: Fig. 2 for p, α, C
    at once (the per-unit-Z shortfall at v=0.1 scales as Z², carbon RMS 0.21 → 0.010), Fig. 3 (5–10× better),
    Fig. 4 (2–3× better); 5e-4 and 2e-3 fit clearly worse;
  - **Fig. 2 is a polyline through 25 temperatures** equally spaced in T_e (v = 1/sqrt(1+99(k−1)/24)); no sample
    between 0.44 and 1. Our α minimum ≈ −1.50 at v ≈ 0.77 falls in that gap, and the "Fig. 2 vs Table I at 0.5"
    disagreement is the chord: our own polyline through the samples gives −1.337 (paper Fig. 2 −1.340), our exact
    value −1.378 (Table I −1.39). **Not an inconsistency of the paper.**
  - **its speed grid: u in [0, 5], 199 nodes (h = 5/198), no node at u_a** (`init_paper`). Found from Fig. 1: its data
    points are spaced 0.0253 (the paper plots at its nodes), and the depth of the f₁⊥ lobe, an O(h) artefact of the
    unaligned grid, pins h to 0.02525–0.0253 (−1.13 at 0.02505, −1.29 at 0.02545; paper −1.224). With nothing else
    adjusted, the same grid removes the residuals elsewhere: Fig. 2 max 0.044 → 0.006 (C), 0.016 → 0.003 (α), the
    alternating ± pattern at v = 0.274/0.329 vanishes; Fig. 3 at v = 1 0.015 → 0.0024 (j); Fig. 5 1 keV q∧ 5.1% → 0.8%.
    (An earlier "effective speed shift" fit was this effect, approximated.) u_max = 10, N = 397 is equivalent;
  - **the speed printed 0.33 is 1/3** (Fig. 3 legend and Table I–IV node): on the paper grid j matches to 5e-4 at 1/3,
    3e-3 at 0.335, 7e-3 at 0.33; Table I ωτ=0 −1.21 vs −1.208 (1/3) / −1.202 (0.33). `v_nodes(3) = 1/3` in the fits;
  - **Fig. 5 used the Epperlein–Haines fitted β** (both components). With E&H 1986 Table III, Z = 1
    (`references/epperlein-haines-1986.pdf`, a scan; coefficients in `scripts/report_numbers.py`: β⊥ form
    (β'₁χ+β'₀)/(χ³+b'₂χ²+b'₁χ+b'₀)^(8/9) = (6.33, 1.05e3; 5.15e2, 4.11e3, 3.71e3), β∧ form
    χ(β''₁χ+β''₀)/(χ³+b''₂χ²+b''₁χ+b''₀) = (1.5, 2.54; 7.09, 3.27, 2.87)), the β inferred from the paper's 15 keV
    q⊥, q∧ (with the paper's closure on its grid) equals the fit in both components to ±0.001 at every ωτ. Our exact β⊥ differs by up to 0.06 for
    0.04 ≲ ωτ ≲ 1 (fit defect: (β⊥(0) − β⊥)/ωτ → 0.690 instead of 0; Sadler 2021, Davies 2021), β∧ by ≤ 0.009. The
    Davies et al. 2021 Fig. 4(a) E&H curve agrees with our transcription to 0.002 (kept as a cross-check).
- **Direct comparison, max deviation in % of each curve's peak** (report Table 16; "paper's numerics" = paper grid +
  n_α/n_e = 1e-3 + E&H β for Fig. 5): **every curve ≤ 1.6%** — Fig. 1 0.26/1.56/0.26, Fig. 4 ≤ 0.46, Fig. 5 0.19/0.83
  (1 keV) and 0.01/0.08 (15 keV), Fig. 6 ≤ 0.04; Figs. 2–3 ≤ 0.006 / 0.015 absolute. Converged (our physics) the large
  ones are Fig. 1 f₁⊥ 18% (paper grid) and Fig. 5 q∧ 18–29% with exact β (paper's E&H β). **No residual is unexplained.**
- **The Appendix C fits miss the paper's own Fig. 3** by up to 0.009 (j) and 0.07 (ζ, at ωτ → 0: the fit's 0.5%
  endpoint error); this, not the solver, is the residual of our kinetic solution against Tables I–IV (incl. the 0.025
  row, solved with 1001 nodes, u_max = 5).
- **Footnote 30** (broad spectra ≈ monoenergetic at the mean energy to 1%): holds for v ≤ 0.5 and spreads up to
  σ_E/Ē = 0.4 or ±60% (≤ 0.7%); fails at v = 1 (4–5%, the j_ν minimum near 0.8) and for the slowing-down
  distribution (up to 4.5% in j, 5.5% in ζ). Grid-converged to 1e-5 at 801 nodes.
- **Fig. 5 was computed kinetically, not from its fits:** at 1 keV its low-ωτ plateau is 6.15e-16, our kinetic value
  6.04e-16, the interpolated fits 6.43e-16.
- **Algebraic closure weak spot:** between the nodes v_α/v_Te = 1 and 0.5 (T_e ≈ 0.5–1.9 keV for 3.45 MeV α); at
  1 keV (v = 0.688) Fig. 5 is missed by 5.8% (q⊥) and 22% (q∧) even with the paper's E&H β. It is the node spacing,
  not the fits: interpolating *exact* kinetic node values gives 5.3%/24%, since j_ν at 0.688 (−1.465 at ωτ → 0) lies
  outside the node values (−1.420, −1.393): its minimum is between the nodes. For FLUME,
  regenerate a denser table with the kinetic solver (at the n_α/n_e actually present, integrating over broad
  spectra) and use exact or Davies/Sadler-corrected β, not the E&H fits.
- **Sec. V** (n_α/n_e = 0, the paper's stated limit):
  - Advection: |u_adv| is (2–3)×10⁴ m/s, and the ⊥ component reverses sign across ωτ ≈ 1. The paper says "up to
    10⁴" (half its own 2(n_α/n_e)⟨v_α⟩ estimate).
  - Scenario C: j⁰_eα = −(3.6–4.8)×10¹⁵ A/m² (the paper's 6×10¹⁵ exceeds the bound Z_α e flux·max|j_ν|),
    and dB/dt·T_keV^{5/2} is (2–3.5)×10¹³ (the paper says 6×10¹³).
  - Scenario B (carbon beam): at 1–2 keV the beam has v_a/v_Te = 2–3, beyond Fig. 2. There
    j⁰_eα/j⁰_α collapses (−0.05 at 1 keV, −1.7 at 2 keV). The paper's blanket "≈ −5" overestimates the
    low-T end, so the kinetic rates are 3×10¹²–6×10¹³ T/s against the paper's 10¹³–10¹⁵.

## Desktop GUI (issue #2)

`appelbe-gui` (src/gui/, FIGURE v0.8.0, `fobos-gui`) is for Luca (a physicist, not a developer): prebuilt binaries for
macOS arm64, Windows and Linux. Rules: the library stays GUI-free (the core fobos/CI never read `fobos-gui`); the GUI
adds no physics (every number from a library call, `appelbe_gui_model`); every shown number is checked by a headless
test against a direct library call (never a snapshot); inputs the library rejects are messages (`stat`/`errmsg`), never
a stop. `gui%frame(app)` is called by the program and by the tests alike. Docs: `docs/guide/gui.md`.
**Threads:** the solves run as FIGURE tasks (`solve_work` over `solve_job` steps). This relies on `src/lib` having no
module variable, `save`, or initialised local (audit table in `docs/guide/gui.md`, "Threads"; `fobos-gui` compiles with
`-frecursive`). Keep it so in every library change; `test_gui_task` checks task = main thread bit for bit.
Exports use the library's headers/writers: for the default inputs (= the driver's reference case) they are byte for
byte the driver's `results/electrons_{profile,f1,scan_*}.dat` (`test_gui_files` compares them when results/ exists).
Help = `docs/guide/gui-user.md` compiled in (one source, `scripts/gui_help.py`); its pictures come from
`--screenshots`. Sessions (`.ses`): `key = value`, ES25.16 reals (bit-exact round trip), a table's rows embedded.
**Packaging** (`gui-release-gnu`, `scripts/package_gui.sh`, `.github/workflows/gui.yml`; release.yml's `gui`,
`gui-assets` attach the archives on a tag): the compiler runtime static; the script refuses a program that loads a
build-machine library and writes the measured minimum OS/glibc into the README. Linux needs glibc 2.38 (built in the
Debian 13 image or on the Ubuntu 24.04 host alike: the newest symbols used are 2.38's). macOS: arm64, deployment target 15.0 (macos-15 runner; GitHub dropped macos-14), ad-hoc signed, unsigned by Apple
(*Open Anyway*). Nothing of the macOS/Windows packaging has run yet as of 2026-11-20 (no CI run without a push).

## Non-Maxwellian electrons (beyond the paper)

The goal: quantify the ECE/TS temperature discrepancy and its effect on transport and on the α closure. TS reads f₀,
while ECE absorption reads f₀′. The physics goals of Luca Senni are not fully pinned down; Stefano assists on the math.

- **API:** `op%init(..., electrons=f, electron_params=p)` with `f` of the `speed_distribution` interface. The distributions
  are `electron_maxwellian` (`[T/T_e]`), `electron_bipolar` (`[A, u_0, w]`, Eq. 21 of the slides, momenta in
  sqrt(m_e T_e), so u_L = sqrt(2) u) and `electron_table` (pack with `electron_table_params(x, f)`, x = u_L from 0;
  spline of ln f, zero slope at 0, linear beyond the end; `read_table` reads two columns).
  - `init`, `read_table` take optional `stat`, `errmsg`: a rejected input (even/small `n_nodes`, u_a under-resolved or off
    the grid, f₀ or F negative or not vanishing at u_max, unreadable table) returns `stat = 1` instead of `error stop`
    (the GUI needs this); `electron_table_check(x, f)` gives the reason `electron_table_params` would stop. Without `stat`
    the drivers stop as before (`test_errors`, `test_xfail_init_stop`).
  - Without `electrons`, the closed Maxwellian forms run as before. f₀′ and f₀″ come from five-point differences with
    step 1e-3, and f₀ is normalised to unit density.
- **Formulation:** general Eqs. (A2), (A5): g₄ = 4πk_e(f₀″/5u⁴ − f₀′/5u⁵), g₅ = 4πk_e f₀′/3u³, g₆ = 4πk_e(u f₀″/5 + 2f₀′/15),
  8πk_e f₀ in g₃, I₀ I₂ J₋₁ by quadrature. Drives: E → −½f₀′; ∇T → −u(3/2 f₀ + ½u f₀′), which assumes a self-similar
  f₀ = n/v_T³ φ(v/v_T). The ∇n and E drives no longer combine, so σ is the pure-E response.
- **The study (`appelbe_electron_study`):** profiles, f₁, the 17 readouts and scan rows of a distorted f₀ against the
  Maxwellian. The driver `appelbe_electrons` and the GUI both call it (one source of the numbers; the driver's output is
  byte-identical to before the move, 2026-11-20).
- **Readouts (`appelbe_eedf`):**
  - `ts_spectrum` gives S(w) = 2π∫_w f₀u du; `ts_temperature(op, w_max)` fits a Gaussian to it (`ts_fit` also gives the
    intercept c: the fit is exp(c − w²/T)).
  - `kinetic_temperature` = (2/3)⟨u²⟩.
  - `slope_temperature` = −2u f₀/f₀′, the ECE readout for an optically thick plasma and a narrow resonance (not a
    forward model). It is degenerate near u = 0, where it tends to 0 whenever f₀′(0) ≠ 0, so the scans report it on
    1 ≤ u_L ≤ 4.
- **Verified** (`test_electrons`, 34 checks):
  - The general path with a Maxwellian converges to the closed forms at third order (2e-6 at 401 nodes).
  - In the Lorentz gas, σ and K ratios equal ∫u⁵f₀ and ∫u⁹f₀ to 1e-6; a Maxwellian at 1.1 T_e gives 1.1^{3/2}.
  - The bipolar f₀ matches its analytic form; tables reproduce the functions they sample.
  - Onsager holds to 1e-7 for the Maxwellian.
- **Results** (3.45 MeV α at 10 keV, n_α/n_e = 1e-3, 801 nodes):
  - Reference case A = 0.1, u₀ = 2, w = 0.25:
    - δf/f 6.70% (6.07% = A e^{-1/2} before renormalisation) and δf′/f′ 20.8%. The slides give 6.1% and 21.3%; their base
      is Maxwell–Jüttner.
    - T_TS +0.70% (w ≤ 2) and +0.08% (w ≤ 3); T_slope 0.894–1.253.
    - σ +0.61%, κ −1.03%, j_ν +0.49%, ζ_ν +0.63% at ωτ = 0.
  - Scans (A ±0.3, u₀ 0.5–4, w 0.1–1):
    - The ECE readout spans 0.62–2.62; TS moves by at most 3%.
    - Against the **equal-energy Maxwellian** (T = T_kin; σ ∝ T^{3/2} otherwise mixes in a temperature shift), σ changes
      by ≤ 1%, κ by up to −6.7% (a genuine shape effect), j_ν by ≤ 2.9% and ζ_ν by ≤ 1.2%. At ωτ = 1, every change is
      below 1.5%.
- **Limits:**
  - A prescribed non-Maxwellian f₀ is not a collisional equilibrium; the source that maintains it is not modelled.
  - Onsager τ = μ − (3/2)σ breaks at first order in A (−1.8% at A = 0.1, w = 0.5). The isotropic α F₀ alone breaks it
    by 1e-4.
  - The model is non-relativistic.
- **Open** (Luca is unavailable): which plasmas, what source/sink sets a steady distorted f₀ (needed for a kinetic l = 0
  solver), the INDACO table format (u_L, f now; possibly relativistic p), whether a feature fixed in absolute energy
  matters for ∇T.

## Reference

`references/appelbe-2019.pdf`, `references/davies-2021.pdf` and `references/epperlein-haines-1986.pdf` are git-ignored (`references/*`) because they are
copyrighted. Never force-add them.

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
   fast ions), which reproduces Epperlein & Haines exactly for Z = 1. For FLUME, do **not** use the E&H *fits* for
   β⊥: their form is wrong at small ωτ ((β⊥(0) − β⊥)/ωτ → 0.690 instead of 0; Sadler 2021, Davies 2021), which is what
   distorts the paper's Fig. 5 q∧. Use the kinetic values (tabulated) or the Davies/Sadler fits.

### Paper errata and quirks

- Sec. V B writes current densities as `A m⁻³` (`j⁰_α = 3.4×10¹⁷`, `j⁰_eα ≈ 6×10¹⁵`). They are `A m⁻²`.
- The same section quotes `j⁰_eα ≈ 6×10¹⁵ A m⁻²` for an α flux of 10³⁴ m⁻² s⁻¹. But `Z_α e n_α⟨v_α⟩` is
  3.2×10¹⁵, and |j⊥ν| ≤ 1.42, so the tables give |j⁰_eα| ≈ (3.2–4.5)×10¹⁵. The paper shows no arithmetic.
  Treat its `6×10¹³ T_keV^{-5/2} T s⁻¹` estimate as order-of-magnitude only; it also implies lnΛ ≈ 4.
- Eqs. (B6)–(B7) print "(G ± Ω) g₇ₓ,ᵧ". The right-hand sides that follow from Eq. (B5) are G g₇ₓ + Ω g₇ᵧ and
  G g₇ᵧ − Ω g₇ₓ (implemented in `solve_paper`).
- Fig. 2 *appears* to contradict Table I at v_α/v_Te = 0.5 (−1.34 against −1.39): it is a polyline through 25
  samples (none between 0.44 and 1), and the chord explains the difference. Not an erratum.
- Undocumented set-up: fast-ion runs with n_α/n_e = 1e-3 in the operator; Fig. 5 with the E&H fitted β; δ-function
  coarse unaligned speed grid (O(h) errors up to 10% in Fig. 1's lobe); "0.33" is 1/3. See Validation status.
- Footnote 30 holds only for moderate spreads at v_α/v_Te ≤ 0.5.
- The "anchors" below are the paper's own estimates. Several are measured high (see Validation status and
  `report/appelbe_report.pdf`), so never use them as benchmarks.

### Order-of-magnitude anchors (sanity checks, not golden values)

- NIF hotspot: α flux ~10³⁴ m⁻² s⁻¹ and T_e 1–10 keV give e–α heat flow 10¹⁹–10²⁰ W m⁻². That is
  comparable to conduction losses, and below the α energy flux (~5×10²¹ W m⁻²).
- B advection with `n_α/n_e ~ 10⁻³` and `⟨v_α⟩ ≤ 10⁷ m s⁻¹` gives `u_adv` up to ~10⁴ m s⁻¹.
- Ion fast ignition, with 200 MeV C⁶⁺, `j⁰_α = 3.4×10¹⁷ A m⁻²`, `j⁰_eα ≈ −5 j⁰_α`, r = 10 μm and
  T_e 1–10 keV, gives `∂B/∂t` of 10¹³–10¹⁵ T s⁻¹ from Eq. (43).
