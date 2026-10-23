---
title: Tutorial
---

# Tutorial

Seven short chapters, each a complete program you can compile and run. They start from the conventional transport
coefficients, add a drifting fast-ion population, magnetise the plasma, form the heat flow and the magnetic-field
terms, give the fast ions an energy spread, and end with the paper's own numerics.

| Chapter | You learn |
|---------|-----------|
| [1. Transport coefficients](./tutorial/01-coefficients) | the operator, a response, σ β κ at any Hall parameter |
| [2. A drifting fast-ion population](./tutorial/02-fast-ions) | `j_nu`, `zeta_nu`, the low-velocity limit (Eq. 32), other species |
| [3. A magnetised plasma](./tutorial/03-magnetised) | the (⊥, ∧) components as complex numbers, the paper's solver |
| [4. The heat flow](./tutorial/04-heat-flow) | Eqs. 33–35, the kinetic and the algebraic closure |
| [5. Magnetic fields](./tutorial/05-magnetic-field) | τ<sub>ei</sub>, lnΛ, advection (Eq. 40) and generation (Eq. 43) in SI units |
| [6. Energy spectra](./tutorial/06-spectra) | fast ions with a Gaussian or slowing-down spectrum (footnote 30) |
| [7. The paper, number by number](./tutorial/07-paper) | the paper's set-up, its grid, the drivers and the report |

## Running the examples

Every program on these pages lives in `docs/examples/src/` and is built and run by

```bash
fobis rule --ex docs-examples      # python3 scripts/docs_examples.py
```

which compiles each example against `lib/libappelbe.a` and regenerates the snippets and the outputs shown here.
To compile one by hand:

```bash
fobis build --mode static-gnu
gfortran -I lib/mod docs/examples/src/tut01_conventional.F90 lib/libappelbe.a -o tut01
./tut01
```

Every program starts with `use appelbe`, which gives the whole API and the PENF kinds `I4P`, `R8P`.
