print '(/,A,2F9.4)', 'j_nu = 1 - 4 pi M3 / (Z_a u_flux) = ', &
   1._R8P - 4._R8P * pi * op%moment(f1(:, 1), 3_I4P) / (par%z_a * op%u_flux)
r = op%response(omega_tau=10._R8P)
print '(A,2F9.4)', 'same from response()             = ', r%j_nu
