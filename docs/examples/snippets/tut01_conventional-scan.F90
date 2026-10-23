print '(/,A)', '  omega_tau   beta_perp  beta_wedge  kappa_perp  kappa_wedge'
block
   integer(I4P) :: i
   real(R8P)    :: omega_tau
   do i = -2, 2
      omega_tau = 10._R8P**i
      r = op%response(omega_tau=omega_tau)
      print '(ES11.2,4F12.5)', omega_tau, r%beta(), r%kappa()
   enddo
endblock
