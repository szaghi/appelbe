---
title: Energy spectra
---

# Energy spectra

The closure of the paper is derived for a monoenergetic fast-ion population (Eqs. 29–30). appelbe also accepts any
isotropic speed distribution $F(u)$, with $\mathbf F_1 = \gamma_\alpha F\,\hat{\mathbf u}_\alpha$ of the same shape.

## A spectrum in the solver

```fortran
call op%init(par=par, n_nodes=801_I4P, distribution=f, shape_params=p)
```

`f` must conform to

```fortran
abstract interface
   pure function speed_distribution(u, p) result(f)
   real(R8P), intent(in) :: u     ! v / v_Te
   real(R8P), intent(in) :: p(:)  ! shape parameters
   real(R8P)             :: f     ! F(u), any normalisation
   endfunction speed_distribution
endinterface
```

- `f` is sampled on the grid and normalised to unit density, $4\pi\int u^2F\,du = 1$; it must vanish well before
  `u_max` (`init` stops otherwise).
- The fast-ion moments $I_0, I_2, J_{-1}$ (of $F_0$) and $I_1, I_3, J_{-2}$ (of $F_1$) are computed by the same composite
  quadrature as the electron–electron integrals; the mass-ratio terms use $4\pi F$ at the node.
- `par%u_a` must be > 0 (it switches the fast ions on) and is aligned with a node: put it on a discontinuity of the
  spectrum, if any (the birth speed of the slowing-down distribution).
- The parameters travel in `p`: write `f` as a module procedure, so no host association (and no gfortran trampoline)
  is needed.

After `init`:

| Component | Value |
|-----------|-------|
| `op%u_flux` | $4\pi\int u^3F\,du = 3\langle v_\alpha\rangle/(\gamma_\alpha v_{Te})$; `j_nu`, `zeta_nu` are normalised by it |
| `op%u_energy` | $\sqrt{4\pi\int u^4F\,du}$, the speed of the mean energy |

For the monoenergetic population both equal `u_a`. A narrow Gaussian converges to the monoenergetic result as
$\sigma^2$ (checked by `test_fast_ions`).

## Provided spectra

`appelbe_distributions`, with $x = (u/u_0)^2 = E/E_0$ and $F \propto (dN/dE)/u$:

| Function | `p` | Spectrum |
|----------|-----|----------|
| `energy_gaussian(u, p)` | `[u_0, sigma/E_0]` | $dN/dE \propto \exp[-(E - E_0)^2/2\sigma^2]$, truncated at $E = 0$ |
| `energy_flat(u, p)` | `[u_0, w, d]` | flat on $[E_0(1 - w), E_0(1 + w)]$ with logistic edges of width $dE_0$ (overflow-safe) |
| `slowing_down(u, p)` | `[u_b, u_c]` | $F \propto 1/(u^3 + u_c^3)$ below the birth speed $u_b$, 1/2 of it at $u_b$, 0 above |

The classical critical speed in DT is $u_c^3 = \tfrac34\sqrt\pi\,m_e/m_{DT}$. A spectrum must be resolved by the grid: the
flat spectrum with $d = 0.03$ at $u_0 = 0.25$ is narrower than a cell of the 801-node grid; $d = 0.1$ converges to
$10^{-7}$.

## Footnote 30

The paper states (footnote 30, no data) that a population with a broad range of energies behaves to about 1% like a
monoenergetic one at the mean energy and the same drift velocity. `appelbe_footnote30` tests it for α particles in DT,
largest relative difference over $\omega\tau = 0, 1, 10$:

| Spectrum | $v/v_{Te} = 0.25$ | 0.5 | 1 |
|----------|------------------|-----|---|
| Gaussian, $\sigma_E/\bar E = 0.2$ | 0.17% | 0.15% | 1.3% |
| Gaussian, $\sigma_E/\bar E = 0.4$ | 0.68% | 0.58% | 4.9% |
| flat, ±30% | 0.26% | 0.24% | 2.1% |
| flat, ±60% | 0.67% | 0.57% | 5.0% |
| slowing-down (born at the centre speed) | 1.6% | 4.6% | 5.5% |

The claim holds for moderate spreads at $v_\alpha/v_{Te} \le 0.5$. It fails at $v_\alpha/v_{Te} = 1$, where $j^\nu$ has its
minimum (averaging over the spectrum and evaluating at the mean do not commute), and for the slowing-down distribution,
whose mean energy is far below the birth energy. A fluid code with self-consistent α distributions should integrate
the closure over the spectrum.
