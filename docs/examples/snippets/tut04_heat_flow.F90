!< Tutorial 4: the electron heat flow driven by 3.45 MeV alphas (Eqs. 33-35), kinetic and algebraic closures.
program tut04_heat_flow
!< Tutorial 4: the electron heat flow driven by 3.45 MeV alphas (Eqs. 33-35), kinetic and algebraic closures.
use appelbe

implicit none
type(kinetic_params)   :: par                !< Physical parameters.
type(kinetic_operator) :: op                 !< Kinetic operator.
type(kinetic_response) :: r                  !< Response.
complex(R8P)           :: j_fit, zeta_fit    !< Algebraic closure.
complex(R8P)           :: q_kin, q_fit       !< Heat flow per unit flux [W s].
real(R8P)              :: te, omega_tau      !< T_e [J], Hall parameter.
integer(I4P)           :: i                  !< Counter.

te = 15._R8P * keV_J                                        ! T_e = 15 keV
par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, te)        ! v_a/v_Te of a 3.45 MeV alpha
call op%init(par=par)
print '(A,F7.4)', 'v_a/v_Te = ', par%u_a
print '(/,A)', ' omega_tau   q_perp kinetic   q_wedge kinetic    q_perp fits     q_wedge fits   [W s keV^-1]'
do i = -2, 2
   omega_tau = 10._R8P**i
   r = op%response(omega_tau=omega_tau)
   call fit_response(par%u_a, omega_tau, j_fit, zeta_fit)  ! Appendix C, interpolated in v_a/v_Te
   ! q / (n_a <v_a>) = (T_e/e) (beta + 5/2) j0_ea + zeta_ea, the complex product of Eqs. (34)-(35)
   q_kin = heat_flow_thermoelectric(te, par%z_a, r%beta(), r%j_nu) + heat_flow_direct(te, r%zeta_nu)
   q_fit = heat_flow_thermoelectric(te, par%z_a, r%beta(), j_fit)  + heat_flow_direct(te, zeta_fit)
   print '(ES10.1,4ES17.4)', omega_tau, q_kin / 15._R8P, q_fit / 15._R8P
enddo
endprogram tut04_heat_flow
