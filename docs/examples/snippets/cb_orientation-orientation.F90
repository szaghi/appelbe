b = [0._R8P, 0._R8P, 1._R8P]
s = [1._R8P, 0._R8P, 1._R8P] / sqrt(2._R8P)        ! flux at 45 degrees to B
r0 = op%response(omega_tau=0._R8P)                 ! along b the electrons are unmagnetised
r  = op%response(omega_tau=1._R8P)
s_par   = dot_product(b, s) * b                    ! (b.s) b
s_perp  = cross(b, cross(s, b))                    ! b x (s x b)
s_wedge = cross(b, s)                              ! b x s
j = real(r0%j_nu) * s_par + real(r%j_nu) * s_perp + aimag(r%j_nu) * s_wedge
print '(A,3F9.4)', 'j0_ea / (Z_a e n_a <v_a>) = ', j
