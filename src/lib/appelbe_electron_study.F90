!< The study of a non-Maxwellian electron f0 against the Maxwellian: profiles, f1, readouts and one-parameter scans.
module appelbe_electron_study
!< The study of a non-Maxwellian electron f0 against the Maxwellian: profiles, f1, readouts and one-parameter scans.
!<
!< What the driver appelbe_electrons writes and the GUI shows, computed once here so that both report the same numbers:
!<
!< - electron_profile: f0 and its readouts on the grid (TS spectrum, slope temperature, relative changes of f0 and f0');
!< - electron_f1: f1 of each unit drive (E, grad T, fast-ion flux) at omega tau = 0, and of the fast-ion flux at a
!<   second omega tau, for the distorted and the Maxwellian f0;
!< - electron_readouts: the TS, kinetic and ECE temperatures and the relative changes of sigma, kappa, j_nu, zeta_nu
!<   (signed at the first omega tau, of the modulus at the second, and at the first against the Maxwellian of the same
!<   energy, T = T_kin, which removes the part of the change that is only a temperature shift);
!< - electron_scan_row: one row of a scan, the readouts plus the ECE-TS distance and whether f0 decreases monotonically
!<   in the ECE window (a non-monotonic f0 has a diverging slope temperature: ECE reads no temperature there).
!<
!< The tables have the columns of the *_header constants; write_table writes them in the drivers' formats.
use penf,                  only : I4P, R8P
use appelbe_distributions, only : electron_maxwellian
use appelbe_eedf,          only : slope_temperature, ts_spectrum, ts_temperature, kinetic_temperature
use appelbe_kinetic,       only : kinetic_operator, kinetic_response

implicit none
private
public :: n_readouts, ts_windows, ece_window
public :: profile_header, f1_header, readouts_header, scan_header
public :: electron_profile, electron_f1, electron_readouts, electron_scan_row, scan_value
public :: write_table, write_scan_row

integer(I4P), parameter :: n_readouts = 17_I4P                !< Readouts of electron_readouts.
real(R8P),    parameter :: ts_windows(2) = [2._R8P, 3._R8P]   !< Gaussian-fit windows of the TS spectrum, w <= w_max.
real(R8P),    parameter :: ece_window(2) = [1._R8P, 4._R8P]   !< ECE window in u_L = sqrt(2) u (E from T_e/2 to 8 T_e).

character(len=*), parameter :: profile_header = &
   'u u_L E/T_e f0_M f0 f0/f0_M-1 df0/df0_M-1 T_slope S_TS_M(w=u) S_TS(w=u)' !< Columns of electron_profile.
character(len=*), parameter :: f1_header = 'u f1_E(M) f1_E f1_T(M) f1_T f1_a(M) f1_a [wt=0, unit drives] '// &
                                           'f1_a_perp(M) f1_a_wedge(M) f1_a_perp f1_a_wedge [wt=1]' !< Columns of electron_f1.
character(len=*), parameter :: readouts_header = 'T_TS(w<=2) T_TS(w<=3) T_kin T_slope_min T_slope_max [1<=u_L<=4] '// &
   'dsigma dkappa dj_nu dzeta_nu [wt=0] same [wt=1] same [wt=0, vs Maxwellian at T_kin]' !< The 17 readouts.

contains
   pure function scan_header(label) result(header)
   !< Columns of a scan table whose varied parameter is label (one row per value: electron_scan_row).
   character(*), intent(in)      :: label  !< Name of the varied parameter.
   character(len=:), allocatable :: header !< The header, without the leading '#'.

   header = label//' T_TS(w<=2) T_TS(w<=3) T_kin T_slope_min T_slope_max max|T_slope-T_TS| '// &
            '[1<=u_L<=4] monotone dsigma dkappa dj_nu dzeta_nu [wt=0, signed] same [wt=1, modulus] '// &
            'same [wt=0, signed, vs the Maxwellian at T_kin]'
   endfunction scan_header

   pure function scan_value(p_min, p_max, n_p, i) result(p)
   !< The i-th of n_p values equally spaced on [p_min, p_max] (the drivers' and the GUI's scans: the same rounding).
   real(R8P),    intent(in) :: p_min, p_max !< Range.
   integer(I4P), intent(in) :: n_p, i       !< Number of values (>= 2), index.
   real(R8P)                :: p            !< The value.

   p = p_min + (p_max - p_min) * real(i - 1_I4P, R8P) / real(n_p - 1_I4P, R8P)
   endfunction scan_value

   pure function electron_profile(ob, om) result(t)
   !< f0 of ob and its readouts on the grid, against the Maxwellian om on the same grid (columns of profile_header).
   type(kinetic_operator), intent(in) :: ob             !< Operator with the distorted f0.
   type(kinetic_operator), intent(in) :: om             !< Operator with the Maxwellian, the same grid.
   real(R8P)                          :: t(ob%grid%n, 10) !< The table.
   real(R8P)                          :: dfr(ob%grid%n) !< df0/df0_M - 1.

   dfr = 0._R8P ; dfr(2:) = ob%df0(2:) / om%df0(2:) - 1._R8P ! df0 = 0 at u = 0
   t(:, 1)  = ob%grid%u
   t(:, 2)  = sqrt(2._R8P) * ob%grid%u
   t(:, 3)  = ob%grid%u**2
   t(:, 4)  = om%f0
   t(:, 5)  = ob%f0
   t(:, 6)  = ob%f0 / om%f0 - 1._R8P
   t(:, 7)  = dfr
   t(:, 8)  = slope_temperature(ob)
   t(:, 9)  = ts_spectrum(om)
   t(:, 10) = ts_spectrum(ob)
   endfunction electron_profile

   function electron_f1(ob, om, omega_tau) result(t)
   !< f1 of each unit drive at omega_tau(1), and of the fast-ion flux at omega_tau(2) (perp, wedge), for ob and om
   !< (columns of f1_header). Both operators need fast ions (par%u_a > 0).
   type(kinetic_operator), intent(in) :: ob           !< Operator with the distorted f0.
   type(kinetic_operator), intent(in) :: om           !< Operator with the Maxwellian, the same grid.
   real(R8P),              intent(in) :: omega_tau(2) !< Hall parameters.
   real(R8P)                          :: t(ob%grid%n, 11) !< The table.
   real(R8P), allocatable             :: rhs(:,:)     !< Sources: E, grad T, alpha flux.
   complex(R8P), allocatable          :: fm0(:,:), fb0(:,:), fm1(:,:), fb1(:,:) !< f1 at both omega tau.

   allocate(rhs(om%grid%n, 3))
   rhs(:, 1) = om%source_electric() ; rhs(:, 2) = om%source_thermal() ; rhs(:, 3) = om%source_fast_flux()
   fm0 = om%solve(omega_tau=omega_tau(1), rhs=rhs)
   fm1 = om%solve(omega_tau=omega_tau(2), rhs=rhs(:, 3:3))
   rhs(:, 1) = ob%source_electric() ; rhs(:, 2) = ob%source_thermal() ; rhs(:, 3) = ob%source_fast_flux()
   fb0 = ob%solve(omega_tau=omega_tau(1), rhs=rhs)
   fb1 = ob%solve(omega_tau=omega_tau(2), rhs=rhs(:, 3:3))
   t(:, 1)  = ob%grid%u
   t(:, 2)  = real(fm0(:, 1)) ; t(:, 3) = real(fb0(:, 1))
   t(:, 4)  = real(fm0(:, 2)) ; t(:, 5) = real(fb0(:, 2))
   t(:, 6)  = real(fm0(:, 3)) ; t(:, 7) = real(fb0(:, 3))
   t(:, 8)  = real(fm1(:, 1)) ; t(:, 9) = aimag(fm1(:, 1))
   t(:, 10) = real(fb1(:, 1)) ; t(:, 11) = aimag(fb1(:, 1))
   endfunction electron_f1

   subroutine electron_readouts(ob, rm, omega_tau, o, stat, errmsg)
   !< Readouts of ob and relative changes against the Maxwellian responses rm (at omega_tau(1:2), the same grid):
   !< T_TS (w <= 2, 3), T_kin, T_slope range on 1 <= u_L <= 4, then sigma, kappa, j_nu, zeta_nu (signed at omega_tau(1),
   !< of the modulus at omega_tau(2)), then the same at omega_tau(1) against the Maxwellian of equal energy (T = T_kin),
   !< built on ob's parameters and number of nodes. stat, errmsg: that Maxwellian's init, as kinetic_operator%init.
   type(kinetic_operator),        intent(in)            :: ob           !< Operator with the distorted f0.
   type(kinetic_response),        intent(in)            :: rm(2)        !< Maxwellian responses at omega_tau(1:2).
   real(R8P),                     intent(in)            :: omega_tau(2) !< Hall parameters.
   real(R8P),                     intent(out)           :: o(n_readouts) !< The readouts.
   integer(I4P),                  intent(out), optional :: stat         !< 0, or 1 when the equal-energy init fails.
   character(len=:), allocatable, intent(out), optional :: errmsg       !< Why it failed.
   type(kinetic_operator)                               :: ot           !< Maxwellian at T_kin.
   type(kinetic_response)                               :: rt, rb       !< Responses: of ot, of ob.
   real(R8P)                                            :: t(ob%grid%n) !< Slope temperature.
   logical                                              :: win(ob%grid%n) !< Nodes in the ECE window.

   t = slope_temperature(ob)
   win = sqrt(2._R8P) * ob%grid%u >= ece_window(1) .and. sqrt(2._R8P) * ob%grid%u <= ece_window(2)
   o(1:5) = [ts_temperature(ob, ts_windows(1)), ts_temperature(ob, ts_windows(2)), kinetic_temperature(ob), &
             minval(t, mask=win), maxval(t, mask=win)]
   rb = ob%response(omega_tau=omega_tau(1))
   o(6:9) = [real(rb%sigma / rm(1)%sigma, R8P), real(rb%kappa() / rm(1)%kappa(), R8P), &
             real(rb%j_nu / rm(1)%j_nu, R8P),   real(rb%zeta_nu / rm(1)%zeta_nu, R8P)] - 1._R8P
   rb = ob%response(omega_tau=omega_tau(2))
   o(10:13) = [abs(rb%sigma / rm(2)%sigma), abs(rb%kappa() / rm(2)%kappa()), &
               abs(rb%j_nu / rm(2)%j_nu),   abs(rb%zeta_nu / rm(2)%zeta_nu)] - 1._R8P
   call ot%init(par=ob%par, n_nodes=ob%grid%n, electrons=electron_maxwellian, electron_params=[o(3)], &
                stat=stat, errmsg=errmsg)
   if (present(stat)) then
      if (stat /= 0_I4P) then
         o(14:17) = 0._R8P ; return
      endif
   endif
   rt = ot%response(omega_tau=omega_tau(1))
   rb = ob%response(omega_tau=omega_tau(1))
   o(14:17) = [real(rb%sigma / rt%sigma, R8P), real(rb%kappa() / rt%kappa(), R8P), &
               real(rb%j_nu / rt%j_nu, R8P),   real(rb%zeta_nu / rt%zeta_nu, R8P)] - 1._R8P
   endsubroutine electron_readouts

   subroutine electron_scan_row(ob, rm, omega_tau, o, max_dev, monotone, stat, errmsg)
   !< One row of a scan: the readouts of ob, the largest |T_slope - T_TS(w <= 2)| in the ECE window, and whether f0
   !< decreases monotonically there (1) or not (0: the slope temperature diverges where df0 >= 0).
   type(kinetic_operator),        intent(in)            :: ob           !< Operator with the distorted f0.
   type(kinetic_response),        intent(in)            :: rm(2)        !< Maxwellian responses at omega_tau(1:2).
   real(R8P),                     intent(in)            :: omega_tau(2) !< Hall parameters.
   real(R8P),                     intent(out)           :: o(n_readouts) !< The readouts (electron_readouts).
   real(R8P),                     intent(out)           :: max_dev      !< max |T_slope - T_TS(w <= 2)| in the window.
   integer(I4P),                  intent(out)           :: monotone     !< 1 when df0 < 0 throughout the window.
   integer(I4P),                  intent(out), optional :: stat         !< As electron_readouts.
   character(len=:), allocatable, intent(out), optional :: errmsg       !< As electron_readouts.
   real(R8P)                                            :: t(ob%grid%n) !< Slope temperature.
   logical                                              :: win(ob%grid%n) !< Nodes in the ECE window.

   call electron_readouts(ob, rm, omega_tau, o, stat, errmsg)
   t = slope_temperature(ob)
   win = sqrt(2._R8P) * ob%grid%u >= ece_window(1) .and. sqrt(2._R8P) * ob%grid%u <= ece_window(2)
   max_dev = maxval(abs(t - o(1)), mask=win)
   monotone = merge(1_I4P, 0_I4P, all(ob%df0 < 0._R8P .or. .not. win))
   endsubroutine electron_scan_row

   subroutine write_table(unit, t)
   !< Write a profile or f1 table (rows of ES15.6), the drivers' format.
   integer(I4P), intent(in) :: unit    !< Open unit, its header written.
   real(R8P),    intent(in) :: t(:,:)  !< The table.
   integer(I4P)             :: j       !< Row.
   character(len=16)        :: fmt     !< Format.

   write(fmt, '(A,I0,A)') '(', size(t, dim=2), 'ES15.6)'
   do j = 1_I4P, size(t, dim=1, kind=I4P)
      write(unit, fmt) t(j, :)
   enddo
   endsubroutine write_table

   subroutine write_scan_row(unit, p, o, max_dev, monotone)
   !< Write one scan row: the parameter, T_TS (2), T_kin, T_slope range, max_dev, monotone, the 12 relative changes.
   integer(I4P), intent(in) :: unit           !< Open unit, its header written.
   real(R8P),    intent(in) :: p              !< Value of the varied parameter.
   real(R8P),    intent(in) :: o(n_readouts)  !< Readouts.
   real(R8P),    intent(in) :: max_dev        !< max |T_slope - T_TS|.
   integer(I4P), intent(in) :: monotone       !< 1 or 0.

   write(unit, '(7ES15.6,I3,12ES15.6)') p, o(1:5), max_dev, monotone, o(6:)
   endsubroutine write_scan_row
endmodule appelbe_electron_study
