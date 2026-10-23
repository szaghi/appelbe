---
title: About appelbe
---

# About appelbe

**appelbe** computes how collisions with a population of fast ions change electron transport in a plasma. When the
fast ions drift (they have a net flux), electron–fast-ion collisions push the electron distribution away from a
Maxwellian, and the electrons carry a current and a heat flow that no conventional transport model contains. The
current does not cancel the fast-ion current, so a net **collisionally induced current** $j^0_{e\alpha}$ enters Ohm's
law, the induction equation and the heat flow, even when $n_\alpha \ll n_e$.

The theory and the closure are those of

> B. Appelbe, M. Sherlock, O. El-Amiri, C. Walsh, J. Chittenden, *Modification of classical electron transport due to
> collisions between electrons and fast ions*, Phys. Plasmas **26**, 102704 (2019),
> [doi:10.1063/1.5114794](https://doi.org/10.1063/1.5114794).

appelbe is a reproduction of that paper and a library built on it.

## What it gives you

- **A kinetic solver** of the steady electron $f_1$ equation (the paper's Eq. 13) with the Fokker–Planck collision
  operators of Shkarofsky: the conventional transport coefficients (σ, β, κ, α of Braginskii and Epperlein–Haines)
  and the fast-ion response $j^\nu$, $\zeta^\nu$, for any fast-ion species, any Hall parameter $\omega\tau$ and any
  energy spectrum. Two solution methods: the paper's Appendix B procedure and a complex formulation.
- **The algebraic closure** of the paper's Appendix C: rational fits of $j^\nu$, $\zeta^\nu$ for α particles in DT,
  cheap enough for an MHD code.
- **The transport terms** of Secs. IV–V: heat flows (Eqs. 33–35), field advection (Eq. 40) and generation (Eq. 43),
  with the collision time and the Coulomb logarithm.
- **The reproduction**: drivers that recompute every figure, table and number of the paper, curves extracted from the
  paper's vector graphics, and a LaTeX report that compares them point by point.

## Why it exists

appelbe is a companion of [adam](https://github.com/szaghi/adam): the closure is meant for **FLUME** (MHD), which
needs the new Ohm's-law, induction and heat-flow terms, with **PRISM** (PIC) as a natural source of the fast-ion flux
$n_\alpha\langle v_\alpha\rangle$. Before a closure goes into a production code it must be trusted, so the first goal
was to reproduce the paper exactly. Doing so exposed several choices the paper does not state, and a few of its
errors; they are documented in [Findings and errata](errata) and isolated in
[the paper's set-up](paper-setup).

## What it is not

appelbe is deliberately simple: dense matrices, no parallelism, no LAPACK. A response on the default grid takes about
20 ms, and a closure table for an MHD code is a one-off computation. It does not couple the closure to a fluid
code (that is FLUME's job), and it does not evolve fast-ion distributions.

## Where to start

1. [Install](install) the library.
2. Read [the physics](physics) in brief, with the notation used everywhere.
3. Follow the [tutorial](/manual/): from conventional coefficients to the paper, number by number.
4. Look up a task in the [cookbook](/manual/cookbook), a procedure in the [reference](features) or the [API](/api/).

## Authors

- Federico Negro
- Luca Senni
- Stefano Zaghi — [@szaghi](https://github.com/szaghi)
- Claude (Anthropic) — AI assistant

Contributions are welcome — see [Contributing](contributing).

## Copyrights

appelbe is distributed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html). The paper
itself is not distributed: the curves in `report/data/` are numerical data extracted from its figures, kept only to make
the comparison reproducible.
