flux = 1.e34_R8P                                       ! alpha flux n_a <v_a>
j0   = par%z_a * e_charge * flux * real(r%j_nu)        ! j0_ea (Eq. C1)
coef = resistive_coefficient(te, 1._R8P, lnl, real(r%resistivity()))
rate = field_generation_rate(coef, abs(j0) / 1.e-5_R8P, j0, te, 1._R8P * keV_J / 1.e-6_R8P)
print '(A,ES10.3,A)', 'j0_ea = ', j0, ' A/m^2'
print '(A,ES10.3,A)', 'dB/dt (Eq. 43, 10 um, 1 keV/um) = ', rate, ' T/s'
