!< Kinetic fast-ion response versus the paper: Appendix C tables, low-velocity limit (Eq. 32), sign convention, plasma helpers.
program test_fast_ions
!< Kinetic fast-ion response versus the paper: Appendix C tables, low-velocity limit (Eq. 32), sign convention, plasma helpers.
!<
!< Tolerances: the kinetic solver assumes lnL_ee = lnL_ei = lnL_ea, while the paper's data used NRL Coulomb logarithms
!< (unspecified ratios); the measured residual against Tables I-IV is <= 3% for j_perp and <= 1.5% for zeta_perp.
use penf,              only : I4P, R8P
use appelbe_assert,    only : assert_close, assert_summary
use appelbe_constants, only : m_e, m_alpha, m_carbon12, keV_J, MeV_J
use appelbe_fits,      only : v_nodes, fit_zero_column
use appelbe_kinetic,   only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_plasma,    only : speed_ratio, resistive_coefficient

implicit none
type(kinetic_params)   :: par       !< Physical parameters.
type(kinetic_operator) :: op        !< Kinetic operator.
type(kinetic_response) :: r         !< Response.
real(R8P)              :: j0, zeta0 !< Tabulated omega tau = 0 values.
integer(I4P)           :: k         !< Counter.
character(len=16)      :: row       !< Row label.

! unmagnetised kinetic response versus the omega tau = 0 column of Tables I and III
par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
do k = 1_I4P, 5_I4P
   write(row, '(A,F5.3)') 'v=', v_nodes(k)
   par%u_a = v_nodes(k)
   call op%init(par=par)
   r = op%response(omega_tau=0._R8P)
   call fit_zero_column(k, j0, zeta0)
   call assert_close(trim(row)//' kinetic j_perp vs Table I',      real(r%j_nu, R8P),    j0,    rel_tol=3.5e-2_R8P)
   call assert_close(trim(row)//' kinetic zeta_perp vs Table III', real(r%zeta_nu, R8P), zeta0, rel_tol=2.e-2_R8P)
enddo

! magnetised: induced current orthogonal to the flux is negative (b x flux convention), heat flow positive (Fig. 3)
par%u_a = 0.5_R8P
call op%init(par=par)
r = op%response(omega_tau=1._R8P)
call assert_close('v=0.5, wt=1 j_wedge    (Table II fit -0.904)', aimag(r%j_nu),   -0.904_R8P, rel_tol=3.e-2_R8P)
call assert_close('v=0.5, wt=1 zeta_wedge (Table IV fit 4.294)',  aimag(r%zeta_nu), 4.294_R8P, rel_tol=3.e-2_R8P)

! grid independence where a rounding-sensitive Heaviside at the u_a-aligned node once caused 2% jumps (v = 0.6, 0.7)
par%u_a = 0.6_R8P
call op%init(par=par)
r = op%response(omega_tau=0._R8P)
j0 = real(r%j_nu, R8P)
call op%init(par=par, n_nodes=1601_I4P)
r = op%response(omega_tau=0._R8P)
call assert_close('v=0.6 j_perp, 401 vs 1601 nodes', j0, real(r%j_nu, R8P), rel_tol=1.e-3_R8P)
par%u_a = 0.7_R8P
call op%init(par=par)
r = op%response(omega_tau=0._R8P)
j0 = real(r%j_nu, R8P)
call op%init(par=par, u_max=10._R8P)
r = op%response(omega_tau=0._R8P)
call assert_close('v=0.7 j_perp, u_max 7 vs 10',     j0, real(r%j_nu, R8P), rel_tol=1.e-3_R8P)

! low-velocity limit j0_ea / j0_a -> 1 - Z_a / Z_i (Eq. 32): alphas -1, carbon -5 (Fig. 2)
par%u_a = 0.1_R8P
call op%init(par=par)
r = op%response(omega_tau=0._R8P)
call assert_close('Eq. 32 alpha, v=0.1', real(r%j_nu, R8P), -1._R8P, rel_tol=5.e-2_R8P)
par%z_a = 6._R8P ; par%mass_ratio = m_e / m_carbon12
call op%init(par=par)
r = op%response(omega_tau=0._R8P)
call assert_close('Eq. 32 carbon, v=0.1', real(r%j_nu, R8P), -5._R8P, rel_tol=5.e-2_R8P)

! plasma helpers
call assert_close('v_a/v_Te, 3.45 MeV alpha at 2 keV', speed_ratio(3.45_R8P * MeV_J, m_alpha, 2._R8P * keV_J), &
                  0.4863_R8P, rel_tol=1.e-3_R8P)
call assert_close('Eq. 43 prefactor (1 keV, lnL = 1)', resistive_coefficient(keV_J, 1._R8P, 1._R8P, 0.506_R8P), &
                  1.65e-9_R8P, rel_tol=1.e-3_R8P)

call assert_summary()
endprogram test_fast_ions
