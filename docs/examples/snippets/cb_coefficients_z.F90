!< Cookbook: conventional coefficients for any ion charge, up to the Lorentz limit.
program cb_coefficients_z
!< Cookbook: conventional coefficients for any ion charge, up to the Lorentz limit.
use appelbe

implicit none
type(kinetic_params)   :: par !< Physical parameters.
type(kinetic_operator) :: op  !< Kinetic operator.
type(kinetic_response) :: r   !< Response.
integer(I4P)           :: k   !< Counter.
real(R8P), parameter   :: z(5) = [1._R8P, 2._R8P, 4._R8P, 16._R8P, 1.e6_R8P] !< Ion charges (1e6 ~ Lorentz gas).

print '(A)', '       Z_i   alpha_par    beta_par   kappa_par'
do k = 1, size(z)
   par%z_i = z(k)
   call op%init(par=par)
   r = op%response(omega_tau=0._R8P)
   print '(ES10.2,3F12.5)', z(k), real(r%resistivity()), real(r%beta()), real(r%kappa())
enddo
print '(A,3F12.5)', '   Lorentz', 3._R8P * pi / 32._R8P, 1.5_R8P, 128._R8P / (3._R8P * pi)
endprogram cb_coefficients_z
