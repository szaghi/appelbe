par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%n_ratio = 1.e-3_R8P
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, 10._R8P * keV_J)            ! 3.45 MeV alphas at T_e = 10 keV
call maxw%init(par=par, n_nodes=801_I4P)
call bip%init(par=par, n_nodes=801_I4P, electrons=electron_bipolar, electron_params=[0.1_R8P, 2._R8P, 0.25_R8P])
