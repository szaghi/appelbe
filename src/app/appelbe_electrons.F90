!< Non-Maxwellian electron f0 (Senni et al., ICFDT 2026): what TS and ECE read, and what transport and the alpha closure do.
program appelbe_electrons
!< Non-Maxwellian electron f0 (Senni et al., ICFDT 2026): what TS and ECE read, and what transport and the alpha closure do.
!<
!< The bulk f0 carries the bipolar distortion of the slides (Eq. 21), f0 = f_M [1 + A x exp(-x^2/2)], x = (u_L - u_0)/w,
!< u_L = p / sqrt(m_e T_e) = sqrt(2) u. The same f0 is the background of Eq. (13), so the solver gives the f1 it implies
!< and the conventional coefficients and alpha closure (3.45 MeV alphas at T_e = 10 keV, n_a/n_e = 1e-3) that go with it.
!< Readouts (appelbe_eedf): TS = Gaussian fit to the projected spectrum on w <= 2 and w <= 3, plus the energy moment; ECE
!< = local log-slope temperature (optically thick, narrow resonance), reported as its range over 1 <= u_L <= 4 (E from
!< T_e/2 to 8 T_e) and its largest distance from the TS value there. Below the window it is degenerate: a distortion that
!< reaches u = 0 (large w, small u_0) gives df0/du /= 0 there, so -2 u f0 / (df0/du) -> 0 whatever the distribution.
!< Relative changes are bipolar against Maxwellian on the same grid: signed at omega tau = 0 (all quantities
!< real), of the modulus at omega tau = 1; and, at omega tau = 0, against the Maxwellian of the same energy (T = T_kin),
!< which removes the part of the change that is only a temperature shift.
!<
!< Files: electrons_profile.dat and electrons_f1.dat (the reference case A = 0.1, u_0 = 2, w = 0.25) and
!< electrons_scan_{A,u0,w}.dat (one parameter varied, the others at the reference). With a file argument,
!< `appelbe_electrons table.dat`, f0 is read from it instead (two columns u_L and f0, '#' comments; electron_table) and
!< electrons_table_{profile,f1}.dat are written, with the readouts printed.
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_constants,             only : m_e, m_alpha, keV_J, MeV_J
use appelbe_distributions,         only : electron_bipolar, electron_maxwellian, electron_table, electron_table_params
use appelbe_eedf,                  only : slope_temperature, ts_spectrum, ts_temperature, kinetic_temperature
use appelbe_io,                    only : open_results, read_table
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_plasma,                only : speed_ratio

implicit none
type(kinetic_params)    :: par                 !< Physical parameters.
type(kinetic_operator)  :: om, ob              !< Operators: Maxwellian, distorted.
type(kinetic_response)  :: rm(2)               !< Maxwellian responses at both omega tau.
real(R8P), allocatable  :: xt(:), ft(:)        !< Tabulated f0 (u_L, f0).
character(len=1024)     :: table               !< Path of the tabulated f0 (first command argument).
real(R8P)               :: o(17)               !< Readouts of the tabulated f0.
integer(I4P), parameter :: n_nodes = 801_I4P   !< Grid (u_max = 7).
real(R8P),    parameter :: ref(3) = [0.1_R8P, 2._R8P, 0.25_R8P] !< Reference case of the slides.
real(R8P),    parameter :: omega_tau(2) = [0._R8P, 1._R8P]      !< Hall parameters.

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%n_ratio = 1.e-3_R8P
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, 10._R8P * keV_J)
call om%init(par=par, n_nodes=n_nodes)
rm(1) = om%response(omega_tau=omega_tau(1))
rm(2) = om%response(omega_tau=omega_tau(2))

if (command_argument_count() > 0) then
   ! a tabulated f0 (two columns u_L = p / sqrt(m_e T_e), f0; '#' comments), e.g. from INDACO
   call get_command_argument(1, table)
   call read_table(trim(table), xt, ft)
   call ob%init(par=par, n_nodes=n_nodes, electrons=electron_table, electron_params=electron_table_params(xt, ft))
   call write_profiles('electrons_table')
   write(output_unit, '(A)') 'T_TS(w<=2) T_TS(w<=3) T_kin T_slope_min T_slope_max [1<=u_L<=4] '// &
                             'dsigma dkappa dj_nu dzeta_nu [wt=0] same [wt=1] same [wt=0, vs Maxwellian at T_kin]'
   call readouts(o)
   write(output_unit, '(17ES13.4)') o
   write(output_unit, '(A)') trim(table)//' read; results/electrons_table_{profile,f1}.dat written'
else
   ! reference case: profiles of f0, of its readouts and of f1; then one-parameter scans around it
   call ob%init(par=par, n_nodes=n_nodes, electrons=electron_bipolar, electron_params=ref)
   call write_profiles('electrons')
   call scan('electrons_scan_A.dat',  'A',   1_I4P, -0.3_R8P, 0.3_R8P, 13_I4P)
   call scan('electrons_scan_u0.dat', 'u_0', 2_I4P,  0.5_R8P, 4._R8P,  15_I4P)
   call scan('electrons_scan_w.dat',  'w',   3_I4P,  0.1_R8P, 1._R8P,  19_I4P)
   write(output_unit, '(A)') 'Non-Maxwellian electrons written to results/electrons_*.dat'
endif

contains
   subroutine write_profiles(prefix)
   !< Write <prefix>_profile.dat (f0 and its readouts) and <prefix>_f1.dat (f1 of each unit drive) for ob against om.
   character(*), intent(in)  :: prefix         !< File prefix in results/.
   real(R8P), allocatable    :: rhs(:,:)       !< Sources: E, grad T, alpha flux.
   complex(R8P), allocatable :: fm0(:,:), fb0(:,:), fm1(:,:), fb1(:,:) !< f1 at omega tau = 0 and 1.
   real(R8P)                 :: t(ob%grid%n), sm(ob%grid%n), sb(ob%grid%n) !< Slope temperature, TS spectra.
   real(R8P)                 :: dfr(ob%grid%n) !< df0/df0_M - 1.
   integer(I4P)              :: j, unit        !< Node, output unit.

   t = slope_temperature(ob) ; sm = ts_spectrum(om) ; sb = ts_spectrum(ob)
   dfr = 0._R8P ; dfr(2:) = ob%df0(2:) / om%df0(2:) - 1._R8P ! df0 = 0 at u = 0
   unit = open_results(prefix//'_profile.dat', 'u u_L E/T_e f0_M f0 f0/f0_M-1 df0/df0_M-1 T_slope S_TS_M(w=u) S_TS(w=u)')
   do j = 1_I4P, ob%grid%n
      write(unit, '(10ES15.6)') ob%grid%u(j), sqrt(2._R8P) * ob%grid%u(j), ob%grid%u(j)**2, om%f0(j), ob%f0(j), &
                                ob%f0(j) / om%f0(j) - 1._R8P, dfr(j), t(j), sm(j), sb(j)
   enddo
   close(unit)
   allocate(rhs(om%grid%n, 3))
   rhs(:, 1) = om%source_electric() ; rhs(:, 2) = om%source_thermal() ; rhs(:, 3) = om%source_fast_flux()
   fm0 = om%solve(omega_tau=omega_tau(1), rhs=rhs)
   fm1 = om%solve(omega_tau=omega_tau(2), rhs=rhs(:, 3:3))
   rhs(:, 1) = ob%source_electric() ; rhs(:, 2) = ob%source_thermal() ; rhs(:, 3) = ob%source_fast_flux()
   fb0 = ob%solve(omega_tau=omega_tau(1), rhs=rhs)
   fb1 = ob%solve(omega_tau=omega_tau(2), rhs=rhs(:, 3:3))
   unit = open_results(prefix//'_f1.dat', 'u f1_E(M) f1_E f1_T(M) f1_T f1_a(M) f1_a [wt=0, unit drives] '// &
                                          'f1_a_perp(M) f1_a_wedge(M) f1_a_perp f1_a_wedge [wt=1]')
   do j = 1_I4P, ob%grid%n
      write(unit, '(11ES15.6)') ob%grid%u(j), real(fm0(j, 1)), real(fb0(j, 1)), real(fm0(j, 2)), real(fb0(j, 2)), &
                                real(fm0(j, 3)), real(fb0(j, 3)), fm1(j, 1), fb1(j, 1)
   enddo
   close(unit)
   endsubroutine write_profiles

   subroutine readouts(o)
   !< Readouts of ob and relative changes against om: T_TS (w <= 2, 3), T_kin, T_slope range on 1 <= u_L <= 4, then
   !< sigma, kappa, j_nu, zeta_nu (signed at omega tau = 0, modulus at omega tau = 1), then the same at omega tau = 0
   !< against the Maxwellian of equal energy (T = T_kin): what is left is the effect of the shape, not of the temperature.
   real(R8P), intent(out) :: o(17)  !< The readouts.
   type(kinetic_operator) :: ot     !< Maxwellian at T_kin.
   type(kinetic_response) :: rt     !< Its response.
   real(R8P)              :: t(ob%grid%n)   !< Slope temperature.
   logical                :: win(ob%grid%n) !< Nodes in the ECE window.
   type(kinetic_response) :: rb     !< Response of ob.

   t = slope_temperature(ob)
   win = sqrt(2._R8P) * ob%grid%u >= 1._R8P .and. sqrt(2._R8P) * ob%grid%u <= 4._R8P
   o(1:5) = [ts_temperature(ob, 2._R8P), ts_temperature(ob, 3._R8P), kinetic_temperature(ob), &
             minval(t, mask=win), maxval(t, mask=win)]
   rb = ob%response(omega_tau=omega_tau(1))
   o(6:9) = [real(rb%sigma / rm(1)%sigma, R8P), real(rb%kappa() / rm(1)%kappa(), R8P), &
             real(rb%j_nu / rm(1)%j_nu, R8P),   real(rb%zeta_nu / rm(1)%zeta_nu, R8P)] - 1._R8P
   rb = ob%response(omega_tau=omega_tau(2))
   o(10:13) = [abs(rb%sigma / rm(2)%sigma), abs(rb%kappa() / rm(2)%kappa()), &
               abs(rb%j_nu / rm(2)%j_nu),   abs(rb%zeta_nu / rm(2)%zeta_nu)] - 1._R8P
   call ot%init(par=par, n_nodes=n_nodes, electrons=electron_maxwellian, electron_params=[o(3)])
   rt = ot%response(omega_tau=omega_tau(1))
   rb = ob%response(omega_tau=omega_tau(1))
   o(14:17) = [real(rb%sigma / rt%sigma, R8P), real(rb%kappa() / rt%kappa(), R8P), &
               real(rb%j_nu / rt%j_nu, R8P),   real(rb%zeta_nu / rt%zeta_nu, R8P)] - 1._R8P
   endsubroutine readouts

   subroutine scan(file_name, label, ip, p_min, p_max, n_p)
   !< Vary p(ip) on [p_min, p_max], the others at the reference; write readouts and relative changes, one row each.
   character(*), intent(in) :: file_name    !< Output file in results/.
   character(*), intent(in) :: label        !< Name of the varied parameter.
   integer(I4P), intent(in) :: ip           !< Index of the varied parameter.
   real(R8P),    intent(in) :: p_min, p_max !< Range.
   integer(I4P), intent(in) :: n_p          !< Number of values.
   real(R8P)                :: p(3), o(17)  !< [A, u_0, w], readouts.
   real(R8P), allocatable   :: t(:)         !< Slope temperature.
   logical, allocatable     :: win(:)       !< Nodes in the ECE window 1 <= u_L <= 4 (sized by each init).
   integer(I4P)             :: i, su        !< Counter, output unit.

   su = open_results(file_name, label//' T_TS(w<=2) T_TS(w<=3) T_kin T_slope_min T_slope_max max|T_slope-T_TS| '// &
                     '[1<=u_L<=4] monotone dsigma dkappa dj_nu dzeta_nu [wt=0, signed] same [wt=1, modulus] '// &
                     'same [wt=0, signed, vs the Maxwellian at T_kin]')
   do i = 1_I4P, n_p
      p = ref
      p(ip) = p_min + (p_max - p_min) * real(i - 1_I4P, R8P) / real(n_p - 1_I4P, R8P)
      call ob%init(par=par, n_nodes=n_nodes, electrons=electron_bipolar, electron_params=p)
      call readouts(o)
      t = slope_temperature(ob)
      win = sqrt(2._R8P) * ob%grid%u >= 1._R8P .and. sqrt(2._R8P) * ob%grid%u <= 4._R8P
      ! a non-monotonic f0 has df0 >= 0 somewhere: the slope temperature diverges there (ECE reads no temperature)
      write(su, '(7ES15.6,I3,12ES15.6)') p(ip), o(1:5), maxval(abs(t - o(1)), mask=win), &
                                        merge(1_I4P, 0_I4P, all(ob%df0 < 0._R8P .or. .not. win)), o(6:)
   enddo
   close(su)
   endsubroutine scan
endprogram appelbe_electrons
