---
title: 4. The heat flow
---

# 4. The heat flow

The electron heat flow driven by the fast ions has two parts (Eq. 24 with $\mathbf j_T = 0$): the heat carried by the
collisionally induced current, $(T_e/e)(\beta + 5/2)\cdot\mathbf j^0_{e\alpha}$, and the heat flow generated directly by
the collisions, $\zeta_{e\alpha}$. Take 3.45 MeV α particles at $T_e = 15$ keV:

<<< @/examples/snippets/tut04_heat_flow-setup.F90{fortran}

`speed_ratio(E, m, T_e)` is $v_\alpha/v_{Te} = \sqrt{E m_e/(T_e m_\alpha)}$; energies and temperatures are in joules
(`MeV_J`, `keV_J` convert).

## Kinetic and algebraic closures

`fit_response` evaluates the paper's Appendix C fits, interpolated between their six tabulated speeds.
`heat_flow_thermoelectric` and `heat_flow_direct` form the two parts of Eqs. 34–35 as complex numbers, per unit
fast-ion flux:

<<< @/examples/snippets/tut04_heat_flow-flow.F90{fortran}

<<< @/examples/output/tut04.txt{text}

These are the curves of the paper's Fig. 5 at 15 keV (divided by $T_{\text{keV}}$, as in the figure). The heat flow along
the flux **grows** with magnetisation, because the fast-ion current is not magnetised; the orthogonal one has a
minimum near $\omega\tau \approx 1$. At 15 keV ($v_\alpha/v_{Te} = 0.18$, between the table nodes 0.25 and 0.1) the
algebraic closure follows the kinetic one closely; between the nodes 1 and 0.5 it does not
([Algebraic closure](/guide/algebraic-closure#limits)).

::: warning The thermoelectric tensor matters
$q_{e\wedge}$ is a small difference of large terms, so it is sensitive to $\beta$. The paper's Fig. 5 used the
Epperlein–Haines *fitted* $\beta$, whose $\beta_\perp$ is wrong at small $\omega\tau$; with the exact $\beta$, as here, its
$q_{e\wedge}$ differs by up to 18–29% ([the paper's set-up](/guide/paper-setup#epperlein-haines-fitted-beta)).
:::

::: tip What you learned
Eqs. 33–35 in complex form, the kinetic and the algebraic closure. Reference: [Transport terms](/guide/transport),
[Algebraic closure](/guide/algebraic-closure). From $j^\nu$ to SI fields: [cookbook](../cookbook#from-the-closure-to-si-fields).
:::

Next: [5. Magnetic fields](./05-magnetic-field).
