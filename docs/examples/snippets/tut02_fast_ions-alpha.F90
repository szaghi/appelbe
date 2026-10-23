par%z_i        = 1._R8P            ! DT, average ion
par%z_a        = 2._R8P            ! alpha particles
par%mass_ratio = m_e / m_alpha
par%u_a        = 0.5_R8P           ! v_a / v_Te
call op%init(par=par)              ! a node is placed exactly on u_a
r = op%response(omega_tau=0._R8P)
print '(A,F8.4)', 'j0_ea / j0_a                 = ', real(r%j_nu)
print '(A,F8.4)', 'zeta_ea / (n_a <v_a> T_e)    = ', real(r%zeta_nu)
