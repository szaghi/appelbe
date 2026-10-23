u_c = (0.75_R8P * sqrt_pi * m_e / m_DT)**(1._R8P / 3._R8P)     ! classical critical speed in DT
par%u_a = 1._R8P                                               ! birth speed, on a node
call broad%init(par=par, n_nodes=801_I4P, u_max=6._R8P, distribution=slowing_down, shape_params=[1._R8P, u_c])
par%u_a = broad%u_energy
call mono%init(par=par, n_nodes=801_I4P)
rb = broad%response(omega_tau=0._R8P)
rm = mono%response(omega_tau=0._R8P)
print '(/,A,F7.4)', 'slowing-down, born at v_Te:  u_energy = ', broad%u_energy
print '(A,F8.4,A,F8.4)', '   zeta_nu broad = ', real(rb%zeta_nu), ',  monoenergetic = ', real(rm%zeta_nu)
