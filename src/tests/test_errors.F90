!< Inputs the library rejects: stat and errmsg instead of a stop, for interactive callers (the GUI, issue #2).
program test_errors
!< Inputs the library rejects: stat and errmsg instead of a stop, for interactive callers (the GUI, issue #2).
!<
!< Each rejected input of kinetic_operator%init, read_table and electron_table_check returns stat = 1 (or a message)
!< with a message naming the cause; a valid input returns stat = 0 and an empty message, and the operator it builds
!< gives the same response as one built without stat (bit for bit). test_xfail_init_stop checks that the default
!< (stat absent) still stops.
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_assert,                only : assert_close, assert_summary
use appelbe_constants,             only : m_e, m_alpha, keV_J, MeV_J
use appelbe_distributions,         only : electron_maxwellian, electron_bipolar, electron_table_check, energy_gaussian
use appelbe_io,                    only : read_table
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_plasma,                only : speed_ratio

implicit none
type(kinetic_params)          :: par      !< Physical parameters.
type(kinetic_operator)        :: op, oq   !< Operators: with stat, without.
type(kinetic_response)        :: rp, rq   !< Their responses.
integer(I4P)                  :: stat     !< Status.
character(len=:), allocatable :: msg      !< Message.
real(R8P), allocatable        :: x(:), y(:) !< A table.
integer(I4P)                  :: unit     !< Scratch file unit.
character(len=*), parameter   :: scratch = 'test_errors_table.tmp' !< Scratch table.

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%n_ratio = 1.e-3_R8P
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, 10._R8P * keV_J)

! kinetic_operator%init
call op%init(par=par, n_nodes=400_I4P, stat=stat, errmsg=msg)
call check('init: even n_nodes', stat == 1_I4P .and. index(msg, 'odd') > 0)
call op%init(par=par, n_nodes=5_I4P, stat=stat, errmsg=msg)
call check('init: n_nodes < 7', stat == 1_I4P .and. index(msg, 'odd and >= 7') > 0)
call op%init(par=par, u_max=-1._R8P, stat=stat, errmsg=msg)
call check('init: u_max <= 0', stat == 1_I4P .and. index(msg, 'u_max must be positive') > 0)
call op%init(par=with_u_a(1.e-4_R8P), n_nodes=401_I4P, stat=stat, errmsg=msg)
call check('init: u_a far below one cell (aligned)', stat == 1_I4P .and. index(msg, 'under-resolved') > 0)
call op%init(par=with_u_a(0.04_R8P), n_nodes=401_I4P, stat=stat, errmsg=msg)
call check('init: u_a < 4 h (aligned)', stat == 1_I4P .and. index(msg, 'under-resolved') > 0)
call op%init(par=with_u_a(8._R8P), n_nodes=401_I4P, stat=stat, errmsg=msg)
call check('init: u_a beyond the grid', stat == 1_I4P .and. index(msg, 'beyond the grid') > 0)
call op%init(par=par, n_nodes=401_I4P, electrons=electron_bipolar, electron_params=[-2._R8P, 2._R8P, 0.25_R8P], &
             stat=stat, errmsg=msg)
call check('init: negative electron f0 (bipolar, A = -2)', stat == 1_I4P .and. index(msg, 'negative') > 0)
call op%init(par=par, n_nodes=401_I4P, electrons=electron_maxwellian, electron_params=[50._R8P], stat=stat, errmsg=msg)
call check('init: electron f0 not vanishing at u_max', stat == 1_I4P .and. index(msg, 'electron distribution does not vanish') > 0)
call op%init(par=with_u_a(6.5_R8P), n_nodes=401_I4P, distribution=energy_gaussian, shape_params=[6.5_R8P, 0.3_R8P], &
             stat=stat, errmsg=msg)
call check('init: fast-ion F not vanishing at u_max', stat == 1_I4P .and. index(msg, 'fast-ion distribution does not vanish') > 0)
call op%init(par=par, n_nodes=401_I4P, stat=stat) ! stat without errmsg
call check('init: valid input, stat only', stat == 0_I4P)

! a valid input with stat gives the operator init builds without it, bit for bit
call op%init(par=par, n_nodes=401_I4P, electrons=electron_bipolar, electron_params=[0.1_R8P, 2._R8P, 0.25_R8P], &
             stat=stat, errmsg=msg)
call check('init: valid input, stat = 0 and no message', stat == 0_I4P .and. len(msg) == 0)
call oq%init(par=par, n_nodes=401_I4P, electrons=electron_bipolar, electron_params=[0.1_R8P, 2._R8P, 0.25_R8P])
rp = op%response(omega_tau=1._R8P) ; rq = oq%response(omega_tau=1._R8P)
call check('init with stat: the same response bit for bit', &
           rp%sigma == rq%sigma .and. rp%mu == rq%mu .and. rp%j_nu == rq%j_nu .and. rp%zeta_nu == rq%zeta_nu)
! a rejected input leaves the object reusable: a valid init afterwards works
call op%init(par=par, n_nodes=400_I4P, stat=stat)
call op%init(par=par, n_nodes=401_I4P, electrons=electron_bipolar, electron_params=[0.1_R8P, 2._R8P, 0.25_R8P], &
             stat=stat, errmsg=msg)
rp = op%response(omega_tau=1._R8P)
call check('init after a rejected init: same response', stat == 0_I4P .and. rp%sigma == rq%sigma .and. rp%j_nu == rq%j_nu)

! read_table
call read_table('no/such/file.dat', x, y, stat=stat, errmsg=msg)
call check('read_table: missing file', stat == 1_I4P .and. index(msg, 'read_table:') > 0 .and. .not. allocated(x))
open(newunit=unit, file=scratch, status='replace', action='write')
write(unit, '(A)') '# u_L f0', '0 1', '0.5 0.8', 'oops', '1 0.6'
close(unit)
call read_table(scratch, x, y, stat=stat, errmsg=msg)
call check('read_table: a line without two numbers, named', stat == 1_I4P .and. index(msg, 'line 4') > 0 &
           .and. .not. allocated(x))
open(newunit=unit, file=scratch, status='replace', action='write')
write(unit, '(A)') '# only comments', ''
close(unit)
call read_table(scratch, x, y, stat=stat, errmsg=msg)
call check('read_table: no data line', stat == 1_I4P .and. index(msg, 'no data line') > 0)
open(newunit=unit, file=scratch, status='replace', action='write')
write(unit, '(A)') '# u_L f0', '0 1', '', '0.5 0.8   extra columns ignored', '1 0.6'
close(unit)
call read_table(scratch, x, y, stat=stat, errmsg=msg)
call check('read_table: valid table, stat = 0', stat == 0_I4P .and. len(msg) == 0 .and. size(x) == 3)
call assert_close('read_table: values', sum(abs(x - [0._R8P, 0.5_R8P, 1._R8P])) + sum(abs(y - [1._R8P, 0.8_R8P, 0.6_R8P])), &
                  0._R8P, rel_tol=0._R8P, abs_tol=1.e-15_R8P)
open(newunit=unit, file=scratch, status='old')
close(unit, status='delete')

! electron_table_check
call check('table check: valid',             len(electron_table_check([0._R8P, 1._R8P, 2._R8P], [1._R8P, .5_R8P, .1_R8P])) == 0)
call check('table check: two nodes',         index(electron_table_check([0._R8P, 1._R8P], [1._R8P, .5_R8P]), 'n >= 3') > 0)
call check('table check: sizes differ',      index(electron_table_check([0._R8P, 1._R8P, 2._R8P], [1._R8P, .5_R8P]), 'n >= 3') > 0)
call check('table check: x(1) /= 0',         index(electron_table_check([.1_R8P, 1._R8P, 2._R8P], [1._R8P, .5_R8P, .1_R8P]), &
                                                   'increasing') > 0)
call check('table check: not increasing',    index(electron_table_check([0._R8P, 1._R8P, 1._R8P], [1._R8P, .5_R8P, .1_R8P]), &
                                                   'increasing') > 0)
call check('table check: f <= 0',            index(electron_table_check([0._R8P, 1._R8P, 2._R8P], [1._R8P, 0._R8P, .1_R8P]), &
                                                   'positive') > 0)
call assert_summary()

contains
   function with_u_a(u_a) result(p)
   !< par with another fast-ion speed.
   real(R8P), intent(in) :: u_a !< v_a / v_Te.
   type(kinetic_params)  :: p   !< Parameters.

   p = par
   p%u_a = u_a
   endfunction with_u_a

   subroutine check(label, ok)
   !< A logical check, through assert_close (1 expected).
   character(*), intent(in) :: label !< What is checked.
   logical,      intent(in) :: ok    !< Outcome.

   call assert_close(label, merge(1._R8P, 0._R8P, ok), 1._R8P, rel_tol=0._R8P)
   if (.not. ok .and. allocated(msg)) write(output_unit, '(A)') '      message: '//msg
   endsubroutine check
endprogram test_errors
