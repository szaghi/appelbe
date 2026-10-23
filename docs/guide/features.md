---
title: Feature map
---

# Feature map

`use appelbe` exports everything below; each module can also be used on its own.

| Task | Entity | Module | Page |
|------|--------|--------|------|
| Physical parameters of a run | `kinetic_params` | `appelbe_kinetic` | [Kinetic solver](kinetic-solver#physical-parameters) |
| Assemble the collision operator | `kinetic_operator%init` | `appelbe_kinetic` | [Kinetic solver](kinetic-solver#the-operator) |
| Transport coefficients and closure at one ωτ | `kinetic_operator%response` | `appelbe_kinetic` | [Kinetic solver](kinetic-solver#the-response) |
| β, κ, 1/σ from a response | `kinetic_response%beta`, `kappa`, `resistivity` | `appelbe_kinetic` | [Kinetic solver](kinetic-solver#the-response) |
| f₁ for given sources | `kinetic_operator%solve`, `solve_paper` | `appelbe_kinetic` | [Kinetic solver](kinetic-solver#lower-level-access) |
| The three drives | `source_electric`, `source_thermal`, `source_fast_flux` | `appelbe_kinetic` | [Kinetic solver](kinetic-solver#lower-level-access) |
| Choose the solver | `method_complex`, `method_paper` | `appelbe_kinetic` | [Kinetic solver](kinetic-solver#solution-methods) |
| Fast ions with an energy spread | `init(..., distribution, shape_params)`, `speed_distribution` | `appelbe_kinetic` | [Energy spectra](distributions) |
| Gaussian, flat, slowing-down spectra | `energy_gaussian`, `energy_flat`, `slowing_down` | `appelbe_distributions` | [Energy spectra](distributions) |
| Non-Maxwellian electron f₀ | `init(..., electrons, electron_params)`, `electron_maxwellian`, `electron_bipolar` | `appelbe_kinetic`, `appelbe_distributions` | [Non-Maxwellian electrons](electrons) |
| A tabulated f₀ (e.g. INDACO) | `electron_table`, `electron_table_params`, `read_table` | `appelbe_distributions`, `appelbe_io` | [Non-Maxwellian electrons](electrons) |
| What TS and ECE read from f₀ | `ts_spectrum`, `ts_temperature`, `kinetic_temperature`, `slope_temperature` | `appelbe_eedf` | [Non-Maxwellian electrons](electrons#what-the-diagnostics-read) |
| Appendix C closure at any v, ωτ | `fit_response` | `appelbe_fits` | [Algebraic closure](algebraic-closure) |
| One table row, the ωτ = 0 column | `fit_node_response`, `fit_zero_column`, `v_nodes` | `appelbe_fits` | [Algebraic closure](algebraic-closure) |
| Heat flows (Eqs. 33–35) | `heat_flow_thermoelectric`, `heat_flow_direct` | `appelbe_closure` | [Transport terms](transport#heat-flow) |
| Field advection, generation (Eqs. 40, 43) | `advection_velocity`, `field_generation_rate` | `appelbe_closure` | [Transport terms](transport#magnetic-field) |
| v_Te, v_α/v_Te, τ_ei, lnΛ | `thermal_speed`, `speed_ratio`, `tau_ei`, `coulomb_log_ei_nrl`, `collision_y_ei` | `appelbe_plasma` | [Transport terms](transport#plasma-helpers) |
| α∥/(e n_e)² of Eq. 43 | `resistive_coefficient` | `appelbe_plasma` | [Transport terms](transport#magnetic-field) |
| Physical constants | `e_charge`, `m_e`, `eps0`, `amu`, `keV_J`, `MeV_J`, `m_proton`, `m_alpha`, `m_carbon12`, `m_DT`, `pi` | `appelbe_constants` | [Transport terms](transport#constants) |
| The paper's numerics | `init_paper`, `paper_n_ratio`, `paper_fig2_speed`, `paper_fig3_speeds` | `appelbe_paper` | [The paper's set-up](paper-setup) |
| Kinds | `I4P`, `R8P` | PENF | — |

Internal modules: `appelbe_velocity_grid` (grid, stencils, quadrature weights), `appelbe_linear_solver` (dense
elimination), `appelbe_io` (results files of the drivers; `read_table` is exported).
