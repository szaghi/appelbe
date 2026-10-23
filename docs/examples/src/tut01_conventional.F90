!< Tutorial 1: the conventional transport coefficients (no fast ions) from the kinetic solver.
program tut01_conventional
!< Tutorial 1: the conventional transport coefficients (no fast ions) from the kinetic solver.
!run tut01 ./tut01_conventional
!region solve
use appelbe

implicit none
type(kinetic_params)   :: par !< Physical parameters: thermal ions of charge Z_i, no fast ions (u_a = 0).
type(kinetic_operator) :: op  !< The discretised collision operator G of Eq. (13).
type(kinetic_response) :: r   !< Transport coefficients at one Hall parameter.

par%z_i = 1._R8P               ! a hydrogen-like plasma (D, T or DT)
call op%init(par=par)          ! 401 nodes on [0, 7 v_Te], the default grid
r = op%response(omega_tau=0._R8P)
!endregion solve
!region print
print '(A,F8.4)', 'alpha_par (1/sigma)  = ', real(r%resistivity())
print '(A,F8.4)', 'beta_par             = ', real(r%beta())
print '(A,F8.4)', 'kappa_par            = ', real(r%kappa())
!endregion print
!region scan
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
!endregion scan
endprogram tut01_conventional
