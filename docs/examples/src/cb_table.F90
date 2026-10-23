!< Cookbook: a dense closure table j_nu(v, wt), zeta_nu(v, wt) for an MHD code, regenerated with the kinetic solver.
program cb_table
!< Cookbook: a dense closure table j_nu(v, wt), zeta_nu(v, wt) for an MHD code, regenerated with the kinetic solver.
!run cb_table ./cb_table && head -4 closure_table.dat && wc -l closure_table.dat
use appelbe

implicit none
type(kinetic_params)    :: par         !< Physical parameters.
type(kinetic_operator)  :: op          !< Kinetic operator.
type(kinetic_response)  :: r           !< Response.
integer(I4P)            :: iv, ix, unit !< Counters, output unit.
real(R8P)               :: v, x        !< v_a/v_Te, log10(omega tau).
integer(I4P), parameter :: n_v = 31, n_x = 25 !< Table size.

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
open(newunit=unit, file='closure_table.dat', status='replace', action='write')
write(unit, '(A)') '# v_a/v_Te log10(wt) j_perp j_wedge zeta_perp zeta_wedge'
do iv = 1, n_v
   v = 0.1_R8P * 30._R8P**(real(iv - 1, R8P) / real(n_v - 1, R8P))     ! 0.1 ... 3, log-spaced
   par%u_a = v
   call op%init(par=par, u_max=max(7._R8P, 2.5_R8P * v))
   do ix = 1, n_x
      x = -3._R8P + 6._R8P * real(ix - 1, R8P) / real(n_x - 1, R8P)
      r = op%response(omega_tau=10._R8P**x)
      write(unit, '(2F9.4,4ES15.6)') v, x, r%j_nu, r%zeta_nu
   enddo
enddo
close(unit)
endprogram cb_table
