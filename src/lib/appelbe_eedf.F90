!< What diagnostics read from the electron f0 of a kinetic operator: Thomson-scattering and ECE temperatures.
module appelbe_eedf
!< What diagnostics read from the electron f0 of a kinetic operator: Thomson-scattering and ECE temperatures.
!<
!< Temperatures are in units of the reference T_e that defines v_Te (u = v / v_Te); a Maxwellian gives 1 for each.
!<
!< - Thomson scattering, incoherent and non-relativistic (Senni et al., ICFDT 2026, Eq. 7): the spectrum is the projection
!<   of f0 on the scattering vector, S(w) = int f0 delta(w - k.v/k) d^3u = 2 pi int_|w|^inf f0(u) u du, w = Delta omega
!<   / (k v_Te). A Maxwellian gives exp(-w^2); the temperature is the width of a Gaussian fitted to ln S over a window
!<   (ts_temperature), or the energy moment (2/3) <u^2> (kinetic_temperature).
!< - ECE, optically thick, in the narrow-resonance limit: emission is linear in f0 and absorption in its derivative
!<   (Eqs. 19-20 of the slides), so the radiation temperature is the local log-slope temperature at the resonant energy,
!<   T(u) = -1 / (d ln f0 / dE) = -2 u f0 / (df0/du) (slope_temperature). A finite optical depth and the spread of the
!<   resonance average this over the emitting electrons; the forward model of an actual ECE channel is beyond this module.
use penf,            only : I4P, R8P
use appelbe_kinetic, only : kinetic_operator

implicit none
private
public :: slope_temperature, ts_spectrum, ts_temperature, kinetic_temperature

real(R8P), parameter :: pi = acos(-1._R8P) !< Pi.

contains
   pure function slope_temperature(op) result(t)
   !< Local log-slope temperature -2 u f0 / (df0/du) on the grid (node 1, where it is 0/0, takes the value of node 2).
   type(kinetic_operator), intent(in) :: op              !< Operator, initialised.
   real(R8P)                          :: t(op%grid%n)    !< T(u) / T_e.

   t(2:) = -2._R8P * op%grid%u(2:) * op%f0(2:) / op%df0(2:)
   t(1)  = t(2)
   endfunction slope_temperature

   pure function ts_spectrum(op) result(s)
   !< Incoherent Thomson spectrum S(w) = 2 pi int_w^inf f0(u) u du at w = u_j, normalised to S(0) = 1.
   type(kinetic_operator), intent(in) :: op           !< Operator, initialised.
   real(R8P)                          :: s(op%grid%n) !< S(w_j).
   integer(I4P)                       :: j            !< Node.

   do j = 1_I4P, op%grid%n
      s(j) = 2._R8P * pi * sum(op%grid%upper_weights(j) * op%f0 * op%grid%u)
   enddo
   s = s / s(1)
   endfunction ts_spectrum

   pure function ts_temperature(op, w_max) result(t)
   !< Temperature from a Gaussian fit of the Thomson spectrum: least squares of ln S = c - w^2 / T over 0 <= w <= w_max.
   type(kinetic_operator), intent(in) :: op     !< Operator, initialised.
   real(R8P),              intent(in) :: w_max  !< Fit window in units of k v_Te (a Maxwellian gives T = 1 for any).
   real(R8P)                          :: t      !< T / T_e.
   real(R8P)                          :: s(op%grid%n), x(op%grid%n), y(op%grid%n) !< Spectrum, w^2, ln S.
   real(R8P)                          :: xm, ym !< Means.
   logical                            :: m(op%grid%n) !< Points in the window.

   s = ts_spectrum(op)
   m = op%grid%u <= w_max .and. s > 0._R8P
   x = op%grid%u**2
   y = 0._R8P
   where (m) y = log(s)
   xm = sum(x, mask=m) / count(m)
   ym = sum(y, mask=m) / count(m)
   t = -sum((x - xm)**2, mask=m) / sum((x - xm) * (y - ym), mask=m)
   endfunction ts_temperature

   pure function kinetic_temperature(op) result(t)
   !< Energy-moment temperature (2/3) <u^2> = (2/3) 4 pi int u^4 f0 du.
   type(kinetic_operator), intent(in) :: op !< Operator, initialised.
   real(R8P)                          :: t  !< T / T_e.

   t = 2._R8P / 3._R8P * 4._R8P * pi * sum(op%grid%lower_weights(op%grid%n) * op%grid%u**4 * op%f0)
   endfunction kinetic_temperature
endmodule appelbe_eedf
