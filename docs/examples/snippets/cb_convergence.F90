!< Cookbook: check grid convergence of a result before trusting it.
program cb_convergence
!< Cookbook: check grid convergence of a result before trusting it.
use appelbe

implicit none
type(kinetic_params)   :: par  !< Physical parameters.
type(kinetic_operator) :: op   !< Kinetic operator.
type(kinetic_response) :: r    !< Response.
complex(R8P)           :: ref  !< Finest-grid value.
integer(I4P)           :: k    !< Counter.
integer(I4P), parameter :: n(4) = [201, 401, 801, 1601] !< Grids.

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%u_a = 0.5_R8P
call op%init(par=par, n_nodes=n(4))
r = op%response(omega_tau=1._R8P)
ref = r%j_nu
print '(A)', '     N   |j_nu - j_nu(1601)| / |j_nu(1601)|'
do k = 1, 3
   call op%init(par=par, n_nodes=n(k))
   r = op%response(omega_tau=1._R8P)
   print '(I6,ES14.3)', n(k), abs(r%j_nu - ref) / abs(ref)
enddo
endprogram cb_convergence
