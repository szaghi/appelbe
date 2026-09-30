!< Dimensional plasma helpers: thermal speeds, collision time (Eq. 14), Coulomb logarithm, resistive coefficient (Eqs. 41-43).
module appelbe_plasma
!< Dimensional plasma helpers: thermal speeds, collision time (Eq. 14), Coulomb logarithm, resistive coefficient (Eqs. 41-43).
use penf,              only : R8P
use appelbe_constants, only : pi, sqrt_pi, e_charge, m_e, eps0

implicit none
private
public :: thermal_speed, speed_ratio, collision_y_ei, tau_ei, coulomb_log_ei_nrl, resistive_coefficient

contains
   elemental function thermal_speed(te) result(v)
   !< Electron thermal speed v_Te = sqrt(2 T_e / m_e) (after Eq. 4).
   real(R8P), intent(in) :: te !< Electron temperature [J].
   real(R8P)             :: v  !< Thermal speed [m/s].

   v = sqrt(2._R8P * te / m_e)
   endfunction thermal_speed

   elemental function speed_ratio(energy, mass, te) result(ratio)
   !< Fast-ion to electron thermal speed ratio v_a/v_Te, with v_a = sqrt(2 E_a / m_a) (after Eq. 30).
   real(R8P), intent(in) :: energy !< Fast-ion energy [J].
   real(R8P), intent(in) :: mass   !< Fast-ion mass [kg].
   real(R8P), intent(in) :: te     !< Electron temperature [J].
   real(R8P)             :: ratio  !< v_a / v_Te.

   ratio = sqrt(energy * m_e / (te * mass))
   endfunction speed_ratio

   elemental function collision_y_ei(z_i, lnl) result(y)
   !< Y_ei = (1/4pi) (Z_i e^2 / (eps0 m_e))^2 ln(Lambda_ei) (Eq. 10).
   real(R8P), intent(in) :: z_i !< Thermal ion charge state.
   real(R8P), intent(in) :: lnl !< Coulomb logarithm.
   real(R8P)             :: y   !< Y_ei [m^6 s^-4].

   y = (z_i * e_charge**2 / (eps0 * m_e))**2 * lnl / (4._R8P * pi)
   endfunction collision_y_ei

   elemental function tau_ei(te, n_i, z_i, lnl) result(tau)
   !< Electron-ion collision time tau_ei = 3 sqrt(pi) v_Te^3 / (4 Y_ei n_i) (Eq. 14), identical to Braginskii tau_e.
   real(R8P), intent(in) :: te  !< Electron temperature [J].
   real(R8P), intent(in) :: n_i !< Thermal ion density [m^-3].
   real(R8P), intent(in) :: z_i !< Thermal ion charge state.
   real(R8P), intent(in) :: lnl !< Coulomb logarithm.
   real(R8P)             :: tau !< Collision time [s].

   tau = 3._R8P * sqrt_pi * thermal_speed(te)**3 / (4._R8P * collision_y_ei(z_i, lnl) * n_i)
   endfunction tau_ei

   elemental function coulomb_log_ei_nrl(n_e, te) result(lnl)
   !< Electron-ion Coulomb logarithm, NRL Plasma Formulary (T_e > 10 Z^2 eV branch): 24 - ln(n_e[cm^-3]^(1/2) / T_e[eV]).
   real(R8P), intent(in) :: n_e !< Electron density [m^-3].
   real(R8P), intent(in) :: te  !< Electron temperature [J].
   real(R8P)             :: lnl !< Coulomb logarithm.

   lnl = 24._R8P - log(sqrt(n_e * 1.e-6_R8P) / (te / e_charge))
   endfunction coulomb_log_ei_nrl

   elemental function resistive_coefficient(te, z_i, lnl, alpha_hat) result(coef)
   !< Coefficient alpha_par / (e n_e)^2 of the field-generation term in Eq. (41), with alpha_par = alpha_hat m_e n_e / tau_ei.
   !<
   !< The density cancels (n_e = Z_i n_i), so the result depends on T_e, Z_i and ln(Lambda) only. With alpha_hat = 0.506,
   !< Z_i = 1, ln(Lambda) = 1 and T_e = 1 keV it is the 1.65e-9 prefactor of Eq. (43). Multiplied by a current-density
   !< gradient [A m^-3] it gives dB/dt [T s^-1].
   real(R8P), intent(in) :: te        !< Electron temperature [J].
   real(R8P), intent(in) :: z_i       !< Thermal ion charge state.
   real(R8P), intent(in) :: lnl       !< Coulomb logarithm.
   real(R8P), intent(in) :: alpha_hat !< Parallel resistivity in units of m_e n_e / tau_ei (Eq. 42).
   real(R8P)             :: coef      !< alpha_par / (e n_e)^2 [Ohm m].
   real(R8P)             :: n_i       !< Arbitrary ion density; cancels.

   n_i = 1._R8P
   coef = alpha_hat * m_e / (e_charge**2 * z_i * n_i * tau_ei(te, n_i, z_i, lnl))
   endfunction resistive_coefficient
endmodule appelbe_plasma
