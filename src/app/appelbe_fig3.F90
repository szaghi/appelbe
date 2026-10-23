!< Fig. 3 and Tables I-IV: kinetic j0_ea, zeta_ea of alphas in DT versus omega tau, against the paper's fits and figure.
program appelbe_fig3
!< Fig. 3 and Tables I-IV: kinetic j0_ea, zeta_ea of alphas in DT versus omega tau, against the paper's fits and figure.
!<
!< The Eq. (13) solver, in the paper's set-up (isotropic F0 with n_a/n_e = 1e-3, appelbe_paper), is run over
!< x = log10(omega tau) in [-3, 3], both converged and on the paper's own grid:
!< - fig3_v<v>.dat, fig3_summary.dat: at the six tabulated v_a/v_Te of Appendix C, against the rational fits of
!<   Eqs. (C5)-(C8). The 0.025 row needs a finer grid (u_a >= 4 h) for the converged solution;
!< - fig3_paper_v<v>.dat: at the four v_a/v_Te of the paper's Fig. 3 legend (1, 1/3, 0.2, 0.05), for the comparison with
!<   the curves extracted from the figure.
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_constants,             only : m_e, m_alpha
use appelbe_fits,                  only : n_nodes, v_nodes, fit_node_response
use appelbe_io,                    only : open_results
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_paper,                 only : paper_n_ratio, paper_fig3_speeds, init_paper

implicit none
type(kinetic_params)    :: par             !< Physical parameters.
type(kinetic_operator)  :: op, opp         !< Kinetic operators: converged, paper's grid.
type(kinetic_response)  :: r, rp           !< Kinetic responses: converged, paper's grid.
complex(R8P)            :: j_fit, zeta_fit !< Fitted response.
real(R8P)               :: x               !< log10(omega tau).
real(R8P)               :: max_dev(8)      !< Max |kinetic - fit| of (j_perp, j_wedge, zeta_perp, zeta_wedge), both grids.
integer(I4P)            :: k, i, unit      !< Counters, output unit.
integer(I4P)            :: unit_summary    !< Summary table.
integer(I4P), parameter :: n_x = 61_I4P    !< Number of x samples.
character(len=32)       :: file_name       !< Output file.

par%z_i        = 1._R8P
par%z_a        = 2._R8P
par%mass_ratio = m_e / m_alpha
par%n_ratio    = paper_n_ratio
write(output_unit, '(A)') 'Fig. 3: max |kinetic - fit| over -3 <= x <= 3 (converged; paper grid)'
unit_summary = open_results('fig3_summary.dat', 'v_a/v_Te max_dj_perp max_dj_wedge max_dzeta_perp max_dzeta_wedge '// &
                                                 '(converged) same (paper grid)')
do k = 1_I4P, n_nodes
   par%u_a = v_nodes(k)
   call init_resolved(v_nodes(k))
   call init_paper(opp, par)
   write(file_name, '(A,F5.3,A)') 'fig3_v', v_nodes(k), '.dat'
   unit = open_results(file_name, 'x j_perp_kin j_wedge_kin zeta_perp_kin zeta_wedge_kin '// &
                                  'j_perp_fit j_wedge_fit zeta_perp_fit zeta_wedge_fit (kinetic on the paper grid)x4')
   max_dev = 0._R8P
   do i = 1_I4P, n_x
      x = -3._R8P + 6._R8P * real(i - 1_I4P, R8P) / real(n_x - 1_I4P, R8P)
      r  = op%response(omega_tau=10._R8P**x)
      rp = opp%response(omega_tau=10._R8P**x)
      call fit_node_response(k, x, j_fit, zeta_fit)
      write(unit, '(13ES15.6)') x, r%j_nu, r%zeta_nu, j_fit, zeta_fit, rp%j_nu, rp%zeta_nu
      max_dev = max(max_dev, abs([real(r%j_nu - j_fit, R8P),        aimag(r%j_nu - j_fit),         &
                                  real(r%zeta_nu - zeta_fit, R8P),  aimag(r%zeta_nu - zeta_fit),   &
                                  real(rp%j_nu - j_fit, R8P),       aimag(rp%j_nu - j_fit),        &
                                  real(rp%zeta_nu - zeta_fit, R8P), aimag(rp%zeta_nu - zeta_fit)]))
   enddo
   close(unit)
   write(output_unit, '(F10.3,8F9.4)') v_nodes(k), max_dev
   write(unit_summary, '(9ES14.5)') v_nodes(k), max_dev
enddo
close(unit_summary)

do k = 1_I4P, size(paper_fig3_speeds, kind=I4P)
   par%u_a = paper_fig3_speeds(k)
   call init_resolved(paper_fig3_speeds(k))
   call init_paper(opp, par)
   write(file_name, '(A,F5.3,A)') 'fig3_paper_v', paper_fig3_speeds(k), '.dat'
   unit = open_results(file_name, 'x j_perp j_wedge zeta_perp zeta_wedge (converged) same (paper grid)')
   do i = 1_I4P, n_x
      x = -3._R8P + 6._R8P * real(i - 1_I4P, R8P) / real(n_x - 1_I4P, R8P)
      r  = op%response(omega_tau=10._R8P**x)
      rp = opp%response(omega_tau=10._R8P**x)
      write(unit, '(9ES15.6)') x, r%j_nu, r%zeta_nu, rp%j_nu, rp%zeta_nu
   enddo
   close(unit)
enddo
write(output_unit, '(A)') 'Fig. 3 written to results/fig3_*.dat'
contains
   subroutine init_resolved(v)
   !< Initialise the converged operator on the default grid, or on a finer one when v_a/v_Te < 4 h of the default grid.
   real(R8P), intent(in) :: v !< v_a / v_Te.

   if (v >= 0.1_R8P) then
      call op%init(par=par)
   elseif (v >= 0.05_R8P) then
      call op%init(par=par, n_nodes=701_I4P)
   else
      call op%init(par=par, n_nodes=1001_I4P, u_max=5._R8P) ! h = 0.005; u_max = 5 changes j, zeta by < 1e-8
   endif
   endsubroutine init_resolved
endprogram appelbe_fig3
