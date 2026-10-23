te = 15._R8P * keV_J                                        ! T_e = 15 keV
par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, te)        ! v_a/v_Te of a 3.45 MeV alpha
call op%init(par=par)
print '(A,F7.4)', 'v_a/v_Te = ', par%u_a
