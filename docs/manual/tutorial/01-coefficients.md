---
title: 1. Transport coefficients
---

# 1. Transport coefficients

Before any fast ion, the kinetic solver must reproduce the classical transport of a plasma. Three objects do all the
work: `kinetic_params` holds the physics, `kinetic_operator` the discretised collision operator $G$ of Eq. 13, and
`kinetic_response` the result at one Hall parameter.

<<< @/examples/snippets/tut01_conventional-solve.F90{fortran}

- `par%z_i` is the thermal-ion charge; with `par%u_a = 0` (the default) there are no fast ions.
- `op%init` assembles $G$ on a uniform speed grid: 401 nodes on $[0, 7\,v_{Te}]$ by default (`n_nodes`, `u_max`
  change them).
- `op%response(omega_tau)` solves Eq. 13 for the electric-field and temperature-gradient drives and returns the
  transport coefficients. Each response costs about 20 ms on the default grid.

The coefficients come in Epperlein–Haines units and as complex numbers $(\perp, \wedge)$; at $\omega\tau = 0$ they are
real and equal to the parallel values:

<<< @/examples/snippets/tut01_conventional-print.F90{fortran}

`resistivity()` is $1/\sigma$, i.e. $\alpha_\parallel$ in units of $m_e/(n_e e^2\tau_{ei})$ (the paper's Eq. 42 quotes
0.506), `beta()` the thermoelectric coefficient, `kappa()` the thermal conductivity.

## Magnetised coefficients

A scan in $\omega\tau$ gives the perpendicular and cross (Righi–Leduc, Nernst) components:

<<< @/examples/snippets/tut01_conventional-scan.F90{fortran}

<<< @/examples/output/tut01.txt{text}

The parallel values are those of Epperlein and Haines (1986) for $Z = 1$ to the four digits they publish
($\hat\alpha_\parallel = 0.5061$, $\beta_\parallel = 0.7029$, $\hat\kappa_\parallel = 3.2031$). As $\omega\tau$ grows, the
electrons are confined by the field and every perpendicular coefficient falls; the cross components peak near
$\omega\tau \approx 1$.

::: tip What you learned
The three types, a response, and the conventional coefficients at any Hall parameter. Reference:
[Kinetic solver](/guide/kinetic-solver). Other ion charges, up to the Lorentz gas: [cookbook](../cookbook#conventional-coefficients-for-any-ion-charge).
:::

Next: [2. A drifting fast-ion population](./02-fast-ions).
