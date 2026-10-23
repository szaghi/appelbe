!< Fast-ion speed distributions with an energy spread, for the kinetic solver (footnote 30 of the paper).
module appelbe_distributions
!< Fast-ion speed distributions with an energy spread, for the kinetic solver (footnote 30 of the paper).
!<
!< Each function has the speed_distribution interface of appelbe_kinetic: F(u; p) up to a constant (the solver normalises
!< it), u = v / v_Te. Energy spectra dN/dE become speed distributions through dN = 4 pi u^2 F du and dE ~ u du, so
!< F ~ (dN/dE) / u. Energies are measured by x = (u / u_0)^2 = E / E_0.
use penf, only : R8P

implicit none
private
public :: energy_gaussian, energy_flat, slowing_down

contains
   pure function energy_gaussian(u, p) result(f)
   !< Gaussian energy spectrum, dN/dE ~ exp(-(E - E_0)^2 / (2 sigma^2)), truncated at E = 0.
   real(R8P), intent(in) :: u    !< Normalised speed.
   real(R8P), intent(in) :: p(:) !< [u_0 (speed at E_0), sigma / E_0].
   real(R8P)             :: f    !< F(u), unnormalised.

   f = 0._R8P
   if (u > 0._R8P) f = exp(-((u / p(1))**2 - 1._R8P)**2 / (2._R8P * p(2)**2)) / u
   endfunction energy_gaussian

   pure function energy_flat(u, p) result(f)
   !< Flat energy spectrum on [E_0 (1 - w), E_0 (1 + w)], with logistic edges of width d E_0 (smooth, so that the solver
   !< keeps its second-order accuracy).
   real(R8P), intent(in) :: u    !< Normalised speed.
   real(R8P), intent(in) :: p(:) !< [u_0 (speed at E_0), w, d].
   real(R8P)             :: f    !< F(u), unnormalised.
   real(R8P)             :: x    !< E / E_0.

   f = 0._R8P
   if (u <= 0._R8P) return
   x = (u / p(1))**2
   f = logistic((1._R8P - p(2) - x) / p(3)) * logistic((x - 1._R8P - p(2)) / p(3)) / u
   endfunction energy_flat

   pure function slowing_down(u, p) result(f)
   !< Classical slowing-down distribution of fast ions born at speed u_b: F ~ 1 / (u^3 + u_c^3) for u < u_b, 1/2 of it at
   !< u = u_b (the node aligned with the birth speed, as the Heaviside step of the monoenergetic case), 0 above.
   real(R8P), intent(in) :: u    !< Normalised speed.
   real(R8P), intent(in) :: p(:) !< [u_b (birth speed), u_c (critical speed)].
   real(R8P)             :: f    !< F(u), unnormalised.

   f = 0._R8P
   if (abs(u - p(1)) <= 1.e-9_R8P * p(1)) then
      f = 0.5_R8P / (u**3 + p(2)**3)
   elseif (u < p(1)) then
      f = 1._R8P / (u**3 + p(2)**3)
   endif
   endfunction slowing_down

   ! private helpers
   elemental function logistic(z) result(s)
   !< 1 / (1 + exp(z)), without overflow for large z.
   real(R8P), intent(in) :: z !< Argument.
   real(R8P)             :: s !< Value.

   if (z > 0._R8P) then
      s = exp(-z) / (1._R8P + exp(-z))
   else
      s = 1._R8P / (1._R8P + exp(z))
   endif
   endfunction logistic
endmodule appelbe_distributions
