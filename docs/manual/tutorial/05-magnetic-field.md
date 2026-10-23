---
title: 5. Magnetic fields
---

# 5. Magnetic fields

Sec. V of the paper estimates what $j^0_{e\alpha}$ does to the magnetic field of an ICF hotspot. The dimensional helpers
of `appelbe_plasma` give the plasma parameters:

<<< @/examples/snippets/tut05_magnetic_field-plasma.F90{fortran}

`coulomb_log_ei_nrl` is the NRL formulary's electron–ion logarithm for $T_e > 10Z^2$ eV; `tau_ei` is Eq. 14 (Braginskii's
$\tau_e$). The normalised closure needs only $v_\alpha/v_{Te}$:

<<< @/examples/snippets/tut05_magnetic_field-closure.F90{fortran}

## Advection

The term $\nabla\times(\mathbf j^0_{e\alpha}\times\mathbf B/en_e)$ advects the field with
$\mathbf u = Z_\alpha(n_\alpha/n_e)\langle v_\alpha\rangle j^\nu$ (Eq. 40):

<<< @/examples/snippets/tut05_magnetic_field-advection.F90{fortran}

## Generation

In an unmagnetised plasma, $\nabla\times[\alpha_\parallel\mathbf j^0_{e\alpha}/(en_e)^2]$ generates field from zero.
For an axial $j^0_{e\alpha}(r)$ (Eq. 43 written with Eq. 41),
$\partial B_\theta/\partial t = [\alpha_\parallel/(en_e)^2]\,[-\partial j/\partial r + \tfrac32(j/T_e)\partial T_e/\partial r]$:

<<< @/examples/snippets/tut05_magnetic_field-generation.F90{fortran}

<<< @/examples/output/tut05.txt{text}

`resistive_coefficient` is $\alpha_\parallel/(en_e)^2$, independent of the density; with
$\hat\alpha_\parallel = 0.506$, $Z_i = 1$, $\ln\Lambda = 1$ and 1 keV it is the $1.65\times10^{-9}$ prefactor of Eq. 43. Here
the current falls to zero over 10 µm and the temperature over 1 keV per µm.

::: tip What you learned
SI estimates of Sec. V from the normalised closure. Reference: [Transport terms](/guide/transport). The paper's own
estimates and where they are too high: [Findings and errata](/guide/errata).
:::

Next: [6. Energy spectra](./06-spectra).
