!< appelbe: the whole public API in one module (kinds, constants, kinetic solver, algebraic closure, transport terms).
module appelbe
!< appelbe: the whole public API in one module (kinds, constants, kinetic solver, algebraic closure, transport terms).
!<
!< `use appelbe` gives everything a program needs; the individual modules remain usable on their own.
use penf,                  only : I4P, R8P
use appelbe_closure,       only : heat_flow_thermoelectric, heat_flow_direct, advection_velocity, field_generation_rate
use appelbe_constants,     only : pi, sqrt_pi, e_charge, m_e, eps0, amu, keV_J, MeV_J, &
                                  m_proton, m_alpha, m_carbon12, m_DT
use appelbe_distributions, only : energy_gaussian, energy_flat, slowing_down, electron_maxwellian, electron_bipolar, &
                                  electron_table, electron_table_params
use appelbe_eedf,          only : slope_temperature, ts_spectrum, ts_temperature, kinetic_temperature
use appelbe_io,            only : read_table
use appelbe_fits,          only : n_nodes, v_nodes, fit_response, fit_node_response, fit_zero_column
use appelbe_kinetic,       only : kinetic_params, kinetic_operator, kinetic_response, speed_distribution, &
                                  method_complex, method_paper
use appelbe_paper,         only : paper_n_ratio, paper_n_nodes, paper_u_max, paper_fig2_samples, paper_fig3_speeds, &
                                  paper_fig2_speed, init_paper
use appelbe_plasma,        only : thermal_speed, speed_ratio, collision_y_ei, tau_ei, coulomb_log_ei_nrl, &
                                  resistive_coefficient

implicit none
private
! kinds (PENF)
public :: I4P, R8P
! physical constants
public :: pi, sqrt_pi, e_charge, m_e, eps0, amu, keV_J, MeV_J, m_proton, m_alpha, m_carbon12, m_DT
! kinetic solver (Eq. 13, Appendix B)
public :: kinetic_params, kinetic_operator, kinetic_response, speed_distribution, method_complex, method_paper
! fast-ion energy spectra (footnote 30) and electron distributions
public :: energy_gaussian, energy_flat, slowing_down, electron_maxwellian, electron_bipolar, &
                                  electron_table, electron_table_params
! tabulated input (two columns, '#' comments)
public :: read_table
! what Thomson scattering and ECE read from the electron f0
public :: slope_temperature, ts_spectrum, ts_temperature, kinetic_temperature
! algebraic closure (Appendix C)
public :: n_nodes, v_nodes, fit_response, fit_node_response, fit_zero_column
! transport terms (Secs. IV-V) and plasma helpers
public :: heat_flow_thermoelectric, heat_flow_direct, advection_velocity, field_generation_rate
public :: thermal_speed, speed_ratio, collision_y_ei, tau_ei, coulomb_log_ei_nrl, resistive_coefficient
! the paper's own set-up (emulation)
public :: paper_n_ratio, paper_n_nodes, paper_u_max, paper_fig2_samples, paper_fig3_speeds, paper_fig2_speed, init_paper
endmodule appelbe
