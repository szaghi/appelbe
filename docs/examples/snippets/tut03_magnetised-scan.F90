print '(A)', '  log10(wt)     j_perp    j_wedge   zeta_perp  zeta_wedge'
do i = 0, 6
   x = -3._R8P + real(i, R8P)
   r = op%response(omega_tau=10._R8P**x)
   print '(F11.1,4F11.4)', x, r%j_nu, r%zeta_nu        ! complex: (perp, wedge) = (real, imag)
enddo
