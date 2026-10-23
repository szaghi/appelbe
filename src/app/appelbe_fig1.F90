!< Fig. 1 (Sec. III C): the electron f1 driven by electron-alpha collisions, unmagnetised and magnetised.
program appelbe_fig1
!< Fig. 1 (Sec. III C): the electron f1 driven by electron-alpha collisions, unmagnetised and magnetised.
!<
!< 3.45 MeV alphas in DT at T_e = 2 keV (v_a/v_Te = 0.486; the paper writes 0.48), unit fast-ion flux. Like the paper, each
!< curve is normalised by its own maximum: f0, f1 at omega tau = 0, and the perp (along the flux) and wedge (along b x flux)
!< components of f1 at omega tau = 10. fig1.dat is the converged solution; fig1_paper.dat repeats it on the paper's own
!< grid (appelbe_paper), whose O(h) error is what deepens the negative lobe of f1_perp in the paper's figure.
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_constants,             only : m_e, m_alpha, keV_J, MeV_J
use appelbe_io,                    only : open_results
use appelbe_kinetic,               only : kinetic_params, kinetic_operator
use appelbe_paper,                 only : paper_n_ratio, init_paper
use appelbe_plasma,                only : speed_ratio

implicit none
type(kinetic_params)    :: par                       !< Physical parameters.
real(R8P)               :: u_nominal                 !< v_a/v_Te at 2 keV.
integer(I4P)            :: unit                      !< Output unit.
integer(I4P), parameter :: n_nodes = 801_I4P         !< Speed nodes of the converged solution.

par%z_i        = 1._R8P
par%z_a        = 2._R8P
par%mass_ratio = m_e / m_alpha
par%n_ratio    = paper_n_ratio
u_nominal = speed_ratio(3.45_R8P * MeV_J, m_alpha, 2._R8P * keV_J)

par%u_a = u_nominal
unit = open_results('fig1.dat', 'u f0 f1_wt0 f1perp_wt10 f1wedge_wt10 (each normalised by its maximum)')
call write_curves(unit, .false.)
close(unit)
unit = open_results('fig1_paper.dat', 'u f0 f1_wt0 f1perp_wt10 f1wedge_wt10 (paper grid, each normalised by its maximum)')
call write_curves(unit, .true.)
close(unit)
write(output_unit, '(A)') 'Fig. 1 written to results/fig1.dat, results/fig1_paper.dat'
contains
   subroutine write_curves(unit, paper_grid)
   !< Solve for the unit-flux f1 at omega tau = 0 and 10 and write the normalised curves for u <= 3.
   integer(I4P), intent(in) :: unit       !< Output unit.
   logical,      intent(in) :: paper_grid !< Use the paper's grid instead of the converged one.
   type(kinetic_operator)   :: op     !< Kinetic operator.
   real(R8P), allocatable   :: rhs(:,:), f(:,:) !< Source, normalised curves (f0, f1_wt0, f1perp, f1wedge).
   complex(R8P), allocatable:: f1(:,:) !< Solution.
   integer(I4P)             :: j, i   !< Counters.

   if (paper_grid) then
      call init_paper(op, par)
   else
      call op%init(par=par, n_nodes=n_nodes)
   endif
   rhs = reshape(op%source_fast_flux(), [op%grid%n, 1])
   allocate(f(op%grid%n, 4))
   f(:, 1) = exp(-op%grid%u**2)
   f1 = op%solve(omega_tau=0._R8P, rhs=rhs)
   f(:, 2) = real(f1(:, 1), R8P)
   f1 = op%solve(omega_tau=10._R8P, rhs=rhs)
   f(:, 3) = real(f1(:, 1), R8P)
   f(:, 4) = aimag(f1(:, 1))
   do i = 1_I4P, 4_I4P
      f(:, i) = f(:, i) / maxval(f(:, i))
   enddo
   do j = 1_I4P, op%grid%n
      if (op%grid%u(j) > 3._R8P) exit
      write(unit, '(5ES16.7)') op%grid%u(j), f(j, :)
   enddo
   endsubroutine write_curves
endprogram appelbe_fig1
