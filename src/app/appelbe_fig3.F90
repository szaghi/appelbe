!< Fig. 3 (validation of the algebraic closure): kinetic j0_ea, zeta_ea versus the Appendix C fits, alphas in DT.
program appelbe_fig3
!< Fig. 3 (validation of the algebraic closure): kinetic j0_ea, zeta_ea versus the Appendix C fits, alphas in DT.
!<
!< For each tabulated v_a/v_Te (except 0.025, under-resolved on the default grid) the Eq. (13) solver is run over
!< x = log10(omega tau) in [-3, 3] and compared with the rational fits of Eqs. (C5)-(C8).
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_constants,             only : m_e, m_alpha
use appelbe_fits,                  only : v_nodes, fit_node_response
use appelbe_io,                    only : open_results
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response

implicit none
type(kinetic_params)    :: par             !< Physical parameters.
type(kinetic_operator)  :: op              !< Kinetic operator.
type(kinetic_response)  :: r               !< Kinetic response.
complex(R8P)            :: j_fit, zeta_fit !< Fitted response.
real(R8P)               :: x               !< log10(omega tau).
real(R8P)               :: max_dev(4)      !< Max |kinetic - fit| of (j_perp, j_wedge, zeta_perp, zeta_wedge).
integer(I4P)            :: k, i, unit      !< Counters, output unit.
integer(I4P)            :: unit_summary    !< Summary table.
integer(I4P), parameter :: n_x = 61_I4P    !< Number of x samples.
character(len=32)       :: file_name       !< Output file.

par%z_i        = 1._R8P
par%z_a        = 2._R8P
par%mass_ratio = m_e / m_alpha
write(output_unit, '(A)') 'Fig. 3: max |kinetic - fit| over -3 <= x <= 3'
unit_summary = open_results('fig3_summary.dat', 'v_a/v_Te max_dj_perp max_dj_wedge max_dzeta_perp max_dzeta_wedge')
write(output_unit, '(A)') '  v_a/v_Te     j_perp    j_wedge  zeta_perp zeta_wedge'
do k = 1_I4P, 5_I4P
   par%u_a = v_nodes(k)
   call op%init(par=par)
   write(file_name, '(A,F5.3,A)') 'fig3_v', v_nodes(k), '.dat'
   unit = open_results(file_name, 'x j_perp_kin j_wedge_kin zeta_perp_kin zeta_wedge_kin '// &
                                  'j_perp_fit j_wedge_fit zeta_perp_fit zeta_wedge_fit')
   max_dev = 0._R8P
   do i = 1_I4P, n_x
      x = -3._R8P + 6._R8P * real(i - 1_I4P, R8P) / real(n_x - 1_I4P, R8P)
      r = op%response(omega_tau=10._R8P**x)
      call fit_node_response(k, x, j_fit, zeta_fit)
      write(unit, '(9ES15.6)') x, r%j_nu, r%zeta_nu, j_fit, zeta_fit
      max_dev = max(max_dev, abs([real(r%j_nu - j_fit, R8P),       aimag(r%j_nu - j_fit), &
                                  real(r%zeta_nu - zeta_fit, R8P), aimag(r%zeta_nu - zeta_fit)]))
   enddo
   close(unit)
   write(output_unit, '(F10.3,4F11.4)') v_nodes(k), max_dev
   write(unit_summary, '(5ES14.5)') v_nodes(k), max_dev
enddo
close(unit_summary)
endprogram appelbe_fig3
