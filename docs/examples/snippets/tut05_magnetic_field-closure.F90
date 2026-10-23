par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, te)
call op%init(par=par)
r = op%response(omega_tau=0._R8P)                     ! unmagnetised
