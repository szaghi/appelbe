---
title: Reproduction status
---

# Reproduction status

Measured on 2026-10-23 with gfortran 16.2 (176 checks since 2026-11-20: `test_errors` adds the rejected inputs, `test_electrons` the study module).
`fobis rule --ex tests` runs them all, passing in `gnu` and `gnu-debug` (bounds, NaN initialisation, FP traps). The full comparison is in `report/appelbe_report.pdf`.

## Verification of the solver

| Quantity | This code | Reference |
|----------|-----------|-----------|
| $\hat\alpha_\parallel$, $Z = 1$ | 0.5061 | 0.5061 (Epperlein–Haines 1986); 0.506 (paper, Eq. 42) |
| $\beta_\parallel$, $Z = 1$ | 0.7029 | 0.7029 (E–H) |
| $\hat\kappa_\parallel$, $Z = 1$ | 3.2031 | 3.2031 (E–H) |
| Lorentz gas $\hat\alpha$, $\beta$, $\hat\kappa$ | $3\pi/32$, $3/2$, $128/3\pi$ | exact |
| Onsager $\tau = \mu - \tfrac32\sigma$ | violated by ≤ $5\times10^{-8}$ | exact |
| Grid convergence, conventional coefficients | $10^{-7}$ at 401 nodes | — |
| Grid convergence, fast-ion moments | second order, $2\times10^{-4}$ at 401 nodes | — |
| General-f₀ path with a Maxwellian | third order, $2\times10^{-6}$ at 401 nodes | closed forms (A8)–(A13) |
| Lorentz gas, non-Maxwellian f₀ | σ, K ratios to $10^{-6}$ | $\int u^5 f_0$, $\int u^9 f_0$ ([Non-Maxwellian electrons](electrons#verification)) |
| Complex vs paper solver | $10^{-9}$ (401 nodes), $10^{-7}$ (1601) | — |

<figure class="ap-figure">
  <img src="/figures/solvers.svg" alt="The paper's solver against the complex formulation" />
  <figcaption>Left: largest relative difference between the two solvers. Right: residuals in the first-order system; the paper's squared-operator route loses accuracy at small ωτ and large N (ωτ = 0, where both solve G f<sub>1</sub> = g<sub>7</sub>, is off the logarithmic axis).</figcaption>
</figure>

## Every curve of the paper

Max deviation over each curve, in percent of its peak (RMS in brackets). **Converged**: our kinetic closure in the
paper's set-up ($n_\alpha/n_e = 10^{-3}$, Epperlein–Haines $\beta$ for Fig. 5). **Paper's numerics**: the same on the
paper's grid. **Algebraic**: the Appendix C closure.

| Figure | Curve | Converged | Paper's numerics | Algebraic |
|--------|-------|-----------|------------------|-----------|
| 1 | $f_1$, ωτ = 0 | 3.63 (0.94) | 0.26 (0.07) | — |
| 1 | $f_{1\perp}$, ωτ = 10 | 18.42 (5.93) | 1.56 (0.53) | — |
| 1 | $f_{1\wedge}$, ωτ = 10 | 3.52 (1.30) | 0.26 (0.08) | — |
| 4 | $j^0_{e\alpha}$ heat flow | 0.32 (0.15) | 0.35 (0.13) | 2.77 (1.25) |
| 4 | $\zeta_{e\alpha}$ heat flow | 0.14 (0.07) | 0.17 (0.07) | 0.78 (0.34) |
| 4 | sum | 0.57 (0.34) | 0.46 (0.34) | 3.13 (1.80) |
| 5 | $q_{e\perp}$, 1 keV | 1.34 (0.91) | 0.19 (0.12) | 5.79 (3.56) |
| 5 | $q_{e\wedge}$, 1 keV | 5.10 (2.39) | 0.83 (0.36) | 22.06 (10.33) |
| 5 | $q_{e\perp}$, 15 keV | 0.09 (0.06) | 0.01 (0.01) | 1.88 (0.69) |
| 5 | $q_{e\wedge}$, 15 keV | 0.28 (0.13) | 0.08 (0.03) | 3.20 (1.15) |
| 6 | six curves | ≤ 0.02 | ≤ 0.04 | — |

| Figure | Converged | Paper's numerics |
|--------|-----------|------------------|
| 2, max \|Δ\| at the 25 samples (p, α, C) | 0.008, 0.016, 0.044 | 0.002, 0.003, 0.006 |
| 3, max \|Δj^ν\|, \|Δζ^ν\| | 0.015, 0.072 | 0.0024, 0.015 |

**With the paper's numerics, no curve deviates by more than 1.6% of its peak, and no residual is left unexplained.**
The larger converged deviations are the paper's discretisation error (Fig. 1, $f_{1\perp}$), and with the exact $\beta$ the
Fig. 5 $q_{e\wedge}$ differs by 18% (15 keV) and 29% (1 keV): the paper's Epperlein–Haines $\beta$. The algebraic closure's
22% at 1 keV is its node spacing ([Algebraic closure](algebraic-closure#limits)), not a discrepancy with the paper,
which computed Fig. 5 kinetically.

### The figures

The same figures as the report ([PDF](https://github.com/szaghi/appelbe/blob/main/report/appelbe_report.pdf)), from the same data.

<figure class="ap-figure">
  <img src="/figures/fig1.svg" alt="Electron f1 driven by fast alpha particles, this work against the paper's Fig. 1" />
  <figcaption>Electron f<sub>1</sub> driven by 3.45 MeV α particles at T<sub>e</sub> = 2 keV (v<sub>α</sub>/v<sub>Te</sub> = 0.486), each curve normalised by its maximum. Solid: this work, converged. Dotted: f<sub>1⊥</sub> on the paper's grid. Circles: the paper's Fig. 1.</figcaption>
</figure>

<figure class="ap-figure">
  <img src="/figures/fig2.svg" alt="Unmagnetised current ratio, this work against the paper's Fig. 2" />
  <figcaption>Unmagnetised current ratio, DT. Solid: this work, paper's set-up (n<sub>α</sub>/n<sub>e</sub> = 10<sup>−3</sup>); dotted: carbon with n<sub>α</sub>/n<sub>e</sub> = 0. Circles: the paper's Fig. 2 (a polyline through 25 samples). Squares: the paper's Table I, ωτ = 0 column, for α particles.</figcaption>
</figure>

<figure class="ap-figure">
  <img src="/figures/fig3.svg" alt="Induced current and heat flow versus the Hall parameter, this work against the paper's Fig. 3" />
  <figcaption>Collisionally induced current (top) and heat flow (bottom) for α particles in DT, at the speeds of the paper's Fig. 3. Lines: this work (kinetic, paper's set-up, converged), solid ⊥, dashed ∧. Markers: the paper's Fig. 3, circles ⊥, triangles ∧.</figcaption>
</figure>

<figure class="ap-figure">
  <img src="/figures/fig4.svg" alt="Unmagnetised heat flow, this work against the paper's Fig. 4" />
  <figcaption>Heat flow induced by electron–α collisions, unmagnetised DT, E<sub>α</sub> = 3.45 MeV. Solid: this work, kinetic closure (paper's set-up). Dashed: this work, algebraic closure (Appendix C). Circles: the paper's Fig. 4.</figcaption>
</figure>

<figure class="ap-figure">
  <img src="/figures/fig5.svg" alt="Magnetised heat flow, this work against the paper's Fig. 5" />
  <figcaption>Heat flow induced by 3.45 MeV α particles moving orthogonally to <b>B</b>, normalised by n<sub>α</sub>⟨v<sub>α</sub>⟩T<sub>e</sub>[keV]. Top: component along the flux; bottom: along <b>b</b>×flux. Solid: the paper's numerics (kinetic closure on its grid, Epperlein–Haines fitted β); dotted: this work, converged kinetic closure with the exact β; dashed: algebraic closure with the fitted β; circles: the paper's Fig. 5.</figcaption>
</figure>

<figure class="ap-figure">
  <img src="/figures/fig6.svg" alt="Coefficients with an isotropic alpha population, this work against the paper's Fig. 6" />
  <figcaption>Thermal diffusion K<sub>∥</sub> (solid) and energy conductivity μ<sub>∥</sub> (dashed) with an isotropic 3.45 MeV α population, normalised by their values without α particles. Markers: the paper's Fig. 6 (circles K<sub>∥</sub>, triangles μ<sub>∥</sub>).</figcaption>
</figure>

## Tables and quoted numbers

- **Tables I–IV**: the kinetic solution differs from the fits by 0.008–0.021 in $j^\nu$ and 0.04–0.10 in $\zeta^\nu$; the
  fits themselves miss the paper's Fig. 3 by up to 0.009 and 0.07. The signs of $j^\nu_\wedge < 0$, $\zeta^\nu_\wedge > 0$ are
  reproduced.
- **Eq. 32**: $j^0_{e\alpha}/j^0_\alpha = -1.023$ (α) and $-5.07$ (C⁶⁺) at $v_\alpha/v_{Te} = 0.1$.
- **Eq. 43 prefactor**: $1.6503\times10^{-9}$ (paper: $1.65\times10^{-9}$).
- **Sec. IV A**: e–α heat flow $8.4\times10^{18}$–$5.6\times10^{19}$ W m⁻² for an α flux of $10^{34}$ m⁻² s⁻¹ at 1.5–10 keV
  (paper: $10^{19}$–$10^{20}$).
- **Sec. VI**: $1 - K_\parallel/K_\parallel^0 = 0.25\%$ at $n_\alpha/n_e = 10^{-3}$ (paper: below 1%).
- **Sec. V**: see [Findings and errata](errata); several of the paper's estimates are too high.
- **Footnote 30**: holds for moderate spreads at $v_\alpha/v_{Te} \le 0.5$ only ([Energy spectra](distributions#footnote-30)).
