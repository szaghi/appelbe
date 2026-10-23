print '(/,A)', '  v_a/v_Te   j_nu (alpha)   zeta_nu (alpha)'
do k = 0, 4
   v = 0.1_R8P * 10._R8P**(0.25_R8P * k)
   par%u_a = v
   call op%init(par=par)
   r = op%response(omega_tau=0._R8P)
   print '(F10.3,2F15.4)', v, real(r%j_nu), real(r%zeta_nu)
enddo
