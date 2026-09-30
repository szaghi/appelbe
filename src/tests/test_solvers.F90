!< The paper's Appendix B procedure (Eqs. B6-B8) and the complex formulation give the same response.
program test_solvers
!< The paper's Appendix B procedure (Eqs. B6-B8) and the complex formulation give the same response.
!<
!< The two are algebraically identical; the paper's squares the operator (GG + Omega^2), so its rounding error is larger
!< (measured ~1e-9 relative at 401 nodes, growing with the grid size). Tolerance 1e-7 at 401 nodes.
use penf,              only : I4P, R8P
use appelbe_assert,    only : assert_close, assert_summary
use appelbe_constants, only : m_e, m_alpha
use appelbe_kinetic,   only : kinetic_params, kinetic_operator, kinetic_response, method_complex, method_paper

implicit none
type(kinetic_params)   :: par    !< Physical parameters.
type(kinetic_operator) :: op     !< Kinetic operator.
type(kinetic_response) :: rc, rp !< Responses: complex, paper.
integer(I4P)           :: k      !< Counter.
character(len=24)      :: label  !< Case label.
real(R8P), parameter   :: omega_tau(4) = [0._R8P, 1.e-2_R8P, 1._R8P, 1.e2_R8P] !< Hall parameters.
real(R8P), parameter   :: tol = 1.e-7_R8P   !< Relative tolerance.
real(R8P), parameter   :: floor = 1.e-9_R8P !< Absolute floor (vanishing wedge components at omega tau = 0).

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%u_a = 0.5_R8P
call op%init(par=par)
do k = 1_I4P, size(omega_tau, kind=I4P)
   write(label, '(A,ES8.1)') 'omega_tau =', omega_tau(k)
   rc = op%response(omega_tau=omega_tau(k), method=method_complex)
   rp = op%response(omega_tau=omega_tau(k), method=method_paper)
   call assert_close(trim(label)//' |sigma|', abs(rp%sigma),             abs(rc%sigma),             tol)
   call assert_close(trim(label)//' |K|',     abs(rp%thermal_diffusion), abs(rc%thermal_diffusion), tol)
   call assert_close(trim(label)//' Re j_nu', real(rp%j_nu, R8P),    real(rc%j_nu, R8P),    tol, floor)
   call assert_close(trim(label)//' Im j_nu', aimag(rp%j_nu),        aimag(rc%j_nu),        tol, floor)
   call assert_close(trim(label)//' Re zeta', real(rp%zeta_nu, R8P), real(rc%zeta_nu, R8P), tol, floor)
   call assert_close(trim(label)//' Im zeta', aimag(rp%zeta_nu),     aimag(rc%zeta_nu),     tol, floor)
enddo
call assert_summary()
endprogram test_solvers
