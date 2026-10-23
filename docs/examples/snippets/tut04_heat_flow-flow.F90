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
