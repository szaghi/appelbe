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
use appelbe_distributions,         only : electron_bipolar, electron_table, electron_table_params
use appelbe_electron_study,        only : n_readouts, profile_header, f1_header, readouts_header, scan_header, &
                                          electron_profile, electron_f1, electron_readouts, electron_scan_row, &
                                          scan_value, write_table, write_scan_row
use appelbe_io,                    only : open_results, read_table
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_plasma,                only : speed_ratio

implicit none
type(kinetic_params)    :: par                 !< Physical parameters.
type(kinetic_operator)  :: om, ob              !< Operators: Maxwellian, distorted.
type(kinetic_response)  :: rm(2)               !< Maxwellian responses at both omega tau.
real(R8P), allocatable  :: xt(:), ft(:)        !< Tabulated f0 (u_L, f0).
character(len=1024)     :: table               !< Path of the tabulated f0 (first command argument).
real(R8P)               :: o(n_readouts)       !< Readouts of the tabulated f0.
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
   write(output_unit, '(A)') readouts_header
   call electron_readouts(ob, rm, omega_tau, o)
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
   character(*), intent(in) :: prefix !< File prefix in results/.
   integer(I4P)             :: unit   !< Output unit.

   unit = open_results(prefix//'_profile.dat', profile_header)
   call write_table(unit, electron_profile(ob, om))
   close(unit)
   unit = open_results(prefix//'_f1.dat', f1_header)
   call write_table(unit, electron_f1(ob, om, omega_tau))
   close(unit)
   endsubroutine write_profiles

   subroutine scan(file_name, label, ip, p_min, p_max, n_p)
   !< Vary p(ip) on [p_min, p_max], the others at the reference; write readouts and relative changes, one row each.
   character(*), intent(in) :: file_name    !< Output file in results/.
   character(*), intent(in) :: label        !< Name of the varied parameter.
   integer(I4P), intent(in) :: ip           !< Index of the varied parameter.
   real(R8P),    intent(in) :: p_min, p_max !< Range.
   integer(I4P), intent(in) :: n_p          !< Number of values.
   real(R8P)                :: p(3), o(n_readouts), max_dev !< [A, u_0, w], readouts, ECE-TS distance.
   integer(I4P)             :: i, su, monotone !< Counter, output unit, monotone f0 in the ECE window.

   su = open_results(file_name, scan_header(label))
   do i = 1_I4P, n_p
      p = ref
      p(ip) = scan_value(p_min, p_max, n_p, i)
      call ob%init(par=par, n_nodes=n_nodes, electrons=electron_bipolar, electron_params=p)
      call electron_scan_row(ob, rm, omega_tau, o, max_dev, monotone)
      call write_scan_row(su, p(ip), o, max_dev, monotone)
   enddo
   close(su)
   endsubroutine scan
endprogram appelbe_electrons
