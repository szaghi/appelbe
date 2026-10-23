par%u_a = 0.5_R8P                                      ! reference speed (a node is aligned with it)
call broad%init(par=par, n_nodes=801_I4P, distribution=energy_gaussian, shape_params=[0.5_R8P, 0.4_R8P])
par%u_a = broad%u_energy                               ! the speed of the mean energy
call mono%init(par=par, n_nodes=801_I4P)
rb = broad%response(omega_tau=0._R8P)
rm = mono%response(omega_tau=0._R8P)
print '(A,F7.4,A,F7.4)', 'Gaussian, sigma_E/E = 0.4:  u_energy = ', broad%u_energy, ',  u_flux = ', broad%u_flux
print '(A,F8.4,A,F8.4)', '   j_nu broad = ', real(rb%j_nu), ',  monoenergetic = ', real(rm%j_nu)
