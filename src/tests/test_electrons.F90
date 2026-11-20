!< Non-Maxwellian electron f0: the general path of the solver, the bipolar distortion, the TS and ECE readouts.
program test_electrons
!< Non-Maxwellian electron f0: the general path of the solver, the bipolar distortion, the TS and ECE readouts.
!<
!< - A Maxwellian given as a function (electron_maxwellian) goes through the general forms of Eqs. (A2) and (A5): f0 and
!<   its derivatives by finite differences, I_0, I_2, J_-1 by quadrature. It must converge to the closed forms (A8)-(A13).
!< - The bipolar distortion (Senni et al., ICFDT 2026, Eq. 21) is checked against its analytic form: f0/f_M - 1 peaks at
!<   A exp(-1/2) once the density renormalisation is divided out, and df0 against the analytic derivative.
!< - Lorentz gas (Z_i -> infinity): f1 = -u^3 g7 / k_i is local, so for any f0 sigma ~ int u^6 (-f0'/2) = 3 int u^5 f0
!<   and K ~ int u^8 g7_T = (7/2) int u^9 f0: the ratios to the Maxwellian test the general drives without the e-e operator.
!< - Onsager's tau = mu - (3/2) sigma holds only about the Maxwellian, the collisional equilibrium: the bipolar f0
!<   breaks it at first order in A (measured -1.8% at A = 0.1, w = 0.5), regression value.
!< - A tabulated f0 (electron_table, spline of ln f) reproduces the Maxwellian and the bipolar results it samples.
!< - Luca's reference case (A = 0.1, u_0 = 2, w = 0.25, in units of sqrt(m_e T_e)): regression values of the slides'
!<   quantities and of the change of the transport coefficients and of the alpha closure.
use penf,                  only : I4P, R8P
use appelbe_assert,        only : assert_close, assert_summary
use appelbe_constants,     only : m_e, m_alpha, keV_J, MeV_J
use appelbe_distributions, only : electron_maxwellian, electron_bipolar, electron_table, electron_table_params
use appelbe_eedf,          only : slope_temperature, ts_temperature, kinetic_temperature
use appelbe_electron_study, only : n_readouts, electron_readouts, electron_profile
use appelbe_kinetic,       only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_plasma,        only : speed_ratio

implicit none
type(kinetic_params)   :: par             !< Physical parameters.
type(kinetic_operator) :: om, ob          !< Operators: closed-form Maxwellian, general path.
type(kinetic_response) :: rm, rb          !< Responses.
real(R8P)              :: err(3)          !< Largest relative difference general vs closed form, 401/801/1601 nodes.
real(R8P), allocatable :: t(:), x(:), fu(:), dfu(:) !< Slope temperature; bipolar argument, f0 and df0/du unnormalised.
real(R8P), allocatable :: xt(:), ft(:)    !< A table of f0 on u_L = sqrt(2) u.
real(R8P), parameter   :: bip(3) = [0.1_R8P, 2._R8P, 0.25_R8P] !< Luca's reference case [A, u_0, w].
integer(I4P), parameter :: nodes(3) = [401_I4P, 801_I4P, 1601_I4P] !< Grids of the convergence check.
integer(I4P)           :: k, n3           !< Counter, last node below u = 3.

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%n_ratio = 1.e-3_R8P
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, 10._R8P * keV_J)

! general path with a Maxwellian -> closed forms, at third order (trapezoidal first interval of the partial integrals)
do k = 1_I4P, 3_I4P
   call om%init(par=par, n_nodes=nodes(k))
   call ob%init(par=par, n_nodes=nodes(k), electrons=electron_maxwellian, electron_params=[1._R8P])
   rm = om%response(omega_tau=1._R8P)
   rb = ob%response(omega_tau=1._R8P)
   err(k) = maxval([abs(rb%sigma / rm%sigma - 1._R8P), abs(rb%kappa() / rm%kappa() - 1._R8P), &
                    abs(rb%j_nu / rm%j_nu - 1._R8P),   abs(rb%zeta_nu / rm%zeta_nu - 1._R8P)])
enddo
call assert_close('general Maxwellian vs closed form, 401 nodes', err(1), 0._R8P, rel_tol=0._R8P, abs_tol=3.e-6_R8P)
call assert_close('general path converges at third order (401 -> 801)',  log(err(1) / err(2)) / log(2._R8P), 3._R8P, &
                  rel_tol=0.15_R8P)
call assert_close('general path converges at third order (801 -> 1601)', log(err(2) / err(3)) / log(2._R8P), 3._R8P, &
                  rel_tol=0.15_R8P)

! readouts of a Maxwellian: every temperature is T_e
call om%init(par=par, n_nodes=801_I4P)
t = slope_temperature(om)
call assert_close('Maxwellian slope temperature',   maxval(abs(t - 1._R8P)), 0._R8P, rel_tol=0._R8P, abs_tol=1.e-12_R8P)
call assert_close('Maxwellian TS fit, w <= 2',      ts_temperature(om, 2._R8P), 1._R8P, rel_tol=1.e-5_R8P)
call assert_close('Maxwellian TS fit, w <= 3',      ts_temperature(om, 3._R8P), 1._R8P, rel_tol=1.e-5_R8P)
call assert_close('Maxwellian kinetic temperature', kinetic_temperature(om),    1._R8P, rel_tol=1.e-5_R8P)

! bipolar distortion against its analytic form
call ob%init(par=par, n_nodes=801_I4P, electrons=electron_bipolar, electron_params=bip)
x   = (sqrt(2._R8P) * ob%grid%u - bip(2)) / bip(3)
fu  = exp(-ob%grid%u**2) * (1._R8P + bip(1) * x * exp(-0.5_R8P * x**2))
dfu = -2._R8P * ob%grid%u * fu + exp(-ob%grid%u**2) * bip(1) * (1._R8P - x**2) * exp(-0.5_R8P * x**2) &
      * sqrt(2._R8P) / bip(3)
call assert_close('bipolar peak of f0/f_M - 1 (A exp(-1/2))', &
                  maxval(ob%f0 / om%f0 * (om%f0(1) / ob%f0(1)) - 1._R8P), bip(1) * exp(-0.5_R8P), rel_tol=1.e-4_R8P)
n3 = count(ob%grid%u < 3._R8P)
call assert_close('bipolar df0, finite differences vs analytic', &
                  maxval(abs(ob%df0(:n3) - ob%f0(2) / fu(2) * dfu(:n3))) / maxval(abs(ob%df0)), 0._R8P, &
                  rel_tol=0._R8P, abs_tol=1.e-8_R8P)

! Luca's reference case (regression; the slides give 6.1%, 21.3%, < 1% and 17-20% with a relativistic base and no
! density renormalisation)
call assert_close('reference case: peak |f0/f_M - 1|',     maxval(abs(ob%f0(:n3) / om%f0(:n3) - 1._R8P)),     &
                  0.06703_R8P, rel_tol=1.e-3_R8P)
call assert_close('reference case: peak |df0/df_M - 1|',   maxval(abs(ob%df0(2:n3) / om%df0(2:n3) - 1._R8P)), &
                  0.2077_R8P, rel_tol=1.e-3_R8P)
call assert_close('reference case: TS fit, w <= 2',        ts_temperature(ob, 2._R8P), 1.0070_R8P, rel_tol=1.e-4_R8P)
call assert_close('reference case: kinetic temperature',   kinetic_temperature(ob),    1.0062_R8P, rel_tol=1.e-4_R8P)
t = slope_temperature(ob)
call assert_close('reference case: slope temperature min', minval(t(2:n3)), 0.894_R8P, rel_tol=1.e-3_R8P)
call assert_close('reference case: slope temperature max', maxval(t(2:n3)), 1.253_R8P, rel_tol=1.e-3_R8P)
rm = om%response(omega_tau=0._R8P)
rb = ob%response(omega_tau=0._R8P)
call assert_close('reference case: sigma change, wt = 0',   abs(rb%sigma / rm%sigma - 1._R8P),     0.0061_R8P, &
                  rel_tol=2.e-2_R8P)
call assert_close('reference case: kappa change, wt = 0',   abs(rb%kappa() / rm%kappa() - 1._R8P), 0.0103_R8P, &
                  rel_tol=2.e-2_R8P)
call assert_close('reference case: j_nu change, wt = 0',    abs(rb%j_nu / rm%j_nu - 1._R8P),       0.0049_R8P, &
                  rel_tol=2.e-2_R8P)
call assert_close('reference case: zeta_nu change, wt = 0', abs(rb%zeta_nu / rm%zeta_nu - 1._R8P), 0.0063_R8P, &
                  rel_tol=2.e-2_R8P)

! the study module (what the driver writes and the GUI shows) reports the readouts of the direct calls, bit for bit
block
   type(kinetic_response) :: rr(2)           !< Maxwellian responses at omega tau = 0, 1.
   real(R8P)              :: o(n_readouts)   !< Readouts.
   real(R8P), allocatable :: prof(:,:)       !< Profile table.
   integer(I4P)           :: stat            !< Status.

   rr(1) = om%response(omega_tau=0._R8P) ; rr(2) = om%response(omega_tau=1._R8P)
   call electron_readouts(ob, rr, [0._R8P, 1._R8P], o, stat=stat)
   call assert_close('study: readouts = direct calls (T_TS, T_kin, sigma change), stat 0', &
                     merge(1._R8P, 0._R8P, stat == 0_I4P .and. o(1) == ts_temperature(ob, 2._R8P) .and. &
                     o(3) == kinetic_temperature(ob) .and. o(6) == real(rb%sigma / rm%sigma, R8P) - 1._R8P), 1._R8P, rel_tol=0._R8P)
   prof = electron_profile(ob, om)
   call assert_close('study: profile = f0 and slope temperature of the operator', &
                     merge(1._R8P, 0._R8P, all(prof(:, 5) == ob%f0) .and. all(prof(:, 8) == slope_temperature(ob))), 1._R8P, &
                     rel_tol=0._R8P)
endblock

! tabulated f0 (u_L step 0.02 up to 12): the spline of ln f against the functions it samples, f0 and the responses
xt = [(0.02_R8P * k, k = 0_I4P, 600_I4P)]
ft = exp(-0.5_R8P * xt**2)
call ob%init(par=par, n_nodes=801_I4P, electrons=electron_table, electron_params=electron_table_params(xt, ft))
call assert_close('Maxwellian table: f0', maxval(abs(ob%f0 - om%f0)) / om%f0(1), 0._R8P, rel_tol=0._R8P, abs_tol=1.e-9_R8P)
rb = ob%response(omega_tau=1._R8P)
rm = om%response(omega_tau=1._R8P)
call assert_close('Maxwellian table: |j_nu|',  abs(rb%j_nu),    abs(rm%j_nu),    rel_tol=1.e-6_R8P)
call assert_close('Maxwellian table: |kappa|', abs(rb%kappa()), abs(rm%kappa()), rel_tol=1.e-6_R8P)
ft = [(electron_bipolar(xt(k) / sqrt(2._R8P), bip), k = 1_I4P, size(xt, kind=I4P))]
call om%init(par=par, n_nodes=801_I4P, electrons=electron_bipolar, electron_params=bip)
call ob%init(par=par, n_nodes=801_I4P, electrons=electron_table, electron_params=electron_table_params(xt, ft))
call assert_close('bipolar table: f0', maxval(abs(ob%f0 - om%f0)) / om%f0(1), 0._R8P, rel_tol=0._R8P, abs_tol=1.e-6_R8P)
rb = ob%response(omega_tau=1._R8P)
rm = om%response(omega_tau=1._R8P)
call assert_close('bipolar table: |j_nu|',  abs(rb%j_nu),    abs(rm%j_nu),    rel_tol=1.e-5_R8P)
call assert_close('bipolar table: |kappa|', abs(rb%kappa()), abs(rm%kappa()), rel_tol=1.e-5_R8P)

! Lorentz gas: ratios to the Maxwellian against the moments of f0
block
   type(kinetic_params) :: lor !< Lorentz-gas parameters.

   lor%z_i = 1.e8_R8P
   call om%init(par=lor, n_nodes=801_I4P)
   call ob%init(par=lor, n_nodes=801_I4P, electrons=electron_bipolar, electron_params=[0.2_R8P, 2._R8P, 0.5_R8P])
   rm = om%response(omega_tau=0._R8P)
   rb = ob%response(omega_tau=0._R8P)
   associate(w => om%grid%lower_weights(om%grid%n), u => om%grid%u)
      call assert_close('Lorentz gas, bipolar: sigma ratio = int u^5 f0 ratio', real(rb%sigma / rm%sigma, R8P), &
                        sum(w * u**5 * ob%f0) / sum(w * u**5 * om%f0), rel_tol=1.e-6_R8P)
      call assert_close('Lorentz gas, bipolar: K ratio = int u^9 f0 ratio', &
                        real(rb%thermal_diffusion / rm%thermal_diffusion, R8P), &
                        sum(w * u**9 * ob%f0) / sum(w * u**9 * om%f0), rel_tol=1.e-6_R8P)
   endassociate
   ! a Maxwellian at T: sigma ~ int u^5 f0 ~ T^(3/2)
   call ob%init(par=lor, n_nodes=801_I4P, electrons=electron_maxwellian, electron_params=[1.1_R8P])
   rb = ob%response(omega_tau=0._R8P)
   call assert_close('Lorentz gas, Maxwellian at 1.1 T_e: sigma ratio = 1.1^(3/2)', real(rb%sigma / rm%sigma, R8P), &
                     1.1_R8P**1.5_R8P, rel_tol=1.e-6_R8P)
endblock

! Onsager: exact for the Maxwellian, broken at first order in A by the bipolar f0 (w = 0.5); no alphas (their isotropic
! F0 is not an electron equilibrium either, and breaks it by 1e-4 at n_a/n_e = 1e-3)
par%u_a = 0._R8P ; par%n_ratio = 0._R8P
call om%init(par=par, n_nodes=801_I4P, electrons=electron_maxwellian, electron_params=[1._R8P])
call ob%init(par=par, n_nodes=801_I4P, electrons=electron_bipolar, electron_params=[0.1_R8P, 2._R8P, 0.5_R8P])
rm = om%response(omega_tau=0._R8P)
rb = ob%response(omega_tau=0._R8P)
call assert_close('Onsager, general-path Maxwellian', real(rm%tau / (rm%mu - 1.5_R8P * rm%sigma), R8P), 1._R8P, &
                  rel_tol=1.e-6_R8P)
call assert_close('Onsager broken by the bipolar f0 (A = 0.1)', real(rb%tau / (rb%mu - 1.5_R8P * rb%sigma), R8P) - 1._R8P, &
                  -1.77e-2_R8P, rel_tol=2.e-2_R8P)

call assert_summary()
endprogram test_electrons
