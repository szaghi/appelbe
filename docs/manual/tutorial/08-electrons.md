---
title: 8. Non-Maxwellian electrons
---

# 8. Non-Maxwellian electrons

Everything so far kept the electron $f_0$ Maxwellian, as the paper does. `init` also accepts any isotropic $f_0$ as a
function `f(u, p)`. This chapter distorts the electrons with the bipolar perturbation of Senni et al. (ICFDT 2026),
then looks at what Thomson scattering and ECE would read and at what the distortion does to transport.

<<< @/examples/snippets/tut08_electrons-bipolar.F90{fortran}

- `electrons` and `electron_params` play the roles that `distribution` and `shape_params` play for the fast ions.
- `electron_bipolar` is $f_M\,[1 + A\,x\,e^{-x^2/2}]$ with $x = (u_L - u_0)/w$ and parameters `[A, u_0, w]`. Momenta are
  in units of $\sqrt{m_eT_e}$, as in the slides; that is $u_L = \sqrt2\,u$.
- The default (no `electrons` argument) is the Maxwellian with closed forms; `maxw` uses it.

## What the diagnostics read

<<< @/examples/snippets/tut08_electrons-readouts.F90{fortran}

`ts_temperature` fits a Gaussian to the projected spectrum $S(w)$ on $w \le w_{\max}$. `kinetic_temperature` is the
energy moment. `slope_temperature` is $-2uf_0/f_0'$ on the grid: what an optically thick ECE channel resonant at speed
$u$ would report. It is restricted here to $1 \le u_L \le 4$, because near $u = 0$ it is degenerate.

## What it does to transport

<<< @/examples/snippets/tut08_electrons-transport.F90{fortran}

<<< @/examples/output/tut08.txt{text}

The distortion moves the ECE readout by −11% to +25%, the TS readout by under 1%, and the coefficients and the α closure
by about 1%. Onsager's relation, exact for a Maxwellian, is broken: a distorted $f_0$ is not the collisional
equilibrium.

::: tip What you learned
`electrons` + `electron_params`, the TS and ECE readouts of `appelbe_eedf`, and the size of the transport effect.
Reference, with the scans and the assumptions: [Non-Maxwellian electrons](/guide/electrons). A tabulated $f_0$:
[cookbook](../cookbook#an-electron-f0-from-a-table).
:::

That is the tutorial. For tasks, see the [cookbook](../cookbook).
