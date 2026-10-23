!< Fig. 5 (Sec. IV B): heat flow from electron-alpha collisions versus omega tau, flux orthogonal to B (Eqs. 34-35).
program appelbe_fig5
!< Fig. 5 (Sec. IV B): heat flow from electron-alpha collisions versus omega tau, flux orthogonal to B (Eqs. 34-35).
!<
!< Monoenergetic 3.45 MeV alphas in DT at T_e = 1 and 15 keV, uniform B (j_T = 0). Heat flows are normalised by the alpha
!< flux and by T_e in keV [W s keV^-1]. The closure comes from the kinetic solver, in the paper's set-up (isotropic F0 with
!< n_a/n_e = 1e-3, appelbe_paper), and from the algebraic fits; here beta_perp and beta_wedge come from the kinetic solver.
!< The files also carry j_nu, zeta_nu and beta (converged and on the paper's own grid, appelbe_paper) and the fitted j_nu,
!< zeta_nu, so that the heat flow can be re-formed with other beta: the paper used the Epperlein-Haines fits (see the
!< report and scripts/report_numbers.py).
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_closure,               only : heat_flow_thermoelectric, heat_flow_direct
use appelbe_constants,             only : m_e, m_alpha, keV_J, MeV_J
use appelbe_fits,                  only : fit_response
use appelbe_io,                    only : open_results
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_paper,                 only : paper_n_ratio, init_paper
use appelbe_plasma,                only : speed_ratio

implicit none
type(kinetic_params)    :: par                           !< Physical parameters.
type(kinetic_operator)  :: op, opp                       !< Kinetic operators: converged, paper's grid.
type(kinetic_response)  :: r, rp                         !< Kinetic responses: converged, paper's grid.
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
par%n_ratio    = paper_n_ratio
do k = 1_I4P, size(te_keV, kind=I4P)
   te      = te_keV(k) * keV_J
   par%u_a = speed_ratio(e_alpha, m_alpha, te)
   call op%init(par=par)
   call init_paper(opp, par)
   write(file_name, '(A,I2.2,A)') 'fig5_Te', nint(te_keV(k)), 'keV.dat'
   unit = open_results(file_name, 'x q_perp_kin q_wedge_kin q_perp_fit q_wedge_fit beta_perp beta_wedge '// &
                                  'j_perp j_wedge zeta_perp zeta_wedge j_fit(2) zeta_fit(2) '// &
                                  'j(2) zeta(2) beta(2) (paper grid)')
   do i = 1_I4P, n_x
      x         = -3._R8P + 6._R8P * real(i - 1_I4P, R8P) / real(n_x - 1_I4P, R8P)
      omega_tau = 10._R8P**x
      r  = op%response(omega_tau=omega_tau)
      rp = opp%response(omega_tau=omega_tau)
      call fit_response(par%u_a, omega_tau, j_fit, zeta_fit)
      q = (heat_flow_thermoelectric(te, par%z_a, r%beta(), [r%j_nu, j_fit]) + &
           heat_flow_direct(te, [r%zeta_nu, zeta_fit])) / te_keV(k)
      write(unit, '(21ES15.6)') x, q(1), q(2), r%beta(), r%j_nu, r%zeta_nu, j_fit, zeta_fit, rp%j_nu, rp%zeta_nu, &
                                rp%beta()
   enddo
   close(unit)
   write(output_unit, '(A)') 'Fig. 5 written to results/'//trim(file_name)
enddo
endprogram appelbe_fig5
