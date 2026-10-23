!< Fig. 2 (supports Sec. V B): unmagnetised j0_ea / j0_a versus v_a/v_Te for protons, alphas and C6+ in DT.
program appelbe_fig2
!< Fig. 2 (supports Sec. V B): unmagnetised j0_ea / j0_a versus v_a/v_Te for protons, alphas and C6+ in DT.
!<
!< Kinetic solver only (the algebraic fits cover alphas only). Two settings: n_a/n_e = 0 in the operator (the paper's stated
!< n_a << n_e limit) and the paper's own set-up, an isotropic F0 with n_a/n_e = 1e-3 (appelbe_paper). Two samplings:
!< - fig2.dat: dense, log-spaced up to v_a/v_Te = 3 (the carbon beam of Sec. V B at T_e = 1-2 keV);
!< - fig2_samples.dat: the 25 speeds at which the paper computed its Fig. 2 (its curves are straight lines between them),
!<   with three more columns: the paper's set-up on the paper's own grid (appelbe_paper).
!< The v_a/v_Te -> 0 limit is 1 - Z_a/Z_i (Eq. 32).
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_constants,             only : m_e, m_proton, m_alpha, m_carbon12
use appelbe_io,                    only : open_results
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_paper,                 only : paper_n_ratio, paper_fig2_samples, paper_fig2_speed, init_paper

implicit none
type(kinetic_params)    :: par                                         !< Physical parameters.
integer(I4P)            :: i, unit                                     !< Counter, output unit.
integer(I4P), parameter :: n_v = 61_I4P                                !< Number of dense samples (log-spaced 0.1..3).
real(R8P),    parameter :: z_a(3) = [1._R8P, 2._R8P, 6._R8P]           !< Charge states: p, alpha, C6+.
real(R8P),    parameter :: m_a(3) = [m_proton, m_alpha, m_carbon12]    !< Masses.
character(len=*), parameter :: header = 'v_a/v_Te proton alpha carbon (n_a/n_e = 0) proton alpha carbon (n_a/n_e = 1e-3)'

par%z_i = 1._R8P
unit = open_results('fig2.dat', header)
do i = 1_I4P, n_v
   call write_row(unit, 0.1_R8P * 30._R8P**(real(i - 1_I4P, R8P) / real(n_v - 1_I4P, R8P)), .false.)
enddo
close(unit)
unit = open_results('fig2_samples.dat', header//' proton alpha carbon (n_a/n_e = 1e-3, paper grid)')
do i = 1_I4P, paper_fig2_samples
   call write_row(unit, paper_fig2_speed(i), .true.)
enddo
close(unit)
write(output_unit, '(A)') 'Fig. 2 written to results/fig2.dat, results/fig2_samples.dat'
contains
   subroutine write_row(unit, v, paper_grid)
   !< j0_ea / j0_a at v_a/v_Te = v for the three species and both settings (and on the paper's grid).
   integer(I4P), intent(in) :: unit       !< Output unit.
   real(R8P),    intent(in) :: v          !< v_a / v_Te.
   logical,      intent(in) :: paper_grid !< Also compute the paper's set-up on the paper's grid.
   type(kinetic_operator)   :: op         !< Kinetic operator.
   type(kinetic_response)   :: r          !< Kinetic response.
   real(R8P)                :: ratio(9)   !< j0_ea / j0_a: species x setting.
   integer(I4P)             :: k, l       !< Counters.

   do l = 1_I4P, merge(3_I4P, 2_I4P, paper_grid)
      do k = 1_I4P, 3_I4P
         par%z_a        = z_a(k)
         par%mass_ratio = m_e / m_a(k)
         par%u_a        = v
         par%n_ratio    = merge(0._R8P, paper_n_ratio, l == 1_I4P)
         if (l == 3_I4P) then
            call init_paper(op, par)
         else
            call op%init(par=par, u_max=max(7._R8P, 2.5_R8P * v))
         endif
         r = op%response(omega_tau=0._R8P)
         ratio(3_I4P * (l - 1_I4P) + k) = real(r%j_nu, R8P)
      enddo
   enddo
   if (paper_grid) then
      write(unit, '(10ES16.7)') v, ratio
   else
      write(unit, '(7ES16.7)') v, ratio(1:6)
   endif
   endsubroutine write_row
endprogram appelbe_fig2
