---
title: Transport terms
---

# Transport terms

`appelbe_closure` turns a closure $(j^\nu, \zeta^\nu)$ into the heat flows and magnetic-field terms of Secs. IV–V;
`appelbe_plasma` gives the dimensional plasma quantities. All functions are `elemental`.

## Heat flow

$$
\frac{q_e}{n_\alpha\langle v_\alpha\rangle} = \underbrace{T_e Z_\alpha(\beta + \tfrac52)\,j^\nu}_{\texttt{heat\_flow\_thermoelectric}}
 + \underbrace{T_e\,\zeta^\nu}_{\texttt{heat\_flow\_direct}}
\tag{33–35}
$$

```fortran
q_j = heat_flow_thermoelectric(te, z_a, beta, j_nu)   ! (T_e/e)(beta + 5/2) j0_ea per unit flux [W s]
q_z = heat_flow_direct(te, zeta_nu)                   ! zeta_ea per unit flux [W s]
```

`te` in joules, `beta`, `j_nu`, `zeta_nu` complex: the complex product reproduces Eqs. 34–35,
$q_\perp = (T_e/e)[(\beta_\perp + \tfrac52)(j^0)_\perp - \beta_\wedge(j^0)_\wedge] + \zeta_\perp$ and
$q_\wedge = (T_e/e)[\beta_\wedge(j^0)_\perp + (\beta_\perp + \tfrac52)(j^0)_\wedge] + \zeta_\wedge$. Unmagnetised, only the real
parts survive (Eq. 33). The paper's Fig. 5 divides by $T_{\text{keV}}$ as well.

<figure class="ap-figure">
  <img src="/figures/fig4.svg" alt="Unmagnetised heat flow, this work against the paper's Fig. 4" />
  <figcaption>Heat flow induced by electron–α collisions, unmagnetised DT, E<sub>α</sub> = 3.45 MeV. Solid: this work, kinetic closure (paper's set-up). Dashed: this work, algebraic closure (Appendix C). Circles: the paper's Fig. 4.</figcaption>
</figure>

<figure class="ap-figure">
  <img src="/figures/fig5.svg" alt="Magnetised heat flow, this work against the paper's Fig. 5" />
  <figcaption>Heat flow induced by 3.45 MeV α particles moving orthogonally to <b>B</b>, normalised by n<sub>α</sub>⟨v<sub>α</sub>⟩T<sub>e</sub>[keV]. Top: component along the flux; bottom: along <b>b</b>×flux. Solid: the paper's numerics (kinetic closure on its grid, Epperlein–Haines fitted β); dotted: this work, converged kinetic closure with the exact β; dashed: algebraic closure with the fitted β; circles: the paper's Fig. 5.</figcaption>
</figure>

## Magnetic field

```fortran
u    = advection_velocity(z_a, n_ratio, v_drift, j_nu)          ! j0_ea / (e n_e) [m/s], complex (Eq. 40)
coef = resistive_coefficient(te, z_i, lnl, alpha_hat)            ! alpha_par / (e n_e)^2 [Ohm m]
rate = field_generation_rate(coef, dj_dr, j, te, dte_dr)         ! dB_theta/dt [T/s] (Eqs. 41, 43)
```

- **Advection**: $\mathbf u = \mathbf j^0_{e\alpha}/(en_e) = Z_\alpha(n_\alpha/n_e)\langle v_\alpha\rangle j^\nu$.
- **Generation**: for an axial $j^0_{e\alpha}(r)$ in an unmagnetised plasma,
  $\partial B_\theta/\partial t = c\,[-\partial j/\partial r + \tfrac32(j/T_e)\,\partial T_e/\partial r]$ with
  $c = \alpha_\parallel/(en_e)^2$; the second term comes from $\alpha_\parallel \propto T_e^{-3/2}$. `te` and `dte_dr` in any
  consistent unit.
- `resistive_coefficient` uses $\alpha_\parallel = \hat\alpha\,m_e n_e/\tau_{ei}$; the density cancels ($n_e = Z_i n_i$).
  With $\hat\alpha = 0.506$, $Z_i = 1$, $\ln\Lambda = 1$ and 1 keV it is the $1.65\times10^{-9}$ prefactor of Eq. 43 (to four
  digits).

## Plasma helpers

| Function | Value |
|----------|-------|
| `thermal_speed(te)` | $v_{Te} = \sqrt{2T_e/m_e}$ [m/s] |
| `speed_ratio(energy, mass, te)` | $v_\alpha/v_{Te} = \sqrt{E m_e/(T_e m_\alpha)}$ |
| `collision_y_ei(z_i, lnl)` | $Y_{ei} = (1/4\pi)(Z_i e^2/\varepsilon_0 m_e)^2\ln\Lambda$ (Eq. 10) |
| `tau_ei(te, n_i, z_i, lnl)` | $\tau_{ei} = 3\sqrt\pi\,v_{Te}^3/(4Y_{ei}n_i)$ (Eq. 14), Braginskii's $\tau_e$ [s] |
| `coulomb_log_ei_nrl(n_e, te)` | $24 - \ln(n_e^{1/2}/T_e)$, $n_e$ in cm⁻³, $T_e$ in eV (NRL, $T_e > 10Z^2$ eV) |

All arguments in SI, temperatures and energies in joules.

## Constants

`appelbe_constants` (CODATA 2018): `pi`, `sqrt_pi`, `e_charge`, `m_e`, `eps0`, `amu`, `keV_J`, `MeV_J`, `m_proton`,
`m_alpha`, `m_carbon12` (bare C-12 nucleus), `m_DT` (mean D–T ion).
