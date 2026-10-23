call read_table('f0.dat', x, f)                                     ! two columns, '#' comments
par%z_i = 1._R8P
call op%init(par=par, n_nodes=801_I4P, electrons=electron_table, electron_params=electron_table_params(x, f))
r = op%response(omega_tau=0._R8P)
print '(A,I0,A,F8.4,A,F8.4)', 'table of ', size(x), ' rows: T_TS = ', ts_temperature(op, 2._R8P), &
                              ',  T_kin = ', kinetic_temperature(op)
print '(A,F8.4,A,F8.4)', 'sigma = ', real(r%sigma), ',  kappa = ', real(r%kappa())
