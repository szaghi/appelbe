---
title: 6. Energy spectra
---

# 6. Energy spectra

The closure is derived for a monoenergetic population. The paper's footnote 30 states that a population with a broad
range of energies behaves, to about 1%, like a monoenergetic one at its mean energy with the same drift velocity. With
appelbe you can check it: `init` accepts any isotropic speed distribution $F(u)$ (with $\mathbf F_1 = \gamma_\alpha F$
of the same shape), and computes the fast-ion moments by quadrature.

<<< @/examples/snippets/tut06_spectra-gaussian.F90{fortran}

- `distribution` is a pure function `f(u, p)` of the `speed_distribution` interface; `shape_params` is its parameter
  array `p`. `energy_gaussian` is a Gaussian energy spectrum centred at the speed `p(1)` with relative width `p(2)`.
- `par%u_a` is then only a reference speed (> 0, aligned with a node).
- `op%u_energy` is the speed of the mean energy, $\sqrt{\langle u^2\rangle}$; `op%u_flux` is $4\pi\int u^3F\,du$, the
  flux moment by which `j_nu`, `zeta_nu` are normalised. Since both are per unit flux, "the same drift velocity" is built
  in: compare `j_nu` of the spectrum with `j_nu` of a monoenergetic population at `u_energy`.

## The slowing-down distribution

The physical spectrum of fusion α particles is $F \propto 1/(u^3 + u_c^3)$ below the birth speed:

<<< @/examples/snippets/tut06_spectra-slowing.F90{fortran}

<<< @/examples/output/tut06.txt{text}

A moderate spread changes $j^\nu$ by less than 1%: the footnote holds. The slowing-down distribution does not behave
like its mean energy (here 4.5% in $\zeta^\nu$), and neither does a broad spectrum near $v_\alpha/v_{Te} = 1$, where $j^\nu$
has its minimum. The full study is in [Energy spectra](/guide/distributions#footnote-30).

::: tip What you learned
Spectra as `distribution` + `shape_params`, `u_energy` and `u_flux`, and the limits of footnote 30. Reference:
[Energy spectra](/guide/distributions). Your own spectrum: [cookbook](../cookbook#your-own-fast-ion-spectrum).
:::

Next: [7. The paper, number by number](./07-paper).
