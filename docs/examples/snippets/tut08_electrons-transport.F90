rm = maxw%response(omega_tau=0._R8P)
rb = bip%response(omega_tau=0._R8P)
print '(/,A)', 'relative change against the Maxwellian, omega tau = 0:'
print '(A,F8.4,A,F8.4)', '   sigma ', real(rb%sigma / rm%sigma) - 1, '   kappa   ', real(rb%kappa() / rm%kappa()) - 1
print '(A,F8.4,A,F8.4)', '   j_nu  ', real(rb%j_nu / rm%j_nu) - 1,   '   zeta_nu ', real(rb%zeta_nu / rm%zeta_nu) - 1
print '(A,F8.4)', 'Onsager tau / (mu - 3/2 sigma) - 1: ', real(rb%tau / (rb%mu - 1.5_R8P * rb%sigma)) - 1
