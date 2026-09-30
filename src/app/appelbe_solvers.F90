!< Solver comparison: the (G + i omega tau) complex formulation versus the paper's Appendix B procedure (Eqs. B6-B8).
program appelbe_solvers
!< Solver comparison: the (G + i omega tau) complex formulation versus the paper's Appendix B procedure (Eqs. B6-B8).
!<
!< Alphas in DT at v_a/v_Te = 0.5 (electric, thermal and fast-ion drives). For each grid size and Hall parameter:
!< relative differences of sigma, K, j_nu, zeta_nu between the methods, relative residuals of both solutions in the
!< first-order system (G + i omega tau) f1 = g7, and CPU time per response. Also writes the grid convergence of the
!< complex method against the finest grid.
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_constants,             only : m_e, m_alpha
use appelbe_io,                    only : open_results
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response, method_complex, method_paper

implicit none
type(kinetic_params)      :: par                   !< Physical parameters.
type(kinetic_operator)    :: op                    !< Kinetic operator.
type(kinetic_response)    :: rc, rp, ref(7)        !< Responses: complex, paper, finest-grid reference.
real(R8P), allocatable    :: rhs(:,:)              !< Sources.
complex(R8P), allocatable :: f1(:,:)               !< Solutions.
real(R8P)                 :: res_c, res_p          !< Max relative residuals.
real(R8P)                 :: t0, t1, t_c, t_p      !< CPU times.
integer(I4P)              :: k, i, unit, unit_conv !< Counters, output units.
integer(I4P), parameter   :: nodes(4) = [201_I4P, 401_I4P, 801_I4P, 1601_I4P] !< Grid sizes.
real(R8P),    parameter   :: omega_tau(7) = [0._R8P, 1.e-2_R8P, 1.e-1_R8P, 1._R8P, 1.e1_R8P, 1.e2_R8P, 1.e3_R8P] !< Hall.

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%u_a = 0.5_R8P
unit      = open_results('solvers.dat', 'nodes omega_tau dsigma dK dj dzeta res_complex res_paper t_complex t_paper')
unit_conv = open_results('convergence.dat', 'nodes omega_tau dsigma dK dj dzeta (complex method vs 1601 nodes)')
write(output_unit, '(A)') 'Solver comparison (alphas in DT, v_a/v_Te = 0.5): relative differences complex vs paper'
write(output_unit, '(A)') '  nodes  omega_tau     dsigma         dK         dj      dzeta   res_cplx  res_paper  t_c[s]  t_p[s]'

! finest grid first: reference for the convergence table
call op%init(par=par, n_nodes=nodes(4))
do i = 1_I4P, size(omega_tau, kind=I4P)
   ref(i) = op%response(omega_tau=omega_tau(i))
enddo

do k = 1_I4P, size(nodes, kind=I4P)
   call op%init(par=par, n_nodes=nodes(k))
   allocate(rhs(nodes(k), 3))
   rhs(:, 1) = op%source_electric()
   rhs(:, 2) = op%source_thermal()
   rhs(:, 3) = op%source_fast_flux()
   do i = 1_I4P, size(omega_tau, kind=I4P)
      call cpu_time(t0) ; rc = op%response(omega_tau=omega_tau(i), method=method_complex) ; call cpu_time(t1)
      t_c = t1 - t0
      call cpu_time(t0) ; rp = op%response(omega_tau=omega_tau(i), method=method_paper)   ; call cpu_time(t1)
      t_p = t1 - t0
      f1    = op%solve(omega_tau=omega_tau(i), rhs=rhs)
      res_c = maxval(op%residual(omega_tau=omega_tau(i), rhs=rhs, f1=f1))
      f1    = op%solve_paper(omega_tau=omega_tau(i), rhs=rhs)
      res_p = maxval(op%residual(omega_tau=omega_tau(i), rhs=rhs, f1=f1))
      write(unit, '(I6,9ES13.4)') nodes(k), omega_tau(i), rel_diffs(rc, rp), res_c, res_p, t_c, t_p
      write(output_unit, '(I7,ES11.2,6ES11.2,2F8.3)') nodes(k), omega_tau(i), rel_diffs(rc, rp), res_c, res_p, t_c, t_p
      if (k < size(nodes, kind=I4P)) write(unit_conv, '(I6,5ES13.4)') nodes(k), omega_tau(i), rel_diffs(rc, ref(i))
   enddo
   deallocate(rhs)
enddo
close(unit)
close(unit_conv)

contains
   pure function rel_diffs(a, b) result(d)
   !< Relative differences |a - b| / |b| of (sigma, K, j_nu, zeta_nu).
   type(kinetic_response), intent(in) :: a    !< First response.
   type(kinetic_response), intent(in) :: b    !< Second response (reference).
   real(R8P)                          :: d(4) !< Relative differences.

   d = [abs(a%sigma - b%sigma) / abs(b%sigma),                                     &
        abs(a%thermal_diffusion - b%thermal_diffusion) / abs(b%thermal_diffusion), &
        abs(a%j_nu - b%j_nu) / abs(b%j_nu),                                        &
        abs(a%zeta_nu - b%zeta_nu) / abs(b%zeta_nu)]
   endfunction rel_diffs
endprogram appelbe_solvers
