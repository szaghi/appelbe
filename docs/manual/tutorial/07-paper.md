---
title: 7. The paper, number by number
---

# 7. The paper, number by number

appelbe reproduces every figure, table and quoted number of Secs. III C–VI. Doing so exposed choices the paper does
not state; `appelbe_paper` collects them, so that a computation can be made **the way the paper made it**.

<<< @/examples/snippets/tut07_paper-carbon.F90{fortran}

<<< @/examples/output/tut07.txt{text}

- `paper_n_ratio` ($10^{-3}$): the paper's fast-ion runs keep an isotropic α population of that density in the
  collision operator, not the $n_\alpha \ll n_e$ limit stated in its Sec. III.
- `paper_fig2_speed(k)`: the paper's Fig. 2 is a polyline through 25 samples equally spaced in temperature.
- `init_paper(op, par)`: the paper's speed grid, 199 nodes on $[0, 5]$ with **no node at $u_\alpha$**. Its $O(h)$ error
  depends on where $u_\alpha$ falls in its cell — here 0.04 at $v_\alpha/v_{Te} = 1$ — and it is exactly the residual
  between the paper and our converged solution.

The converged solution is the physical one; `init_paper` exists only to show that nothing else separates us from the
paper. The evidence for each choice is in [the paper's set-up](/guide/paper-setup).

## The drivers

One program per figure or section writes `results/*.dat`:

```bash
fobis build --mode gnu
fobis rule --ex figures          # every exe/appelbe_* -> results/, gnuplot previews results/*.png
./exe/appelbe_fig5               # or one of them
```

| Driver | Reproduces |
|--------|------------|
| `appelbe_fig1` … `appelbe_fig6` | Figs. 1–6 (Fig. 3 with Tables I–IV), converged and with the paper's numerics |
| `appelbe_footnote30` | footnote 30, broad spectra |
| `appelbe_sec5` | the advection and generation estimates of Sec. V |
| `appelbe_validation`, `appelbe_solvers` | verification: coefficients, convergence, the two solvers |

Columns and files are listed in [Drivers and results](/guide/drivers).

## The report

```bash
fobis rule --ex report           # report/generated/*.tex + report/appelbe_report.pdf
```

The PDF compares every curve, extracted from the paper's vector graphics, with these results, and every quoted number;
every number in it comes from the last run ([Report pipeline](/guide/report)). The outcome is summarised in
[Reproduction status](/guide/validation).

::: tip What you learned
The paper's set-up as code, the drivers, the report. Reference: [The paper's set-up](/guide/paper-setup),
[Drivers and results](/guide/drivers), [Reproduction status](/guide/validation).
:::

That is the tutorial. For tasks, see the [cookbook](../cookbook).
