!< Cookbook: the electron f1 itself, and its moments (Eqs. 16-17).
program cb_f1
!< Cookbook: the electron f1 itself, and its moments (Eqs. 16-17).
!run cb_f1 ./cb_f1
use appelbe

implicit none
type(kinetic_params)      :: par     !< Physical parameters.
type(kinetic_operator)    :: op      !< Kinetic operator.
type(kinetic_response)    :: r       !< Response.
real(R8P), allocatable    :: rhs(:,:) !< Source g7 of a unit fast-ion flux.
complex(R8P), allocatable :: f1(:,:) !< Solution on the grid, (perp, wedge).
integer(I4P)              :: j       !< Node.

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%u_a = 0.4863_R8P
call op%init(par=par, n_nodes=801_I4P)
!region solve
rhs = reshape(op%source_fast_flux(), [op%grid%n, 1])   ! one right-hand side, on the full grid
f1  = op%solve(omega_tau=10._R8P, rhs=rhs)            ! (G + i wt) f1 = g7, f1 = f1x + i f1y
!endregion solve
print '(A)', '        u     f1_perp      f1_wedge'
do j = 1, op%grid%n, 80
   print '(F9.3,2ES13.4)', op%grid%u(j), f1(j, 1)
enddo
!region moments
print '(/,A,2F9.4)', 'j_nu = 1 - 4 pi M3 / (Z_a u_flux) = ', &
   1._R8P - 4._R8P * pi * op%moment(f1(:, 1), 3_I4P) / (par%z_a * op%u_flux)
r = op%response(omega_tau=10._R8P)
print '(A,2F9.4)', 'same from response()             = ', r%j_nu
!endregion moments
endprogram cb_f1
