---
title: "The paper's set-up"
---

# The paper's set-up

The paper states its model but not several choices behind its figures. Comparing every curve point by point
determines them; `appelbe_paper` collects them, so that a computation can be repeated **the way the paper made it**.
Each finding is tested on several figures at once, so that none rests on a single fitted number.

```fortran
use appelbe
par%n_ratio = paper_n_ratio        ! 1e-3
call init_paper(op, par)           ! 199 nodes on [0, 5], no node on u_a
```

| Entity | Value |
|--------|-------|
| `paper_n_ratio` | $10^{-3}$, the isotropic α density kept in the operator |
| `paper_n_nodes`, `paper_u_max`, `init_paper(op, par)` | the paper's grid: 199 nodes on $[0, 5]$, `align=.false.` |
| `paper_fig2_samples`, `paper_fig2_speed(k)` | the 25 samples of Fig. 2, $v_\alpha/v_{Te} = 1/\sqrt{1 + 99(k-1)/24}$ |
| `paper_fig3_speeds` | the legend of Fig. 3: $1, 1/3, 0.2, 0.05$ |

::: warning For comparison only
The converged solution (default grid, node on $u_\alpha$, $n_\alpha/n_e$ of your problem) is the physical one. The paper's
numerics carry its discretisation error; use them to compare with the paper, never for physics.
:::

## n_α/n_e = 10⁻³ in the operator

The paper's Sec. III assumes $n_\alpha \ll n_e$, i.e. no fast-ion $F_0$ in the collision operator. In that limit the
response is linear in $Z_\alpha$: $1 - j^0_{e\alpha}/j^0_\alpha$ per unit $Z_\alpha$ is the same for every species
(1.011–1.012 at $v_\alpha/v_{Te} = 0.1$). The paper's Fig. 2 gives 1.0105, 1.0077 and 0.9771 for protons, α particles and
carbon: a shortfall growing as $Z_\alpha^2$, the signature of $F_0$ friction ($\propto Z_\alpha^2 n_\alpha/n_e$). With
$n_\alpha/n_e = 10^{-3}$ — the hotspot value the paper itself quotes in Sec. V A — all three species match at once:

| Fig. 2, RMS deviation at the samples | proton | α | C⁶⁺ |
|---|---|---|---|
| $n_\alpha/n_e = 0$ | 0.0022 | 0.0085 | 0.206 |
| $n_\alpha/n_e = 10^{-3}$ | 0.0021 | 0.0038 | 0.010 |
| $10^{-3}$, paper's grid | 0.0007 | 0.0007 | 0.0014 |

On the paper's grid the value is sharp: the carbon RMS is 0.04 at $0.8\times10^{-3}$ and at $1.2\times10^{-3}$. The same
setting improves Fig. 3 five- to tenfold and Fig. 4 two- to threefold.

## Fig. 2 is a polyline of 25 samples

The curves of Fig. 2 are polylines whose vertices lie at $v_\alpha/v_{Te} = 1/\sqrt{1 + 99(k-1)/24}$: 25 temperatures
equally spaced in $T_e$. Between the last two samples, 0.44 and 1, the plotted curve is a straight line. So the figure
misses the minimum of the α curve ($-1.50$ at $v_\alpha/v_{Te} \approx 0.77$), and its value at 0.5 ($-1.340$) only seems
to contradict Table I ($-1.39$): a straight line through our values at the same samples gives $-1.339$, and our exact
value is $-1.378$. The paper is consistent; its plot is coarse.

## The speed grid

The data points of Fig. 1 are equally spaced, by $\Delta u = 0.0253$: the paper plots its solution at its nodes. On so
coarse a grid, without a node at $u_\alpha$, the Heaviside steps of the fast-ion source jump between nodes, and the
solution carries an $O(h)$ error that depends on where $u_\alpha$ falls in its cell. Running our operator without
alignment, the depth of the negative lobe of $f_{1\perp}$ in Fig. 1 is a steep function of $h$:

| $h$ | 0.02505 | 0.02520 | 0.02525 | 0.02530 | 0.02545 | paper |
|---|---|---|---|---|---|---|
| lobe of $f_{1\perp}$ | −1.13 | −1.19 | −1.21 | −1.23 | −1.29 | −1.224 |

$h = 5/198$ (199 nodes on $[0, 5]$; 397 on $[0, 10]$ is equivalent). With nothing else adjusted, this grid predicts the
residuals of every other figure:

| | converged | paper's grid |
|---|---|---|
| Fig. 1, $f_{1\perp}$, max deviation | 18% | 1.6% |
| Fig. 2, carbon at $v_\alpha/v_{Te} = 1$ | 0.044 | 0.006 |
| Fig. 2, carbon at 0.329 / 0.274 (alternating sign) | −0.025 / +0.010 | 0.000 / −0.000 |
| Fig. 3, $j^\nu$ at $v_\alpha/v_{Te} = 1$ | 0.015 | 0.0024 |
| Fig. 5 at 1 keV, $q_{e\wedge}$ | 5.1% | 0.8% |

The paper's results thus carry its discretisation error: up to 10% in the lobe of $f_{1\perp}$, 0.04 in
$j^0_{e\alpha}/j^0_\alpha$ for carbon. The lobe weighs little in the moments, which is why the closure is far less affected.

## The speed printed 0.33 is 1/3

On the paper's grid a change of $v_\alpha/v_{Te}$ by 0.003 moves $u_\alpha$ by a tenth of a cell, which is visible. The curve
labelled 0.33 in Fig. 3 is matched to $5\times10^{-4}$ in $j^\nu$ at $1/3$, against $3\times10^{-3}$ at 0.335 and
$7\times10^{-3}$ at 0.33; the $\omega\tau = 0$ column of Table I ($-1.21$) is closer at $1/3$ ($-1.208$) than at 0.33
($-1.202$). appelbe uses $1/3$ for the figure and the table node.

## Epperlein–Haines fitted β

At 15 keV the paper's closure is known (our kinetic solution on its grid), so its Fig. 5 determines the thermoelectric
tensor it was computed with: $q_e/(n_\alpha\langle v_\alpha\rangle T_e) = Z_\alpha(\beta + \tfrac52)j^\nu + \zeta^\nu$ gives one complex
$\beta$ per $\omega\tau$. It equals, in both components and to 0.001, the fits of Epperlein and Haines (1986), Table III,
$Z = 1$:

$$
\beta_\perp^c = \frac{6.33\chi + 1.05\times10^3}{(\chi^3 + 5.15\times10^2\chi^2 + 4.11\times10^3\chi + 3.71\times10^3)^{8/9}}, \qquad
\beta_\wedge^c = \frac{\chi(1.5\chi + 2.54)}{\chi^3 + 7.09\chi^2 + 3.27\chi + 2.87},
$$

$\chi = \omega\tau$. The exact $\beta_\perp$ differs from the fit by up to 0.06 for $0.04 \lesssim \omega\tau \lesssim 1$: the fitting
form tends to $(\beta_\perp(0) - \beta_\perp)/\omega\tau \to 0.690$ at $\omega\tau \to 0$ instead of 0, a known defect
(Sadler et al., PRL 126, 075001, 2021; Davies et al., Phys. Plasmas 28, 2021). Because $q_{e\wedge}$ is a small difference
of large terms, this is what puts the paper's $q_{e\wedge}$ 18–29% away from the exact one. The fits are evaluated in
`scripts/report_numbers.py` (the solver gives the exact tensor); the Epperlein–Haines curve of Davies et al., Fig. 4(a),
extracted from their manuscript, agrees with the transcription to 0.002.

## Coulomb logarithms

Appendix C takes the Coulomb logarithms from the NRL formulary. For $T_e > 10Z^2$ eV it gives
$\lambda_{ee} = 23.5 - \ln(n_e^{1/2}T_e^{-5/4}) - [10^{-5} + (\ln T_e - 2)^2/16]^{1/2}$ and
$\lambda_{ei} = 24 - \ln(n_e^{1/2}T_e^{-1})$; for $T_e \gg e^2$ eV the square root is $(\ln T_e - 2)/4$ and the two coincide
(difference $4\times10^{-6}$ at 1–10 keV). The ratios are 1, as in the solver; they explain no residual.
