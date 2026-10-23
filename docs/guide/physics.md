---
title: The physics
---

# The physics

This page summarises the model of Appelbe et al. (2019) and fixes the notation used in the code and in this
documentation. Equation numbers are the paper's.

## Three species

Thermal electrons $e$, thermal ions $i$ (charge $Z_i$) and a dilute population of fast ions $\alpha$ (charge
$Z_\alpha$; any species, not only α particles). The plasma is quasineutral, $n_e = Z_i n_i + Z_\alpha n_\alpha$, with
$n_\alpha \ll n_e$; fast ions slow down on electrons ($E_\alpha \gg T_e$, $T_e \sim T_i$), the electrons are
quasi-steady on the fast-ion time scales, and the thermal ions are at rest. The electron distribution is expanded as
$f_e = f_0 + \mathbf f_1\cdot\mathbf v/v + \dots$ with a Maxwellian $f_0$; the fast ions as
$F_\alpha = F_0 + \mathbf F_1\cdot\mathbf v/v$.

## The electron $f_1$ equation

The first angular moment of the electron kinetic equation, with the Fokker–Planck collision operators of Shkarofsky,
is a linear integro-differential equation for $\mathbf f_1(v)$ (Eq. 13):

$$
g_1 f_1'' + g_2 f_1' + g_3 f_1 + g_4\!\int_0^v\! v^5 f_1\,dv + g_5\!\int_0^v\! v^3 f_1\,dv
+ g_6\!\int_v^\infty\! f_1\,dv + \omega\tau\,\mathbf b\times\mathbf f_1 = \mathbf g_7 .
$$

The coefficients $g_{1\text{–}6}$ (Eqs. A8–A13) contain electron–electron, electron–ion and, through the isotropic
part $F_0$, electron–fast-ion collisions. The source $\mathbf g_7$ (Eq. 15) is linear in $\nabla n_e$, $\nabla T_e$,
$\mathbf E$ and the anisotropic part $\mathbf F_1$ of the fast ions. $\omega\tau = eB\tau_{ei}/m_e$ is the electron
Hall parameter, with $\tau_{ei} = 3\sqrt\pi\,v_{Te}^3/(4Y_{ei}n_i)$ (Eq. 14, Braginskii's $\tau_e$) and
$v_{Te} = \sqrt{2T_e/m_e}$.

Moments of $f_1$ give the electron current and heat flow; with the fast-ion current $j^0_\alpha$ (Eq. 20), the
collisionally induced current is $j^0_{e\alpha} = \xi_{e\alpha} + j^0_\alpha$:

$$
\xi_{e\alpha} = -\frac{4\pi e}{3}\int_0^\infty v^3 f_1\,dv, \qquad
\zeta_{e\alpha} = \frac{2\pi m_e}{3}\int_0^\infty v^5 f_1\,dv .
\tag{16, 17}
$$

## Transport relations

Because Eq. 13 is linear, the response to each force can be computed separately. The result extends the classical
relations (Eqs. 23–24):

$$
\mathbf E = -\frac{\nabla P_e}{e n_e} + \boldsymbol\sigma^{-1}\!\cdot(\mathbf j_T - \mathbf j^0_{e\alpha})
            - \frac1e\boldsymbol\beta\cdot\nabla T_e , \qquad
\mathbf q_e = -\boldsymbol\kappa\cdot\nabla T_e
             - \frac{T_e}{e}\left(\boldsymbol\beta + \tfrac52\mathbf I\right)\cdot(\mathbf j_T - \mathbf j^0_{e\alpha})
             + \boldsymbol\zeta_{e\alpha} .
$$

$\boldsymbol\sigma$, $\boldsymbol\beta$, $\boldsymbol\kappa$ are the **conventional** coefficients (no fast ions);
the fast ions enter only through $\mathbf j^0_{e\alpha}$ and $\boldsymbol\zeta_{e\alpha}$, which act as independent
sources: they drive heat flow and magnetic field even when $\mathbf j_T = 0$.

## The tensor convention, and complex numbers

Every tensor acts on a driving vector $\mathbf s$ as (Eq. 27)

$$
\boldsymbol\phi\cdot\mathbf s = \phi_\parallel(\mathbf b\cdot\mathbf s)\mathbf b
 + \phi_\perp\,\mathbf b\times(\mathbf s\times\mathbf b) + \phi_\wedge\,\mathbf b\times\mathbf s .
$$

For a drive orthogonal to $\mathbf b$, appelbe writes the two orthogonal components as one complex number,
**$(\perp, \wedge) = (\text{real}, \text{imaginary})$**: $\perp$ is along the drive (for the closure, along the
fast-ion flux), $\wedge$ along $\mathbf b\times$drive. With $f_1 = f_{1x} + i f_{1y}$ one has
$\mathbf b\times\mathbf f_1 \to i f_1$, and Eq. 13 becomes the single complex system $(G + i\omega\tau) f_1 = g_7$.
Tensor algebra becomes complex arithmetic: $\beta = \mu/\sigma - 5/2$, and the heat flows of Eqs. 34–35 are one complex
product. At $\omega\tau = 0$ the imaginary parts vanish and the real part is the parallel (unmagnetised) value.

## The closure

For a monoenergetic population (Eqs. 29–30), $F_0 = n_\alpha\delta(v - v_\alpha)/4\pi v^2$ and
$\mathbf F_1 = \gamma_\alpha F_0\hat{\mathbf u}_\alpha$, with drift $\langle v_\alpha\rangle = \gamma_\alpha v_\alpha/3$
(Eq. 31). Then $f_1$, $j^0_{e\alpha}$ and $\zeta_{e\alpha}$ are proportional to the flux $n_\alpha\langle v_\alpha\rangle$ and
depend only on $v_\alpha/v_{Te}$ and $\omega\tau$:

$$
j^0_{e\alpha} = Z_\alpha e\,n_\alpha\langle v_\alpha\rangle\, j^\nu, \qquad
\zeta_{e\alpha} = n_\alpha\langle v_\alpha\rangle\, T_e\, \zeta^\nu
\tag{C1–C4}
$$

with $T_e$ in joules. The dimensionless $j^\nu$, $\zeta^\nu$ are what the kinetic solver returns (`j_nu`, `zeta_nu`)
and what Appendix C fits for α particles in DT. In the unmagnetised low-velocity limit,
$j^0_{e\alpha}/j^0_\alpha \approx 1 - Z_\alpha/Z_i$ (Eq. 32): $-1$ for α particles in DT, $-5$ for C⁶⁺.

## Heat flow and magnetic field

- **Heat flow** (Eq. 33, unmagnetised): $q_e = (T_e/e)(\beta_\parallel + 5/2)\,j^0_{e\alpha} + \zeta_{e\alpha}$. The first
  term opposes the fast-ion flux, the second is parallel to it and larger. Magnetised (Eqs. 34–35), in complex form,
  $q_e/(n_\alpha\langle v_\alpha\rangle) = T_e[Z_\alpha(\beta + 5/2)j^\nu + \zeta^\nu]$; $q_{e\perp}$ *grows* with $\omega\tau$
  because $j^0_\alpha$ is not magnetised.
- **Advection** (Eq. 40): $\partial\mathbf B/\partial t = \nabla\times(\mathbf j^0_{e\alpha}/(en_e)\times\mathbf B)$, with
  velocity $\mathbf u = \mathbf j^0_{e\alpha}/(en_e)$, whose direction reverses with $\omega\tau$.
- **Generation** (Eqs. 41–43): in an unmagnetised plasma
  $\partial\mathbf B/\partial t = \nabla\times[\alpha_\parallel\mathbf j^0_{e\alpha}/(en_e)^2]$ creates field from zero, with
  $\alpha_\parallel = 0.506\,m_e n_e/\tau_{ei}$ for $Z_i = 1$ (Eq. 42).

## Units in the code

The solver works in normalised units: $u = v/v_{Te}$, each distribution per $n/v_{Te}^3$ of its species, time in
$\tau_{ei}$. Every $\tau_{ei}Y_{ab}n_b/v_{Te}^3$ becomes a pure number ($3\sqrt\pi/4$ times charge and density ratios),
and the drives are dimensionless through the mean free path $\lambda = v_{Te}\tau_{ei}$. Conventional coefficients are
returned in Epperlein–Haines units: $\sigma$ in $n_e e^2\tau_{ei}/m_e$, $\kappa$ in $n_e T_e\tau_{ei}/m_e$, $\beta$
dimensionless. Dimensional quantities (Sec. V) are in SI, with temperatures in joules (`keV_J` converts).
