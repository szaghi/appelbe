---
title: Installation
---

# Installation

## Requirements

| Tool | Used for |
|------|----------|
| A Fortran 2018 compiler | the library and the programs (tested: gfortran 16.2) |
| [FoBiS.py](https://github.com/szaghi/FoBiS) ≥ 3.8 | build, dependency fetch, rules |
| [PENF](https://github.com/szaghi/PENF) | kind parameters (fetched by FoBiS) |
| gnuplot (pngcairo, svg) | preview plots, documentation figures |
| Python 3 + NumPy | report numbers, documentation examples |
| `mutool` (MuPDF) | extracting curves from the paper's PDF (only to refresh `report/data/`) |
| TeX Live (pdflatex, pgfplots, latexmk) | the report |
| Node.js ≥ 20, [formal](https://github.com/szaghi/formal) | this documentation |

Only the compiler, FoBiS and PENF are needed to use the library.

## Build

```bash
git clone https://github.com/szaghi/appelbe && cd appelbe
fobis fetch                      # PENF into src/third_party/
fobis build --mode static-gnu    # the library: lib/libappelbe.a, modules in lib/mod/
fobis build --mode gnu           # every program under src/ (drivers, tests) into exe/
fobis rule --ex tests            # the verification suite
```

| Mode | Flags | Builds |
|------|-------|--------|
| `static-gnu` | `-O2` | `lib/libappelbe.a` and `lib/mod/*.mod` |
| `gnu` | `-O2` | every program under `src/` into `exe/`: drivers `appelbe_*`, tests `test_*` |
| `gnu-debug` | `-O0 -g3 -fcheck=all -ffpe-trap=invalid,zero,overflow -finit-real=snan` | the same, with runtime checks |

```bash
fobis build --lmodes             # list the modes
fobis rule --ls                  # list the rules: tests, figures, report, docs-examples
```

Run everything from the repository root: the drivers write to `./results/`.

## Use it in a program

```fortran
program my_program
use appelbe          ! the whole API: kinds, constants, solver, closure, transport terms
implicit none
type(kinetic_params)   :: par
type(kinetic_operator) :: op
type(kinetic_response) :: r
call op%init(par=par)
r = op%response(omega_tau=0._R8P)
print *, real(r%beta())
endprogram my_program
```

```bash
gfortran -I lib/mod my_program.F90 lib/libappelbe.a -o my_program
```

The individual modules (`appelbe_kinetic`, `appelbe_fits`, ...) can also be used on their own; see the
[feature map](features).

## As a FoBiS dependency

Declare appelbe and PENF, its only dependency, in the `fobos` of your project:

```ini
[dependencies]
deps_dir = src/third_party
PENF     = https://github.com/szaghi/PENF
appelbe  = https://github.com/szaghi/appelbe
```

```bash
fobis fetch     # clone the sources
fobis build     # the appelbe modules your program uses are compiled with it
```

Exclude `src/third_party/appelbe/src/app`, `src/tests` and `docs` from your build (`exclude_dirs`): they are
appelbe's own programs.

## Toolchains

The code is plain Fortran 2018 and needs no preprocessor definitions. On the CNR workstations and on the medooza
cluster, gfortran 16.2 is the tested compiler; nvfortran works as well but is not part of the build modes.
