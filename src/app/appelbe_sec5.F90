!< Sec. V: magnetic-field advection (Eq. 40) and generation (Eqs. 41-43) by electron-fast ion collisions.
program appelbe_sec5
!< Sec. V: magnetic-field advection (Eq. 40) and generation (Eqs. 41-43) by electron-fast ion collisions.
!<
!< A. Advection velocity j0_ea/(e n_e) for alphas, n_a/n_e = 1e-3, <v_a> = 1e7 m/s, versus omega tau (Sec. V A).
!< B. Ion fast ignition: 200 MeV C6+ beam, j0_a = 3.4e17 A/m^2, radius 10 um, 400 g/cc DT, uniform T_e (Sec. V B).
!< C. Alpha flux 1e34 m^-2 s^-1 across a 1 keV/um temperature gradient, hotspot density 1e5 kg/m^3 (Sec. V B).
!< Coulomb logarithms from the NRL formula; alpha_par from the kinetic solver (Eq. 42 gives 0.506 for Z_i = 1).
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_closure,               only : advection_velocity, field_generation_rate
use appelbe_constants,             only : e_charge, m_e, m_alpha, m_carbon12, m_DT, keV_J, MeV_J
use appelbe_fits,                  only : fit_response
use appelbe_io,                    only : open_results
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_plasma,                only : speed_ratio, coulomb_log_ei_nrl, resistive_coefficient

implicit none
type(kinetic_params)   :: par                            !< Physical parameters.
type(kinetic_operator) :: op                             !< Kinetic operator.
type(kinetic_response) :: r                              !< Kinetic response.
complex(R8P)           :: j_fit, zeta_fit, u_adv(2)      !< Algebraic closure, advection velocity (kinetic, fit).
real(R8P)              :: te, n_e, lnl, coef, alpha_hat  !< T_e [J], n_e [m^-3], ln(Lambda), resistive coef., alpha_par.
real(R8P)              :: j_ea(2), rate(2)               !< Induced current [A/m^2], dB/dt [T/s], (kinetic, fit).
real(R8P)              :: x                              !< log10(omega tau).
integer(I4P)           :: k, i, unit                     !< Counters, output unit.
integer(I4P)           :: unit_a, unit_b, unit_c         !< Machine-readable tables of scenarios A, B, C.
real(R8P), parameter   :: e_alpha    = 3.45_R8P * MeV_J  !< Alpha energy [J].
real(R8P), parameter   :: e_carbon   = 200._R8P * MeV_J  !< Carbon-beam ion energy [J].
real(R8P), parameter   :: te_list(4) = [1._R8P, 2._R8P, 5._R8P, 10._R8P] !< Electron temperatures [keV].

unit   = open_results('sec5.txt', 'Sec. V reproduction (see appelbe_sec5.F90 for the scenarios)')
unit_a = open_results('sec5_advection.dat', 'Te_keV log10_wt u_perp_kin u_wedge_kin u_perp_fit u_wedge_fit')
unit_b = open_results('sec5_carbon.dat', 'Te_keV v_a/v_Te j_ratio lnL_ei alpha_par dBdt')
unit_c = open_results('sec5_gradient.dat', 'Te_keV lnL_ei j_ea_kin j_ea_fit dBdt_kin dBdt_fit')

! A. advection velocity
call emit('A. Advection velocity j0_ea/(e n_e) [m/s], alphas, n_a/n_e = 1e-3, <v_a> = 1e7 m/s (paper: up to ~1e4 m/s)')
call emit('    T_e[keV]   log10(wt)  u_perp_kin u_wedge_kin  u_perp_fit u_wedge_fit')
par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
do k = 1_I4P, size(te_list, kind=I4P), 2_I4P
   te      = te_list(k) * keV_J
   par%u_a = speed_ratio(e_alpha, m_alpha, te)
   call op%init(par=par)
   do i = -3_I4P, 3_I4P
      x = real(i, R8P)
      r = op%response(omega_tau=10._R8P**x)
      call fit_response(par%u_a, 10._R8P**x, j_fit, zeta_fit)
      u_adv = advection_velocity(par%z_a, 1.e-3_R8P, 1.e7_R8P, [r%j_nu, j_fit])
      call emit(fmt_row([te_list(k), x, real(u_adv(1), R8P), aimag(u_adv(1)), real(u_adv(2), R8P), aimag(u_adv(2))]))
      write(unit_a, '(6ES14.5)') te_list(k), x, real(u_adv(1), R8P), aimag(u_adv(1)), real(u_adv(2), R8P), aimag(u_adv(2))
   enddo
enddo
call emit('')

! B. carbon ion beam, fast ignition
call emit('B. Ion fast ignition: C6+ 200 MeV, j0_a = 3.4e17 A/m^2, R = 10 um, 400 g/cc DT (paper: 1e13-1e15 T/s)')
call emit('    T_e[keV]    v_a/v_Te  j0_ea/j0_a      lnL_ei   alpha_par  dB/dt[T/s]')
par%z_i = 1._R8P ; par%z_a = 6._R8P ; par%mass_ratio = m_e / m_carbon12
n_e = 4.e5_R8P / m_DT ! 400 g/cc = 4e5 kg/m^3; n_e = n_i for DT
do k = 1_I4P, size(te_list, kind=I4P)
   te      = te_list(k) * keV_J
   par%u_a = speed_ratio(e_carbon, m_carbon12, te)
   call op%init(par=par, u_max=max(7._R8P, 2._R8P * par%u_a))
   r = op%response(omega_tau=0._R8P)
   alpha_hat = real(r%resistivity(), R8P)
   lnl  = coulomb_log_ei_nrl(n_e, te)
   coef = resistive_coefficient(te, par%z_i, lnl, alpha_hat)
   ! beam edge: |dj/dr| ~ |j0_ea| / R, uniform T_e
   j_ea(1) = real(r%j_nu, R8P) * 3.4e17_R8P
   rate(1) = abs(field_generation_rate(coef, j_ea(1) / 10.e-6_R8P, j_ea(1), te, 0._R8P))
   call emit(fmt_row([te_list(k), par%u_a, real(r%j_nu, R8P), lnl, alpha_hat, rate(1)]))
   write(unit_b, '(6ES14.5)') te_list(k), par%u_a, real(r%j_nu, R8P), lnl, alpha_hat, rate(1)
enddo
call emit('')

! C. alpha flux across a temperature gradient
call emit('C. Alpha flux 1e34 m^-2 s^-1 across grad T_e = 1 keV/um, hotspot 1e5 kg/m^3')
call emit('   (paper: j0_ea ~ 6e15 A/m^2 and dB/dt ~ 6e13 T_keV^-5/2 T/s)')
call emit('    T_e[keV]      lnL_ei   j0_ea_kin   j0_ea_fit    dBdt_kin    dBdt_fit dBdt*T^2.5')
par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
n_e = 1.e5_R8P / m_DT
do k = 1_I4P, size(te_list, kind=I4P)
   te      = te_list(k) * keV_J
   par%u_a = speed_ratio(e_alpha, m_alpha, te)
   call op%init(par=par)
   r = op%response(omega_tau=0._R8P)
   call fit_response(par%u_a, 0._R8P, j_fit, zeta_fit)
   alpha_hat = real(r%resistivity(), R8P)
   lnl  = coulomb_log_ei_nrl(n_e, te)
   coef = resistive_coefficient(te, par%z_i, lnl, alpha_hat)
   j_ea = par%z_a * e_charge * 1.e34_R8P * [real(r%j_nu, R8P), real(j_fit, R8P)]
   ! uniform current, T_e in keV, dT/dr = 1 keV/um = 1e6 keV/m
   rate = abs(field_generation_rate(coef, 0._R8P, j_ea, te_list(k), 1.e6_R8P))
   call emit(fmt_row([te_list(k), lnl, j_ea(1), j_ea(2), rate(1), rate(2), rate(1) * te_list(k)**2.5_R8P]))
   write(unit_c, '(6ES14.5)') te_list(k), lnl, j_ea(1), j_ea(2), rate(1), rate(2)
enddo
close(unit) ; close(unit_a) ; close(unit_b) ; close(unit_c)

contains
   subroutine emit(line)
   !< Write a line to stdout and to results/sec5.txt.
   character(*), intent(in) :: line !< Line.

   write(output_unit, '(A)') trim(line)
   write(unit, '(A)') trim(line)
   endsubroutine emit

   function fmt_row(values) result(line)
   !< Format a row of reals.
   real(R8P), intent(in) :: values(:) !< Values.
   character(len=256)    :: line      !< Formatted row.

   write(line, '(*(ES12.4))') values
   endfunction fmt_row
endprogram appelbe_sec5
