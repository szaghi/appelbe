---
title: Kinetic solver
---

# Kinetic solver

`appelbe_kinetic` solves the steady electron $f_1$ equation (Eq. 13) discretised as in the paper's Appendix B, and
returns the conventional transport coefficients and the fast-ion closure.

## Physical parameters

```fortran
type :: kinetic_params
   real(R8P) :: z_i          = 1._R8P   ! thermal-ion charge state
   real(R8P) :: z_a          = 2._R8P   ! fast-ion charge state
   real(R8P) :: mass_ratio   = 0._R8P   ! m_e / m_a
   real(R8P) :: u_a          = 0._R8P   ! fast-ion speed v_a/v_Te (aligned with a node); 0 disables the fast ions
   real(R8P) :: n_ratio      = 0._R8P   ! n_a/n_e of the isotropic F0 kept in the operator (Sec. VI)
   real(R8P) :: lnl_ee_ratio = 1._R8P   ! lnL_ee / lnL_ei
   real(R8P) :: lnl_ea_ratio = 1._R8P   ! lnL_ea / lnL_ei
endtype kinetic_params
```

- `u_a > 0` switches the fast-ion drive on. With the default monoenergetic population it is the fast-ion speed;
  with a spectrum it is only a reference speed.
- `n_ratio` controls **only** the isotropic $F_0$ inside the operator (the friction of the fast ions on $f_1$, Sec. VI).
  The closure itself is computed for a unit flux whatever `n_ratio` is. The $n_\alpha \ll n_e$ limit is
  `n_ratio = 0`; the paper used $10^{-3}$ ([the paper's set-up](paper-setup)).
- The Coulomb-logarithm ratios default to 1. That is also what the NRL formulary gives: for $T_e \gg e^2$ eV its
  $\lambda_{ee}$ and $\lambda_{ei}$ coincide to $10^{-5}$, and $\lambda_{e\alpha}$ takes the electron–ion form for
  $v_\alpha < v_{Te}$.
- The convention $n_e = Z_i n_i$ is used for the collision strengths, as in the paper.

## The operator

```fortran
call op%init(par, n_nodes, u_max, distribution, shape_params, align)
```

| Argument | Default | Meaning |
|----------|---------|---------|
| `par` | — | `kinetic_params` |
| `n_nodes` | 401 | odd number of speed nodes |
| `u_max` | 7 | grid extent in $v_{Te}$ (stretched by < half a cell to put a node on `u_a`) |
| `distribution`, `shape_params` | monoenergetic | a fast-ion speed distribution and its parameters ([Energy spectra](distributions)) |
| `align` | `.true.` | node alignment with `u_a`; `.false.` emulates the paper's discretisation |

`init` assembles the reduced operator $G$, $(N-2)\times(N-2)$, row by row: five-point centred differences
(three-point next to the boundaries), Simpson weights for the integral terms, and the boundary conditions
$f_1(u_1) = f_1(u_2)$ (column 1 folded into column 2) and $f_1(u_N) = 0$ (column $N$ dropped). After `init`,
`op%grid%u(:)` holds the nodes, `op%u_flux` the flux moment and `op%u_energy` the mean-energy speed of the fast ions.

### Node alignment

The monoenergetic population puts Heaviside steps and δ functions at $u_\alpha$. Unless a node sits exactly there, the
fast-ion moments carry an $O(h)$ error that depends on where $u_\alpha$ falls in its cell and does not converge.
`init` therefore stretches $u_{\max}$ so that $u_\alpha$ is a node, and the Heaviside steps take the value 1/2 within
$10^{-8}h$ of it (without this tolerance, rounding makes the step randomly 0 or 1 at the node). The δ functions are
unit-area hats on the two nodes around $u_\alpha$, and $u_\alpha \ge 4h$ is enforced. With alignment the moments converge
at second order ([cookbook](/manual/cookbook#check-grid-convergence)).

`align=.false.` keeps the grid as given. It exists only to reproduce the paper's own discretisation error
([the paper's set-up](paper-setup#the-speed-grid)); never use it for physics.

## The response

```fortran
r = op%response(omega_tau, method)
```

solves three drives at once — the electric field, the temperature gradient and (if `u_a > 0`) a unit fast-ion flux —
and returns a `kinetic_response`. Every field is complex, $(\perp, \wedge) = (\text{real}, \text{imaginary})$:

| Component | Meaning | Units |
|-----------|---------|-------|
| `sigma` | electric conductivity σ (Eq. 18) | $n_e e^2\tau_{ei}/m_e$ |
| `mu` | energy conductivity μ (Eq. 19) | $n_e e T_e\tau_{ei}/m_e$ |
| `tau` | thermoelectric coefficient τ (Eq. 18) | $n_e e\tau_{ei}/m_e$ |
| `thermal_diffusion` | thermal diffusion K (Eq. 19) | $n_e T_e\tau_{ei}/m_e$ |
| `j_nu` | $j^0_{e\alpha}/(Z_\alpha e n_\alpha\langle v_\alpha\rangle)$ (Eqs. C1–C2) | — |
| `zeta_nu` | $\zeta_{e\alpha}/(n_\alpha\langle v_\alpha\rangle T_e)$ (Eqs. C3–C4) | — |

| Method | Returns |
|--------|---------|
| `r%beta()` | thermoelectric tensor $\beta = (e/T_e)\mu\sigma^{-1} - 5/2$ (Eq. 26), dimensionless |
| `r%kappa()` | thermal conductivity $\kappa = K - \mu\sigma^{-1}\mu/T_e + \tfrac{3}{2e}\mu$ (Eq. 25), in $n_e T_e\tau_{ei}/m_e$ |
| `r%resistivity()` | $1/\sigma$ in $m_e/(n_e e^2\tau_{ei})$; at $\omega\tau = 0$ it is $\hat\alpha_\parallel$ of Eq. 42 |

The Onsager relation $\tau = \mu - \tfrac32\sigma$ holds to $5\times10^{-8}$ over $\omega\tau \in [0, 10^3]$.

## Solution methods

| Constant | System | Notes |
|----------|--------|-------|
| `method_complex` (default) | $(G + i\omega\tau) f_1 = g_7$, one complex solve | condition number of $G$ |
| `method_paper` | $(GG + \Omega^2) f_{1x} = G g_{7x}$, $(GG + \Omega^2) f_{1y} = -\Omega g_{7x}$; $G f_1 = g_7$ at $\omega\tau = 0$ | Appendix B, $GG$ by matrix product; squared condition number, real arithmetic |

They are algebraically identical, since $(G + i\omega\tau)^{-1} = (G - i\omega\tau)(GG + \omega^2\tau^2)^{-1}$, and agree to
$10^{-9}$ at 401 nodes ($10^{-7}$ at 1601). The paper's residual in the first-order system is up to $10^4$ times larger,
but it is about twice as fast. The paper prints the right-hand sides of Eqs. B6–B7 as "$(G \pm \Omega)g_{7x,y}$", which
drops the cross-component coupling; the implemented form follows from Eq. B5.

## Lower-level access

| Procedure | Returns |
|-----------|---------|
| `op%source_electric()` | $g_7$ for a unit electric drive, $u f_0$, on the full grid |
| `op%source_thermal()` | $g_7$ for a unit temperature-gradient drive, $u f_0 (u^2 - 3/2)$ |
| `op%source_fast_flux()` | $g_7$ of a unit fast-ion population ($n_\alpha/n_e = 1$, $\gamma_\alpha = 1$) |
| `op%solve(omega_tau, rhs)` | $f_1$ on the full grid, one column per column of `rhs(n, ncol)` (complex method) |
| `op%solve_paper(omega_tau, rhs)` | the same with the paper's method |
| `op%residual(omega_tau, rhs, f1)` | relative residual $\|(G + i\omega\tau)f_1 - g_7\|/\|g_7\|$ per column |
| `op%moment(f1, p)` | $\int_0^{u_{\max}} u^p f_1\,du$ (Simpson) |
| `op%fast_integrals(j)` | $[I_0, I_2, J_{-1}]$ of $F_0$ and $[I_1, I_3, J_{-2}]$ of $F_1$ at node `j` (Eqs. A3–A7) |

The moments give the closure: $\sigma = -\tfrac{8\pi}{3}M_3$ and $\mu = -\tfrac{8\pi}{3}M_5$ for the electric drive,
$j^\nu = 1 - 4\pi M_3/(Z_\alpha u_{\text{flux}})$ and $\zeta^\nu = 4\pi M_5/u_{\text{flux}}$ for the fast-ion drive.

## Normalisation

$u = v/v_{Te}$; each distribution is normalised by $n/v_{Te}^3$ of its own species; time is in $\tau_{ei}$. Then
$\tau_{ei}Y_{ei}n_i/v_{Te}^3 = 3\sqrt\pi/4$, $\tau_{ei}Y_{ee}n_e/v_{Te}^3 = (3\sqrt\pi/4)(\ln\Lambda_{ee}/\ln\Lambda_{ei})/Z_i$ and
$\tau_{ei}Y_{e\alpha}n_\alpha/v_{Te}^3 = (3\sqrt\pi/4)(Z_\alpha^2/Z_i)(n_\alpha/n_e)(\ln\Lambda_{e\alpha}/\ln\Lambda_{ei})$, and the
drives are made dimensionless by the mean free path $\lambda = v_{Te}\tau_{ei}$.

## Cost

Dense matrices and Gaussian elimination: a response (three right-hand sides) costs $O(N^3)$, about 20 ms at 401 nodes,
0.15 s at 801 and 1 s at 1601 on a laptop.
