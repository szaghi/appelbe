u = advection_velocity(par%z_a, 1.e-3_R8P, 1.e7_R8P, r%j_nu)   ! n_a/n_e = 1e-3, <v_a> = 1e7 m/s (Eq. 40)
print '(A,2ES11.3,A)', 'advection velocity (perp, wedge) = ', u, ' m/s'
