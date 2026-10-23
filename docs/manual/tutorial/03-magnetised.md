---
title: 3. A magnetised plasma
---

# 3. A magnetised plasma

With a magnetic field $\mathbf b$ orthogonal to the fast-ion flux, the induced current and heat flow have a component
along the flux ($\perp$) and one along $\mathbf b\times$flux ($\wedge$). appelbe returns both as one complex number,
$(\perp, \wedge) = (\text{real}, \text{imaginary})$:

<<< @/examples/snippets/tut03_magnetised-scan.F90{fortran}

The real part of $j^\nu$ goes from about $-1.4$ (unmagnetised: the electron current dominates) to $+1$ (strongly
magnetised: the electrons are confined, only the unmagnetised fast-ion current remains). The imaginary part, the
current orthogonal to both the flux and the field, peaks near $\omega\tau \approx 1$ and is **negative**: since the
solver is built on the tensor convention of Eq. 27, this pins the handedness that the paper does not state.

## Why complex numbers

With $\mathbf b = \hat z$ and $f_1 = f_{1x} + i f_{1y}$, the term $\omega\tau\,\mathbf b\times\mathbf f_1$ is
$i\,\omega\tau f_1$, and the two coupled real equations of the paper become one complex system,
$(G + i\omega\tau)f_1 = g_7$. Tensor algebra becomes complex arithmetic: $\beta = \mu/\sigma - 5/2$ is a complex
division, and the heat flows of Eqs. 34–35 are a single complex product (next chapter).

## The paper's solver

The paper solves instead $(GG + \Omega^2) f_{1x} = G g_{7x}$, $(GG + \Omega^2) f_{1y} = -\Omega g_{7x}$ (Appendix B, with
the right-hand sides corrected, see [Findings and errata](/guide/errata)). Both are available:

<<< @/examples/snippets/tut03_magnetised-methods.F90{fortran}

<<< @/examples/output/tut03.txt{text}

They agree to rounding. The paper's route squares the condition number of $G$ (its residual is up to $10^4$ times
larger at small $\omega\tau$ and large $N$) but works in real arithmetic and is about twice as fast.

::: tip What you learned
The $(\perp, \wedge)$ convention, its sign, and the two solvers. Reference: [Kinetic solver](/guide/kinetic-solver#solution-methods),
[The physics](/guide/physics#the-tensor-convention-and-complex-numbers). Any orientation of the flux to $\mathbf B$:
[cookbook](../cookbook#any-orientation-of-the-flux-to-the-field).
:::

Next: [4. The heat flow](./04-heat-flow).
