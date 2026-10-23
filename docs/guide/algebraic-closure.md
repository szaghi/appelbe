---
title: Algebraic closure
---

# Algebraic closure

`appelbe_fits` is the paper's **simple-algebraic closure** (Appendix C): rational fits of $j^\nu$ and $\zeta^\nu$ in
$x = \log_{10}\omega\tau$, tabulated at six values of $v_\alpha/v_{Te}$, for **α particles in DT only** ($Z_\alpha = 2$,
$Z_i = 1$).

$$
j^\nu_\perp = \frac{p_1x^3 + p_2x^2 + p_3x + p_4}{x^4 + q_1x^3 + q_2x^2 + q_3x + q_4}, \qquad
j^\nu_\wedge = \frac{r_1x^2 + r_2x + r_3}{x^4 + s_1x^3 + s_2x^2 + s_3x + s_4}
\tag{C5, C6}
$$

and the same forms, with primed coefficients, for $\zeta^\nu_\perp$, $\zeta^\nu_\wedge$ (C7, C8). The coefficients are
transcribed verbatim in the module (Tables I–IV).

## Procedures

```fortran
call fit_response(v_ratio, omega_tau, j_nu, zeta_nu)
```

The closure at any $v_\alpha/v_{Te}$ and $\omega\tau \ge 0$, as complex numbers $(\perp, \wedge)$, normalised as the kinetic
`j_nu`, `zeta_nu`. Two choices the paper leaves open:

- **$\omega\tau$ range**: $x$ is clamped to the fitted range $[-3, 3]$. This is continuous, and $\omega\tau = 0$ maps to $x =
  -3$, within 0.8% of the tabulated $\omega\tau = 0$ column (the worst row is 0.025, $j_\perp$, 0.71%).
- **Speed**: between the six nodes the fitted *values* are interpolated linearly in $\log(v_\alpha/v_{Te})$; outside
  $[0.025, 1]$ the nearest node is used.

```fortran
call fit_node_response(k, x, j_nu, zeta_nu)      ! row k (1..6) of the tables, at x = log10(omega tau), not clamped
call fit_zero_column(k, j_perp0, zeta_perp0)     ! the tabulated omega tau = 0 values of row k
```

`v_nodes(1:6) = [1, 0.5, 1/3, 0.25, 0.1, 0.025]`, `n_nodes = 6`. The node printed as 0.33 is $1/3$: the paper's kinetic
data match $1/3$ and not 0.33 ([the paper's set-up](paper-setup#the-speed-printed-0-33-is-1-3)).

## Accuracy

| Check | Result |
|-------|--------|
| Fit at $x = -3$ against the $\omega\tau = 0$ column | within 0.8% for all 24 rows |
| $x = +3$ | $j_\perp^\nu \to 1$ (0.991–0.996), the other three $\to 0$ |
| Fits against the paper's own Fig. 3 (the data they fit) | up to 0.009 in $j^\nu$, 0.07 in $\zeta^\nu$ |
| Kinetic solution (paper's set-up) against the fits | 0.008–0.021 in $j^\nu$, 0.04–0.10 in $\zeta^\nu$ ([status](validation)) |

The residual of the kinetic solution against the fits is the fits' own error: the kinetic solution reproduces the
paper's Fig. 3 to $10^{-3}$.

## Limits

The six nodes are far apart where it matters most. Between $v_\alpha/v_{Te} = 1$ and 0.5 ($T_e \approx 0.5$–1.9 keV for
3.45 MeV α particles), $j^\nu$ has a minimum, near $v_\alpha/v_{Te} \approx 0.8$. No interpolation between the two nodes
can follow it: at $T_e = 1$ keV ($v_\alpha/v_{Te} = 0.688$) the kinetic $j^\nu(\omega\tau \to 0) = -1.465$ lies outside the
node values $-1.420$ and $-1.393$. The heat flow of Fig. 5 at 1 keV is then off by 6% in $q_\perp$ and 22% in $q_\wedge$ —
and interpolating *exact* kinetic node values gives the same error, so the fits are not to blame.

For a fluid code (FLUME), regenerate a denser table with the kinetic solver
([cookbook](/manual/cookbook#a-dense-closure-table-for-an-mhd-code)). For other species, use the kinetic solver; the
only algebraic information is Eq. 32, $j^0_{e\alpha}/j^0_\alpha \to 1 - Z_\alpha/Z_i$ at low speed.
