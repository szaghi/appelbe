!< Cookbook: an electron f0 given as a table (e.g. from INDACO), read from a file.
program cb_electron_table
!< Cookbook: an electron f0 given as a table (e.g. from INDACO), read from a file.
use appelbe

implicit none
type(kinetic_params)   :: par    !< Physical parameters.
type(kinetic_operator) :: op     !< Kinetic operator.
type(kinetic_response) :: r      !< Response.
real(R8P), allocatable :: x(:), f(:) !< Table: u_L = p / sqrt(m_e T_e), f0.
integer(I4P)           :: k, unit !< Counter, output unit.

! a table to read: a Maxwellian with a 20% tail beyond u_L = 3 (any normalisation)
open(newunit=unit, file='f0.dat', status='replace', action='write')
write(unit, '(A)') '# u_L f0'
do k = 0_I4P, 600_I4P
   write(unit, '(2ES24.15)') 0.02_R8P * k, exp(-0.5_R8P * (0.02_R8P * k)**2) * (1._R8P + 0.2_R8P / (1._R8P + &
                             exp(-(0.02_R8P * k - 3._R8P) / 0.2_R8P)))
enddo
close(unit)
call read_table('f0.dat', x, f)                                     ! two columns, '#' comments
par%z_i = 1._R8P
call op%init(par=par, n_nodes=801_I4P, electrons=electron_table, electron_params=electron_table_params(x, f))
r = op%response(omega_tau=0._R8P)
print '(A,I0,A,F8.4,A,F8.4)', 'table of ', size(x), ' rows: T_TS = ', ts_temperature(op, 2._R8P), &
                              ',  T_kin = ', kinetic_temperature(op)
print '(A,F8.4,A,F8.4)', 'sigma = ', real(r%sigma), ',  kappa = ', real(r%kappa())
endprogram cb_electron_table
