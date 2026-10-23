---
title: Findings and errata
---

# Findings and errata

The reproduction checked every equation, figure, table and number of Secs. III C–VI. What it found:

## Errors in the paper

1. **Eqs. B6–B7** print the right-hand sides as "$(G \pm \Omega)g_{7x,y}$", which drops the cross-component coupling. From
   Eq. B5 they are $Gg_{7x} + \Omega g_{7y}$ and $Gg_{7y} - \Omega g_{7x}$ (implemented in `solve_paper`).
2. **Sec. V B, units**: the current densities are given in A m⁻³ ($j^0_\alpha = 3.4\times10^{17}$,
   $j^0_{e\alpha} \approx 6\times10^{15}$); the unit is A m⁻².
3. **Sec. V B, α flux across a temperature gradient**: $j^0_{e\alpha} \approx 6\times10^{15}$ A m⁻² exceeds the bound
   $Z_\alpha e\,n_\alpha\langle v_\alpha\rangle\max|j^\nu| \approx 4.8\times10^{15}$; the kinetic values are $(3.6$–$4.8)\times10^{15}$, and
   $T_{\text{keV}}^{5/2}\partial B/\partial t$ is $(2$–$3.5)\times10^{13}$ T s⁻¹, not $6\times10^{13}$ (which would need
   $\ln\Lambda_{ei} \approx 4$ at all temperatures).
4. **Sec. V B, carbon beam**: the estimate uses $j^0_{e\alpha} \approx -5j^0_\alpha$ at 1–10 keV, but at 1–2 keV a 200 MeV C⁶⁺
   ion has $v_\alpha/v_{Te} = 2$–3, beyond Fig. 2, where the ratio collapses ($-0.05$ at 1 keV, $-1.7$ at 2 keV). The rates
   are $3\times10^{12}$–$6\times10^{13}$ T s⁻¹, not $10^{13}$–$10^{15}$.
5. **Sec. V A**: "advection velocities of up to $10^4$ m s⁻¹" is half the paper's own estimate
   $2(n_\alpha/n_e)\langle v_\alpha\rangle$; the computed maximum is $3\times10^4$ m s⁻¹.

## Choices the paper does not state

Found by the comparison and documented in [the paper's set-up](paper-setup):

6. The fast-ion runs keep an isotropic α population with $n_\alpha/n_e = 10^{-3}$ in the collision operator, not the
   $n_\alpha \ll n_e$ limit of Sec. III (a 4% effect for carbon in Fig. 2).
7. The fast-ion runs use a coarse speed grid ($h = 5/198$) without a node at $v_\alpha$; its $O(h)$ error reaches 10% in the
   lobe of $f_{1\perp}$ (Fig. 1) and 0.04 in $j^0_{e\alpha}/j^0_\alpha$ (carbon, Fig. 2).
8. The speed printed as 0.33 (Fig. 3, Tables I–IV) is $1/3$.
9. Fig. 5 uses the Epperlein–Haines fitted $\beta$, whose $\beta_\perp$ form is wrong at small Hall parameter; $q_{e\wedge}$
   is off by up to 18–29% of its peak as a result.
10. Fig. 2 is a polyline through 25 temperatures; it has no sample between $v_\alpha/v_{Te} = 0.44$ and 1, misses the
    minimum of the α curve there, and only *appears* to contradict Table I at 0.5.

## Claims checked

- **Footnote 30** (broad spectra behave as monoenergetic ones to 1%): true for moderate spreads at
  $v_\alpha/v_{Te} \le 0.5$, false at $v_\alpha/v_{Te} = 1$ and for the slowing-down distribution (4–5%).
- **Fig. 5 was computed kinetically**, not from the paper's own fits: at 1 keV its plateau ($6.15\times10^{-16}$ W s keV⁻¹)
  is 2% from the kinetic value and 5% from the interpolated fits.
- **The physics holds**: heat flow along the α flux, growing with magnetisation; field advection reversing with $\omega\tau$;
  field generation with $\mathbf j_T = 0$; negligible $F_0$ effect for $n_\alpha/n_e \lesssim 10^{-3}$.
- **Coulomb logarithms**: NRL gives $\lambda_{ee} = \lambda_{ei}$ at these temperatures, so the unit ratios are the paper's
  choice too.
