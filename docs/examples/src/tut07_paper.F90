!< Tutorial 7: the paper's numerics: its set-up and its coarse speed grid, against the converged solution.
program tut07_paper
!< Tutorial 7: the paper's numerics: its set-up and its coarse speed grid, against the converged solution.
!run tut07 ./tut07_paper
use appelbe

implicit none
type(kinetic_params)   :: par   !< Physical parameters.
type(kinetic_operator) :: op    !< Kinetic operator.
type(kinetic_response) :: r     !< Response.
integer(I4P)           :: k     !< Sample.

!region carbon
par%z_i = 1._R8P ; par%z_a = 6._R8P ; par%mass_ratio = m_e / m_carbon12
par%n_ratio = paper_n_ratio                            ! the paper keeps F0 with n_a/n_e = 1e-3
print '(A)', '  v_a/v_Te   converged   paper grid'
do k = 1, 3                                            ! the first three samples of the paper's Fig. 2
   par%u_a = paper_fig2_speed(k)
   call op%init(par=par)                               ! converged: 401 nodes, one on u_a
   r = op%response(omega_tau=0._R8P)
   write(*, '(F10.4,F12.4)', advance='no') par%u_a, real(r%j_nu)
   call init_paper(op, par)                            ! the paper's grid: 199 nodes on [0, 5], none on u_a
   r = op%response(omega_tau=0._R8P)
   print '(F13.4)', real(r%j_nu)
enddo
!endregion carbon
endprogram tut07_paper
