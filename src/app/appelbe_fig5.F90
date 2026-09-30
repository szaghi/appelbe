!< Fig. 5 (Sec. IV B): heat flow from electron-alpha collisions versus omega tau, flux orthogonal to B (Eqs. 34-35).
program appelbe_fig5
!< Fig. 5 (Sec. IV B): heat flow from electron-alpha collisions versus omega tau, flux orthogonal to B (Eqs. 34-35).
!<
!< Monoenergetic 3.45 MeV alphas in DT at T_e = 1 and 15 keV, uniform B (j_T = 0). Heat flows are normalised by the alpha
!< flux and by T_e in keV [W s keV^-1]. The closure comes from the kinetic solver and from the algebraic fits; beta_perp and
!< beta_wedge always come from the kinetic solver.
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_closure,               only : heat_flow_thermoelectric, heat_flow_direct
use appelbe_constants,             only : m_e, m_alpha, keV_J, MeV_J
use appelbe_fits,                  only : fit_response
use appelbe_io,                    only : open_results
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_plasma,                only : speed_ratio

implicit none
type(kinetic_params)    :: par                           !< Physical parameters.
type(kinetic_operator)  :: op                            !< Kinetic operator.
type(kinetic_response)  :: r                             !< Kinetic response.
complex(R8P)            :: j_fit, zeta_fit               !< Algebraic closure.
complex(R8P)            :: q(2)                          !< Normalised heat flow (perp, wedge), (kinetic, fit).
real(R8P)               :: te, x, omega_tau              !< Electron temperature [J], log10(omega tau), omega tau.
integer(I4P)            :: k, i, unit                    !< Counters, output unit.
integer(I4P), parameter :: n_x = 61_I4P                  !< Number of omega tau samples.
real(R8P),    parameter :: e_alpha = 3.45_R8P * MeV_J    !< Alpha energy [J].
real(R8P),    parameter :: te_keV(2) = [1._R8P, 15._R8P] !< Electron temperatures [keV].
character(len=32)       :: file_name                     !< Output file.

par%z_i        = 1._R8P
par%z_a        = 2._R8P
par%mass_ratio = m_e / m_alpha
do k = 1_I4P, size(te_keV, kind=I4P)
   te      = te_keV(k) * keV_J
   par%u_a = speed_ratio(e_alpha, m_alpha, te)
   call op%init(par=par)
   write(file_name, '(A,I2.2,A)') 'fig5_Te', nint(te_keV(k)), 'keV.dat'
   unit = open_results(file_name, 'x q_perp_kin q_wedge_kin q_perp_fit q_wedge_fit beta_perp beta_wedge')
   do i = 1_I4P, n_x
      x         = -3._R8P + 6._R8P * real(i - 1_I4P, R8P) / real(n_x - 1_I4P, R8P)
      omega_tau = 10._R8P**x
      r = op%response(omega_tau=omega_tau)
      call fit_response(par%u_a, omega_tau, j_fit, zeta_fit)
      q = (heat_flow_thermoelectric(te, par%z_a, r%beta(), [r%j_nu, j_fit]) + &
           heat_flow_direct(te, [r%zeta_nu, zeta_fit])) / te_keV(k)
      write(unit, '(7ES15.6)') x, q(1), q(2), r%beta()
   enddo
   close(unit)
   write(output_unit, '(A)') 'Fig. 5 written to results/'//trim(file_name)
enddo
endprogram appelbe_fig5
