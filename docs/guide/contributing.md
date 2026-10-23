---
title: Contributing
---

# Contributing

This is a FOSS project — anyone interested in using, developing, or contributing is welcome. It follows a KISS (Keep It
Simple and Stupid) philosophy: simplicity and maintainability over performance.

## Reporting issues

- Open a ticket on the repository **GitHub Issues** page.
- Describe the problem clearly, with the steps to reproduce it.
- For a disagreement with the paper, give the equation, figure or table and the numbers.

## Pull requests

1. Fork the repository and create a topic branch.
2. Build and test in both modes:
   ```bash
   fobis build --mode gnu-debug && fobis rule --ex tests
   fobis build --mode gnu && fobis rule --ex tests
   ```
3. If the change affects results, regenerate them and the report (`fobis rule --ex figures`, `fobis rule --ex report`)
   and check `git diff` of `report/`.
4. If it affects the documented behaviour, regenerate the examples (`fobis rule --ex docs-examples`) and the figures
   (`gnuplot scripts/docs_figures.gp`).
5. Python scripts must pass `ruff check scripts`.
6. Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/).

## Fortran style

- `.F90` files, one module per file, the file named after the module.
- `implicit none` everywhere; explicit `intent` on every dummy argument; PENF kinds (`I4P`, `R8P`).
- Every module, type, procedure and variable documented with a `!<` comment: the [API](/api/) is generated from them.
- Cite the paper's equation numbers in comments.
- No mutable module-level state; derived types with `init` and type-bound procedures.

## Documentation

```bash
fobis rule --ex docs-examples          # snippets and outputs of the tutorial and cookbook
gnuplot scripts/docs_figures.gp        # docs/public/figures/*.svg (needs results/ and report/generated/)
cd docs && npm install && npm run docs:dev
```
