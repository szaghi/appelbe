!< Fig. 4 (Sec. IV A): heat flow from electron-alpha collisions in an unmagnetised DT plasma versus T_e (Eq. 33).
program appelbe_fig4
!< Fig. 4 (Sec. IV A): heat flow from electron-alpha collisions in an unmagnetised DT plasma versus T_e (Eq. 33).
!<
!< Monoenergetic 3.45 MeV alphas. Heat flows are normalised by the alpha flux n_a <v_a> [W s]. The closure (j_nu, zeta_nu)
!< comes both from the kinetic solver, in the paper's set-up (isotropic F0 with n_a/n_e = 1e-3, appelbe_paper), and from
!< the algebraic fits; beta_par always comes from the kinetic solver. The last three columns repeat the kinetic closure on
!< the paper's own grid (appelbe_paper).
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
type(kinetic_params)    :: par                        !< Physical parameters.
type(kinetic_operator)  :: op                         !< Kinetic operator.
type(kinetic_response)  :: r, rp                      !< Kinetic responses: converged, paper's grid.
complex(R8P)            :: j_fit, zeta_fit            !< Algebraic closure.
complex(R8P)            :: beta                       !< Thermoelectric coefficient (unmagnetised: real).
real(R8P)               :: te_keV, te                 !< Electron temperature [keV], [J].
real(R8P)               :: q_j(3), q_z(3)             !< Thermoelectric and direct heat flows, (kinetic, fit, paper) [W s].
integer(I4P)            :: i, unit                    !< Counter, output unit.
integer(I4P), parameter :: n_te = 57_I4P              !< Number of temperatures (1 to 15 keV).
real(R8P),    parameter :: e_alpha = 3.45_R8P * MeV_J !< Alpha energy [J].

par%z_i        = 1._R8P
par%z_a        = 2._R8P
par%mass_ratio = m_e / m_alpha
par%n_ratio    = paper_n_ratio
unit = open_results('fig4.dat', 'Te_keV q_j_kin q_zeta_kin q_sum_kin q_j_fit q_zeta_fit q_sum_fit beta_par v_a/v_Te '// &
                               'q_j_kin q_zeta_kin q_sum_kin (paper grid)')
do i = 1_I4P, n_te
   te_keV  = 1._R8P + 14._R8P * real(i - 1_I4P, R8P) / real(n_te - 1_I4P, R8P)
   te      = te_keV * keV_J
   par%u_a = speed_ratio(e_alpha, m_alpha, te)
   call op%init(par=par)
   r = op%response(omega_tau=0._R8P)
   call init_paper(op, par)
   rp = op%response(omega_tau=0._R8P)
   call fit_response(par%u_a, 0._R8P, j_fit, zeta_fit)
   beta = r%beta()
   q_j = real(heat_flow_thermoelectric(te, par%z_a, [beta, beta, rp%beta()], [r%j_nu, j_fit, rp%j_nu]), R8P)
   q_z = real(heat_flow_direct(te, [r%zeta_nu, zeta_fit, rp%zeta_nu]), R8P)
   write(unit, '(12ES15.6)') te_keV, q_j(1), q_z(1), q_j(1) + q_z(1), q_j(2), q_z(2), q_j(2) + q_z(2), real(beta, R8P), &
                             par%u_a, q_j(3), q_z(3), q_j(3) + q_z(3)
enddo
close(unit)
write(output_unit, '(A)') 'Fig. 4 written to results/fig4.dat'
endprogram appelbe_fig4
