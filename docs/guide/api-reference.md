---
title: API Reference
---

# API Reference

The [API section](/api/) documents every module, type and procedure, generated from the source comments by
[formal](https://github.com/szaghi/formal):

```bash
cd docs
npm run docs:api      # formal generate --mirror-sources --diagrams --project ford.md --output api
```

`npm run docs:dev` and `npm run docs:build` regenerate it first.

## Public entry point

`use appelbe` exports:

| Entities | Module | Purpose |
|----------|--------|---------|
| `kinetic_params`, `kinetic_operator`, `kinetic_response`, `speed_distribution`, `method_complex`, `method_paper` | `appelbe_kinetic` | the kinetic solver — [Kinetic solver](kinetic-solver) |
| `energy_gaussian`, `energy_flat`, `slowing_down` | `appelbe_distributions` | fast-ion spectra — [Energy spectra](distributions) |
| `fit_response`, `fit_node_response`, `fit_zero_column`, `v_nodes`, `n_nodes` | `appelbe_fits` | Appendix C — [Algebraic closure](algebraic-closure) |
| `heat_flow_thermoelectric`, `heat_flow_direct`, `advection_velocity`, `field_generation_rate` | `appelbe_closure` | Secs. IV–V — [Transport terms](transport) |
| `thermal_speed`, `speed_ratio`, `collision_y_ei`, `tau_ei`, `coulomb_log_ei_nrl`, `resistive_coefficient` | `appelbe_plasma` | dimensional helpers — [Transport terms](transport#plasma-helpers) |
| `pi`, `sqrt_pi`, `e_charge`, `m_e`, `eps0`, `amu`, `keV_J`, `MeV_J`, `m_proton`, `m_alpha`, `m_carbon12`, `m_DT` | `appelbe_constants` | CODATA 2018 |
| `init_paper`, `paper_n_ratio`, `paper_n_nodes`, `paper_u_max`, `paper_fig2_samples`, `paper_fig2_speed`, `paper_fig3_speeds` | `appelbe_paper` | [The paper's set-up](paper-setup) |
| `I4P`, `R8P` | PENF | kinds |

The internal modules (`appelbe_velocity_grid`, `appelbe_linear_solver`, `appelbe_io`) may change without notice.
