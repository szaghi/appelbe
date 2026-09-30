!< Transport-equation terms driven by electron-fast ion collisions (Secs. IV-V), from a closure (j_nu, zeta_nu).
module appelbe_closure
!< Transport-equation terms driven by electron-fast ion collisions (Secs. IV-V), from a closure (j_nu, zeta_nu).
!<
!< All vectors are complex numbers (perp, wedge) = (real, imag) in the plane orthogonal to B, perp along the fast-ion
!< flux and wedge along b x flux (Eq. 27). Products of tensors are complex products; in an unmagnetised plasma only the
!< real part survives.
use penf, only : R8P

implicit none
private
public :: heat_flow_thermoelectric, heat_flow_direct, advection_velocity, field_generation_rate

contains
   elemental function heat_flow_thermoelectric(te, z_a, beta, j_nu) result(q)
   !< Heat flow carried by the collisionally induced current per unit fast-ion flux, (T_e/e)(beta + 5/2) j0_ea, [W s].
   !<
   !< From Eq. (24) with j_T = 0: -(T_e/e)(beta + 5/2).(j_T - j0_ea); with j0_ea = Z_a e n_a <v_a> j_nu (Eqs. 33-35).
   real(R8P),    intent(in) :: te   !< Electron temperature [J].
   real(R8P),    intent(in) :: z_a  !< Fast-ion charge state.
   complex(R8P), intent(in) :: beta !< Thermoelectric tensor (perp, wedge) (Eq. 26).
   complex(R8P), intent(in) :: j_nu !< j0_ea / (Z_a e n_a <v_a>).
   complex(R8P)             :: q    !< q / (n_a <v_a>) [W s].

   q = te * z_a * (beta + 2.5_R8P) * j_nu
   endfunction heat_flow_thermoelectric

   elemental function heat_flow_direct(te, zeta_nu) result(q)
   !< Heat flow generated directly by the collisions per unit fast-ion flux, zeta_ea / (n_a <v_a>) [W s] (Eqs. 17, C3-C4).
   real(R8P),    intent(in) :: te      !< Electron temperature [J].
   complex(R8P), intent(in) :: zeta_nu !< zeta_ea / (n_a <v_a> T_e).
   complex(R8P)             :: q       !< q / (n_a <v_a>) [W s].

   q = te * zeta_nu
   endfunction heat_flow_direct

   elemental function advection_velocity(z_a, n_ratio, v_drift, j_nu) result(u)
   !< Magnetic-field advection velocity j0_ea / (e n_e) = Z_a (n_a/n_e) <v_a> j_nu (Eq. 40) [m/s].
   real(R8P),    intent(in) :: z_a     !< Fast-ion charge state.
   real(R8P),    intent(in) :: n_ratio !< n_a / n_e.
   real(R8P),    intent(in) :: v_drift !< Fast-ion drift speed |<v_a>| [m/s].
   complex(R8P), intent(in) :: j_nu    !< j0_ea / (Z_a e n_a <v_a>).
   complex(R8P)             :: u       !< Advection velocity (perp, wedge) [m/s].

   u = z_a * n_ratio * v_drift * j_nu
   endfunction advection_velocity

   elemental function field_generation_rate(coef, dj_dr, j, te, dte_dr) result(rate)
   !< Azimuthal field generation by an axial j0_ea(r) in an unmagnetised plasma (Eq. 43 written with Eq. 41) [T/s]:
   !<
   !<    dB_theta/dt = coef * [ -dj/dr + (3/2) (j/T_e) dT_e/dr ],   coef = alpha_par / (e n_e)^2 at T_e,
   !<
   !< the second term coming from alpha_par being proportional to T_e^(-3/2).
   real(R8P), intent(in) :: coef   !< alpha_par / (e n_e)^2 [Ohm m] (see appelbe_plasma: resistive_coefficient).
   real(R8P), intent(in) :: dj_dr  !< Radial gradient of the axial j0_ea [A m^-3].
   real(R8P), intent(in) :: j      !< Axial j0_ea [A m^-2].
   real(R8P), intent(in) :: te     !< Electron temperature (any unit, consistent with dte_dr).
   real(R8P), intent(in) :: dte_dr !< Radial temperature gradient [te unit / m].
   real(R8P)             :: rate   !< dB_theta/dt [T/s].

   rate = coef * (-dj_dr + 1.5_R8P * j / te * dte_dr)
   endfunction field_generation_rate
endmodule appelbe_closure
