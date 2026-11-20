---
layout: home

hero:
  name: appelbe
  text: Electron transport with fast ions
  tagline: The current and heat flow that a drifting population of fast ions drives in a plasma, from a kinetic Fokker–Planck solver and from the simple-algebraic closure of Appelbe et al. (2019). Every result of the paper reproduced and explained, in plain Fortran.
  actions:
    - theme: brand
      text: Tutorial
      link: /manual/tutorial/01-coefficients
    - theme: alt
      text: Cookbook
      link: /manual/cookbook
    - theme: alt
      text: The physics
      link: /guide/physics
    - theme: alt
      text: Reproduction status
      link: /guide/validation
    - theme: alt
      text: View on GitHub
      link: https://github.com/szaghi/appelbe

features:
  - icon: ⚛️
    title: Kinetic solver
    details: The linearised electron f₁ equation (Eq. 13) with electron–electron, electron–ion and electron–fast-ion Fokker–Planck operators, for any fast-ion species, any Hall parameter and any energy spectrum.
    link: /guide/kinetic-solver
    linkText: The solver
  - icon: 🧮
    title: Algebraic closure
    details: The rational fits of the paper's Appendix C for α particles in DT, interpolated in v<sub>α</sub>/v<sub>Te</sub> — the closure an MHD code can afford in every cell.
    link: /guide/algebraic-closure
    linkText: The fits
  - icon: 🔀
    title: Two equivalent solvers
    details: The paper's Appendix B procedure (GG + Ω²) and a complex formulation (G + iωτ) f₁ = g₇ in which tensor algebra is complex arithmetic. They agree to 1e-9.
    link: /manual/tutorial/03-magnetised
    linkText: Magnetised plasma
  - icon: ✅
    title: Verified
    details: Epperlein–Haines coefficients to four digits, the exact Lorentz limits, Onsager symmetry to 5e-8, second-order grid convergence; 176 checks in every build mode.
    link: /guide/validation
    linkText: Verification
  - icon: 🔍
    title: Reproduced, curve by curve
    details: All six figures extracted from the paper's vector graphics and compared point by point. With the paper's own numerics reconstructed, every curve is matched to within 1.6% of its peak.
    link: /guide/validation
    linkText: Reproduction status
  - icon: 🕵️
    title: The paper's unstated choices
    details: n<sub>α</sub>/n<sub>e</sub> = 10⁻³ in the operator, a coarse grid with no node at v<sub>α</sub>, Fig. 2 as a polyline of 25 samples, 0.33 meaning 1/3, the Epperlein–Haines fitted β — each found and tested.
    link: /guide/paper-setup
    linkText: The set-up
  - icon: 🌡️
    title: Broad energy spectra
    details: Gaussian, flat and slowing-down α populations, or your own; the paper's footnote 30 tested and bounded.
    link: /manual/tutorial/06-spectra
    linkText: Energy spectra
  - icon: 📡
    title: Non-Maxwellian electrons
    details: Any electron f₀, analytic or tabulated, in the collision operator and the drives, with what Thomson scattering and ECE read from it. For the ECE/TS temperature discrepancy.
    link: /guide/electrons
    linkText: Beyond the paper
  - icon: 🪶
    title: Simple by design
    details: Fortran 2018, dense matrices, no LAPACK, one dependency (PENF). One FoBiS build; the full reproduction runs in four minutes on a laptop.
    link: /guide/install
    linkText: Install
---

<div class="ap-home">

## The physics in one figure

<p class="ap-lead">Collisions with a drifting population of fast ions (here 3.45 MeV α particles at T<sub>e</sub> = 2 keV)
distort the electron distribution: its anisotropic part f<sub>1</sub> carries a current and a heat flow even when every
other force vanishes. Lines are this code; circles are the paper's Fig. 1, read from its vector graphics.</p>

<figure class="ap-figure">
  <img src="/figures/fig1.svg" alt="Electron f1 driven by fast alpha particles, this work against the paper" />
  <figcaption>Fig. 1 of the paper. The dotted red line is the same solution on the paper's coarse grid, which accounts
  for the deeper lobe of its f<sub>1⊥</sub> (<a href="./guide/paper-setup">the paper's set-up</a>).</figcaption>
</figure>

## Quick start

<<< @/examples/snippets/tut02_fast_ions-alpha.F90{fortran}

```bash
fobis fetch                      # PENF, the only dependency
fobis build --mode static-gnu    # lib/libappelbe.a and lib/mod/*.mod: use appelbe
fobis build --mode gnu           # the drivers into bin/
fobis build --mode tests-gnu     # the tests into exe/
fobis rule --ex tests            # 176 checks
fobis rule --ex figures          # reproduce the paper: results/*.dat
```

## The paper, reproduced

<p class="ap-lead">Every panel of every figure, this work (lines) against the paper (markers). The
<a href="./guide/validation">reproduction status</a> quantifies each curve; the <a href="./guide/errata">findings</a>
list what the comparison revealed about the paper.</p>

<div class="ap-gallery">
  <figure class="ap-figure"><img src="/figures/fig2.svg" alt="Unmagnetised current ratio, this work against the paper's Fig. 2" /><figcaption>Fig. 2 — unmagnetised current ratio for protons, α particles and carbon</figcaption></figure>
  <figure class="ap-figure"><img src="/figures/fig3.svg" alt="Induced current and heat flow versus the Hall parameter, this work against the paper's Fig. 3" /><figcaption>Fig. 3 — induced current and heat flow versus the Hall parameter</figcaption></figure>
  <figure class="ap-figure"><img src="/figures/fig4.svg" alt="Unmagnetised heat flow, this work against the paper's Fig. 4" /><figcaption>Fig. 4 — heat flow in an unmagnetised plasma</figcaption></figure>
  <figure class="ap-figure"><img src="/figures/fig5.svg" alt="Magnetised heat flow, this work against the paper's Fig. 5" /><figcaption>Fig. 5 — magnetised heat flow, along the α flux and along b × flux</figcaption></figure>
  <figure class="ap-figure"><img src="/figures/fig6.svg" alt="Coefficients with an isotropic alpha population, this work against the paper's Fig. 6" /><figcaption>Fig. 6 — conventional coefficients with an isotropic α population</figcaption></figure>
  <figure class="ap-figure"><img src="/figures/solvers.svg" alt="The paper's solver against the complex formulation" /><figcaption>The paper's solver against the complex formulation</figcaption></figure>
</div>

## Reference

B. Appelbe, M. Sherlock, O. El-Amiri, C. Walsh, J. Chittenden, *Modification of classical electron transport due to
collisions between electrons and fast ions*, Phys. Plasmas **26**, 102704 (2019),
[doi:10.1063/1.5114794](https://doi.org/10.1063/1.5114794).

## Authors

- Federico Negro
- Luca Senni
- Stefano Zaghi — [@szaghi](https://github.com/szaghi)
- Claude (Anthropic) — AI assistant

## Copyrights

appelbe is distributed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html).

</div>
