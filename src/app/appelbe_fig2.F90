!< Fig. 2 (supports Sec. V B): unmagnetised j0_ea / j0_a versus v_a/v_Te for protons, alphas and C6+ in DT.
program appelbe_fig2
!< Fig. 2 (supports Sec. V B): unmagnetised j0_ea / j0_a versus v_a/v_Te for protons, alphas and C6+ in DT.
!<
!< Kinetic solver only (the algebraic fits cover alphas only). The range is extended to v_a/v_Te = 3 to cover the carbon
!< beam of Sec. V B at T_e = 1-2 keV. The v_a/v_Te -> 0 limit is 1 - Z_a/Z_i (Eq. 32).
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_constants,             only : m_e, m_proton, m_alpha, m_carbon12
use appelbe_io,                    only : open_results
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response

implicit none
type(kinetic_params)    :: par                                         !< Physical parameters.
type(kinetic_operator)  :: op                                          !< Kinetic operator.
type(kinetic_response)  :: r                                           !< Kinetic response.
real(R8P)               :: v, ratio(3)                                 !< v_a/v_Te, j0_ea/j0_a per species.
integer(I4P)            :: i, k, unit                                  !< Counters, output unit.
integer(I4P), parameter :: n_v = 41_I4P                                !< Number of samples (log-spaced 0.1..3).
real(R8P),    parameter :: z_a(3) = [1._R8P, 2._R8P, 6._R8P]           !< Charge states: p, alpha, C6+.
real(R8P),    parameter :: m_a(3) = [m_proton, m_alpha, m_carbon12]    !< Masses.

unit = open_results('fig2.dat', 'v_a/v_Te j_ratio_proton j_ratio_alpha j_ratio_carbon')
par%z_i = 1._R8P
do i = 1_I4P, n_v
   v = 0.1_R8P * 30._R8P**(real(i - 1_I4P, R8P) / real(n_v - 1_I4P, R8P))
   do k = 1_I4P, 3_I4P
      par%z_a        = z_a(k)
      par%mass_ratio = m_e / m_a(k)
      par%u_a        = v
      call op%init(par=par, u_max=max(7._R8P, 2.5_R8P * v))
      r = op%response(omega_tau=0._R8P)
      ratio(k) = real(r%j_nu, R8P)
   enddo
   write(unit, '(4ES15.6)') v, ratio
enddo
close(unit)
write(output_unit, '(A)') 'Fig. 2 written to results/fig2.dat'
endprogram appelbe_fig2
