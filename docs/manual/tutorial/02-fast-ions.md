---
title: 2. A drifting fast-ion population
---

# 2. A drifting fast-ion population

Now add α particles drifting through a DT plasma. The fast-ion population is described by its charge, its mass ratio
and its speed in units of the electron thermal speed, $u_\alpha = v_\alpha/v_{Te}$:

<<< @/examples/snippets/tut02_fast_ions-alpha.F90{fortran}

- A positive `u_a` switches the fast ions on: `response` then solves a third right-hand side, the source $g_7$ of a
  **unit** fast-ion flux (the problem is linear, so the flux factors out).
- `init` stretches $u_{\max}$ by less than half a cell so that a grid node sits exactly on $u_\alpha$: the Heaviside
  steps and the δ functions of the monoenergetic population then fall on a node, and the result converges at second
  order (see [the kinetic solver](/guide/kinetic-solver#node-alignment)).
- `r%j_nu` is $j^0_{e\alpha}/j^0_\alpha = j^0_{e\alpha}/(Z_\alpha e n_\alpha\langle v_\alpha\rangle)$; `r%zeta_nu` is
  $\zeta_{e\alpha}/(n_\alpha\langle v_\alpha\rangle T_e)$ — exactly the normalisation of the paper's Appendix C.

## Speed dependence

<<< @/examples/snippets/tut02_fast_ions-scan.F90{fortran}

## Other species

The kinetic solver is not limited to α particles; only the algebraic fits are. In the low-velocity limit the
current ratio tends to $1 - Z_\alpha/Z_i$ (Eq. 32):

<<< @/examples/snippets/tut02_fast_ions-species.F90{fortran}

<<< @/examples/output/tut02.txt{text}

The induced electron current is opposite to the fast-ion current and larger than it: for α particles in DT the net
current $j^0_{e\alpha}$ is about $-1$ to $-1.5$ times the α current. Its minimum, near $v_\alpha/v_{Te} \approx 0.8$, is
a feature the paper's Fig. 2 misses (it samples no speed between 0.44 and 1, see [the paper's set-up](/guide/paper-setup)).

::: tip What you learned
Fast ions as a third drive, the closure `j_nu`, `zeta_nu` and Eq. 32. Reference: [Kinetic solver](/guide/kinetic-solver),
[The physics](/guide/physics#the-closure). Fast beams beyond the electron thermal speed: [cookbook](../cookbook#a-fast-ion-species-the-fits-do-not-cover).
:::

Next: [3. A magnetised plasma](./03-magnetised).
