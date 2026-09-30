!< Appendix C fits: endpoint consistency of every table row and interpolation/clamping behaviour.
program test_fits
!< Appendix C fits: endpoint consistency of every table row and interpolation/clamping behaviour.
!<
!< - x = -3 reproduces the tabulated omega tau = 0 column (to 0.8%; worst row v=0.025: 0.71%), wedges vanish.
!< - x = +3: j_perp -> 1 (electron current suppressed), the other components -> 0.
!< - Spot values at x = 0 for v_a/v_Te = 1 (recorded in CLAUDE.md).
!< - fit_response: exact at a node, clamped below x = -3, continuous across a node.
use penf,           only : I4P, R8P
use appelbe_assert, only : assert_close, assert_summary
use appelbe_fits,   only : n_nodes, v_nodes, fit_node_response, fit_zero_column, fit_response

implicit none
complex(R8P)      :: j_nu, zeta_nu, j_ref, zeta_ref !< Fit values.
real(R8P)         :: j0, zeta0                      !< Tabulated omega tau = 0 values.
integer(I4P)      :: k                              !< Counter.
character(len=16) :: row                            !< Row label.

do k = 1_I4P, n_nodes
   write(row, '(A,F5.3)') 'v=', v_nodes(k)
   call fit_zero_column(k, j0, zeta0)
   call fit_node_response(k, -3._R8P, j_nu, zeta_nu)
   call assert_close(trim(row)//' j_perp(x=-3) vs wt=0',    real(j_nu, R8P),    j0,     rel_tol=1.e-2_R8P)
   call assert_close(trim(row)//' zeta_perp(x=-3) vs wt=0', real(zeta_nu, R8P), zeta0,  rel_tol=1.e-2_R8P)
   call assert_close(trim(row)//' j_wedge(x=-3)',           aimag(j_nu),        0._R8P, rel_tol=0._R8P, abs_tol=0.04_R8P)
   call assert_close(trim(row)//' zeta_wedge(x=-3)',        aimag(zeta_nu),     0._R8P, rel_tol=0._R8P, abs_tol=0.04_R8P)
   call fit_node_response(k, 3._R8P, j_nu, zeta_nu)
   call assert_close(trim(row)//' j_perp(x=+3)',     real(j_nu, R8P),    1._R8P, rel_tol=1.e-2_R8P)
   call assert_close(trim(row)//' j_wedge(x=+3)',    aimag(j_nu),        0._R8P, rel_tol=0._R8P, abs_tol=0.01_R8P)
   call assert_close(trim(row)//' zeta_perp(x=+3)',  real(zeta_nu, R8P), 0._R8P, rel_tol=0._R8P, abs_tol=0.06_R8P)
   call assert_close(trim(row)//' zeta_wedge(x=+3)', aimag(zeta_nu),     0._R8P, rel_tol=0._R8P, abs_tol=0.01_R8P)
enddo

call fit_node_response(1_I4P, 0._R8P, j_nu, zeta_nu)
call assert_close('v=1 j_perp(x=0)',     real(j_nu, R8P),     0.481_R8P, rel_tol=1.e-3_R8P)
call assert_close('v=1 j_wedge(x=0)',    aimag(j_nu),        -0.918_R8P, rel_tol=1.e-3_R8P)
call assert_close('v=1 zeta_perp(x=0)',  real(zeta_nu, R8P),  2.147_R8P, rel_tol=1.e-3_R8P)
call assert_close('v=1 zeta_wedge(x=0)', aimag(zeta_nu),      4.872_R8P, rel_tol=1.e-3_R8P)

! fit_response at a node equals the node fit; omega tau = 0 is clamped to x = -3
call fit_node_response(2_I4P, -3._R8P, j_ref, zeta_ref)
call fit_response(v_nodes(2), 0._R8P, j_nu, zeta_nu)
call assert_close('fit_response node, clamp j',    real(j_nu, R8P),    real(j_ref, R8P),    rel_tol=1.e-12_R8P)
call assert_close('fit_response node, clamp zeta', real(zeta_nu, R8P), real(zeta_ref, R8P), rel_tol=1.e-12_R8P)
! continuity across node 3
call fit_response(v_nodes(3) * (1._R8P + 1.e-9_R8P), 1._R8P, j_ref, zeta_ref)
call fit_response(v_nodes(3) * (1._R8P - 1.e-9_R8P), 1._R8P, j_nu,  zeta_nu)
call assert_close('fit_response continuity j',    real(j_nu, R8P), real(j_ref, R8P), rel_tol=1.e-6_R8P)
call assert_close('fit_response continuity zeta', aimag(zeta_nu),  aimag(zeta_ref),  rel_tol=1.e-6_R8P)

call assert_summary()
endprogram test_fits
