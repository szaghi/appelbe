---
title: Drivers and results
---

# Drivers and results

One program per figure or section, `src/app/appelbe_*.F90`, writes plain tables to `results/` (one `#` header line
naming the columns). `fobis rule --ex figures` builds nothing: it runs every `exe/appelbe_*` and then the gnuplot
previews `scripts/*.gp` into `results/*.png`. The whole run takes about four minutes.

Complex quantities are written as two columns, $\perp$ then $\wedge$. "Paper grid" columns are the same computation with
`init_paper` ([the paper's set-up](paper-setup)).

| Driver | Files | Columns |
|--------|-------|---------|
| `appelbe_fig1` | `fig1.dat`, `fig1_paper.dat` | u, f₀, f₁(ωτ=0), f₁⊥(ωτ=10), f₁∧(ωτ=10), each normalised by its maximum (converged; paper grid) |
| `appelbe_fig2` | `fig2.dat` | v, j ratio of p, α, C with n_α/n_e = 0, then with 10⁻³ (dense, 0.1–3) |
| | `fig2_samples.dat` | the same at the paper's 25 samples, plus p, α, C on the paper grid |
| `appelbe_fig3` | `fig3_v<v>.dat` | x = log₁₀ωτ, kinetic j, ζ, Appendix C fits j, ζ, kinetic on the paper grid j, ζ (the six table nodes) |
| | `fig3_summary.dat` | v, max \|kinetic − fit\| of j⊥ j∧ ζ⊥ ζ∧, converged and on the paper grid |
| | `fig3_paper_v<v>.dat` | x, j, ζ converged, j, ζ on the paper grid (the speeds of Fig. 3: 1, 1/3, 0.2, 0.05) |
| `appelbe_fig4` | `fig4.dat` | T_e, q_j q_ζ q_sum kinetic, the same from the fits, β∥, v_α/v_Te, q_j q_ζ q_sum on the paper grid [W s] |
| `appelbe_fig5` | `fig5_Te01keV.dat`, `fig5_Te15keV.dat` | x, q kinetic, q fits [W s keV⁻¹], β, j, ζ (converged), j, ζ (fits), j, ζ, β (paper grid) |
| `appelbe_fig6` | `fig6.dat` | n_α/n_e, K/K₀ and μ/μ₀ at 1, 5, 10 keV, then the same on the paper grid |
| `appelbe_footnote30` | `footnote30.dat` | spectrum, u₀, u_energy, u_flux, ωτ, j and ζ of the spectrum and of the monoenergetic reference |
| `appelbe_sec5` | `sec5.txt`, `sec5_advection.dat`, `sec5_carbon.dat`, `sec5_gradient.dat` | the advection and generation estimates of Sec. V |
| `appelbe_validation` | `validation.dat` | key, value, reference: conventional coefficients, Lorentz limits, Onsager, convergence |
| `appelbe_solvers` | `solvers.dat`, `convergence.dat` | the two solution methods against each other, grid convergence |

Fast-ion runs of the figure drivers use the paper's $n_\alpha/n_e = 10^{-3}$; Sec. V uses $n_\alpha/n_e = 0$, the limit the
paper states. The Fig. 5 heat flow with the Epperlein–Haines $\beta$ is formed from these columns by
`scripts/report_numbers.py` ([Report pipeline](report)).
