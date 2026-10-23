!< Kinetic fast-ion response versus the paper: tables, figures, low-velocity limit (Eq. 32), signs, distributed populations.
program test_fast_ions
!< Kinetic fast-ion response versus the paper: tables, figures, low-velocity limit (Eq. 32), signs, distributed populations.
!<
!< Tolerances against Tables I-IV (n_a/n_e = 0 here): the residual is set by the fits themselves (they miss the paper's
!< own Fig. 3 by up to 0.007 in j and 0.04 in zeta) and, at v_a/v_Te = 1 and 0.5, by the paper's discretisation of the
!< delta function; it is <= 3% for j_perp and <= 1.5% for zeta_perp. NRL Coulomb logarithms give lnL_ee = lnL_ei, so the
!< unit ratios used here are the paper's choice too.
use penf,                  only : I4P, R8P
use appelbe_assert,        only : assert_close, assert_summary
use appelbe_constants,     only : m_e, m_alpha, m_carbon12, keV_J, MeV_J
use appelbe_distributions, only : energy_gaussian, energy_flat
use appelbe_fits,          only : v_nodes, fit_zero_column
use appelbe_kinetic,       only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_paper,         only : paper_n_ratio, paper_fig2_speed, paper_fig2_samples, init_paper
use appelbe_plasma,        only : speed_ratio, resistive_coefficient

implicit none
type(kinetic_params)   :: par       !< Physical parameters.
type(kinetic_operator) :: op        !< Kinetic operator.
type(kinetic_response) :: r, rd     !< Responses.
real(R8P)              :: j0, zeta0 !< Tabulated omega tau = 0 values.
real(R8P), allocatable :: rhs(:,:)  !< Fast-ion source.
complex(R8P), allocatable :: f1(:,:) !< Electron f1.
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

! the paper's set-up (isotropic F0 with n_a/n_e = 1e-3) against its own Fig. 2 at its smallest sample, v_a/v_Te = 0.1
! (values extracted from the vector figure); with n_a/n_e = 0 carbon would be -5.071, 0.21 off
call assert_close('paper Fig. 2 sample 25 is v_a/v_Te = 0.1', paper_fig2_speed(paper_fig2_samples), 0.1_R8P, &
                  rel_tol=1.e-12_R8P)
par%u_a = 0.1_R8P ; par%n_ratio = paper_n_ratio
par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
call op%init(par=par)
r = op%response(omega_tau=0._R8P)
call assert_close('paper set-up, alpha, v=0.1 (paper Fig. 2: -1.0154)', real(r%j_nu, R8P), -1.0154_R8P, &
                  rel_tol=0._R8P, abs_tol=2.e-3_R8P)
par%z_a = 6._R8P ; par%mass_ratio = m_e / m_carbon12
call op%init(par=par)
r = op%response(omega_tau=0._R8P)
call assert_close('paper set-up, carbon, v=0.1 (paper Fig. 2: -4.8625)', real(r%j_nu, R8P), -4.8625_R8P, &
                  rel_tol=0._R8P, abs_tol=2.e-3_R8P)

! the paper's own grid (h = 5/198, no node at u_a) reproduces its O(h) error: Fig. 2 carbon at sample 3 (v = 0.3288;
! the converged solution is 0.025 off) and the depth of the negative lobe of f1_perp in Fig. 1 (converged: -1.093)
par%z_a = 6._R8P ; par%mass_ratio = m_e / m_carbon12 ; par%u_a = paper_fig2_speed(3_I4P)
call init_paper(op, par)
r = op%response(omega_tau=0._R8P)
call assert_close('paper grid, carbon, v=0.3288 (paper Fig. 2: -5.4164)', real(r%j_nu, R8P), -5.4164_R8P, &
                  rel_tol=0._R8P, abs_tol=3.e-3_R8P)
par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, 2._R8P * keV_J)
call init_paper(op, par)
rhs = reshape(op%source_fast_flux(), [op%grid%n, 1])
f1 = op%solve(omega_tau=10._R8P, rhs=rhs)
call assert_close('paper grid, Fig. 1 f1_perp lobe (paper -1.224)', minval(real(f1(:, 1))) / maxval(real(f1(:, 1))), &
                  -1.224_R8P, rel_tol=0._R8P, abs_tol=2.e-2_R8P)
call op%init(par=par, n_nodes=801_I4P)
rhs = reshape(op%source_fast_flux(), [op%grid%n, 1])
f1 = op%solve(omega_tau=10._R8P, rhs=rhs)
call assert_close('converged, Fig. 1 f1_perp lobe', minval(real(f1(:, 1))) / maxval(real(f1(:, 1))), &
                  -1.093_R8P, rel_tol=0._R8P, abs_tol=5.e-3_R8P)

! distributed populations (footnote 30): a narrow Gaussian converges to the monoenergetic result as sigma^2
par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%u_a = 0.5_R8P
call op%init(par=par, n_nodes=801_I4P)
call assert_close('monoenergetic u_flux = u_a',   op%u_flux,   0.5_R8P, rel_tol=1.e-14_R8P)
call assert_close('monoenergetic u_energy = u_a', op%u_energy, 0.5_R8P, rel_tol=1.e-14_R8P)
rd = op%response(omega_tau=1._R8P)
call op%init(par=par, n_nodes=801_I4P, distribution=energy_gaussian, shape_params=[0.5_R8P, 0.08_R8P])
r = op%response(omega_tau=1._R8P)
call assert_close('narrow Gaussian -> delta, |j|',    abs(r%j_nu),    abs(rd%j_nu),    rel_tol=5.e-4_R8P)
call assert_close('narrow Gaussian -> delta, |zeta|', abs(r%zeta_nu), abs(rd%zeta_nu), rel_tol=5.e-4_R8P)
call op%init(par=par, n_nodes=801_I4P, u_max=6._R8P, distribution=energy_flat, shape_params=[0.5_R8P, 0.3_R8P, 0.1_R8P])
call assert_close('flat spectrum: mean-energy speed', op%u_energy, 0.5_R8P, rel_tol=2.e-4_R8P)

! plasma helpers
call assert_close('v_a/v_Te, 3.45 MeV alpha at 2 keV', speed_ratio(3.45_R8P * MeV_J, m_alpha, 2._R8P * keV_J), &
                  0.4863_R8P, rel_tol=1.e-3_R8P)
call assert_close('Eq. 43 prefactor (1 keV, lnL = 1)', resistive_coefficient(keV_J, 1._R8P, 1._R8P, 0.506_R8P), &
                  1.65e-9_R8P, rel_tol=1.e-3_R8P)

call assert_summary()
endprogram test_fast_ions
