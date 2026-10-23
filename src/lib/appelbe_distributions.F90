!< Speed distributions for the kinetic solver: fast-ion energy spectra (footnote 30) and non-Maxwellian electron f0.
module appelbe_distributions
!< Speed distributions for the kinetic solver: fast-ion energy spectra (footnote 30) and non-Maxwellian electron f0.
!<
!< Each function has the speed_distribution interface of appelbe_kinetic: F(u; p) up to a constant (the solver normalises
!< it), u = v / v_Te. Energy spectra dN/dE become speed distributions through dN = 4 pi u^2 F du and dE ~ u du, so
!< F ~ (dN/dE) / u. Energies are measured by x = (u / u_0)^2 = E / E_0.
use penf, only : R8P

implicit none
private
public :: energy_gaussian, energy_flat, slowing_down
public :: electron_maxwellian, electron_bipolar, electron_table, electron_table_params

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

   pure function electron_maxwellian(u, p) result(f)
   !< Electron Maxwellian at temperature T, exp(-u^2 T_e / T), u = v / v_Te: with T = T_e the default f0 through the
   !< general path of the solver; with T /= T_e the equal-energy reference of a distorted f0 (T = its kinetic temperature).
   real(R8P), intent(in) :: u    !< Normalised speed.
   real(R8P), intent(in) :: p(:) !< [T / T_e].
   real(R8P)             :: f    !< f0(u), unnormalised.

   f = exp(-u**2 / p(1))
   endfunction electron_maxwellian

   pure function electron_bipolar(u, p) result(f)
   !< Maxwellian with the bipolar distortion of Fontana et al. (2023) and Senni et al. (ICFDT 2026, Eq. 21):
   !<
   !<    f0 = exp(-u^2) [1 + A g(x)],   g(x) = x exp(-x^2/2),   x = (sqrt(2) u - u_0) / w,
   !<
   !< u = v / v_Te. u_0 and w are in units of the thermal momentum sqrt(m_e T_e) (as in the slides), hence the sqrt(2).
   !< Non-relativistic base: the solver's collision operator is non-relativistic. g is odd about u_0, so density and
   !< energy change only through the u^2 weighting (the solver renormalises the density).
   real(R8P), intent(in) :: u    !< Normalised speed.
   real(R8P), intent(in) :: p(:) !< [A, u_0, w].
   real(R8P)             :: f    !< f0(u), unnormalised.
   real(R8P)             :: x    !< Distance from the feature in widths.

   x = (sqrt(2._R8P) * u - p(2)) / p(3)
   f = exp(-u**2) * (1._R8P + p(1) * x * exp(-0.5_R8P * x**2))
   endfunction electron_bipolar

   pure function electron_table(u, p) result(f)
   !< Tabulated electron f0 (e.g. from INDACO), as packed by electron_table_params: p = [n, x(1:n), ln f(1:n), M(1:n)],
   !< x = u_L = p / sqrt(m_e T_e) = sqrt(2) u, x(1) = 0, increasing. ln f is a cubic spline, C2, with zero slope at the
   !< origin (f0 is smooth in 3-D velocity) and zero curvature at x(n), continued linearly beyond x(n): the table must
   !< decay there, or init rejects f0 at u_max. Non-relativistic: x is the speed in units of sqrt(T_e / m_e).
   real(R8P), intent(in) :: u    !< Normalised speed.
   real(R8P), intent(in) :: p(:) !< [n, x(1:n), ln f(1:n), M(1:n)] (M: spline second derivatives).
   real(R8P)             :: f    !< f0(u), unnormalised.
   real(R8P)             :: x, h, a, b !< Abscissa, interval, distances from its ends.
   integer               :: n, i       !< Table size, interval.

   n = nint(p(1))
   x = sqrt(2._R8P) * u
   associate(xt => p(2:n+1), yt => p(n+2:2*n+1), mt => p(2*n+2:3*n+1))
      if (x >= xt(n)) then
         h = xt(n) - xt(n-1)
         f = exp(yt(n) + ((yt(n) - yt(n-1)) / h + h * mt(n-1) / 6._R8P) * (x - xt(n)))
         return
      endif
      i = max(1, min(n - 1, count(xt <= x)))
      h = xt(i+1) - xt(i) ; a = xt(i+1) - x ; b = x - xt(i)
      f = exp((mt(i) * a**3 + mt(i+1) * b**3) / (6._R8P * h) + (yt(i) / h - mt(i) * h / 6._R8P) * a &
              + (yt(i+1) / h - mt(i+1) * h / 6._R8P) * b)
   endassociate
   endfunction electron_table

   pure function electron_table_params(x, f) result(p)
   !< Pack a table f(x), x = u_L = p / sqrt(m_e T_e), for electron_table: spline of ln f with ln f'(0) = 0, M(n) = 0.
   real(R8P), intent(in)  :: x(:)          !< Nodes, x(1) = 0, strictly increasing.
   real(R8P), intent(in)  :: f(:)          !< f0 at the nodes, > 0 (any scale: the solver normalises).
   real(R8P), allocatable :: p(:)          !< [n, x, ln f, M].
   real(R8P)              :: y(size(x)), m(size(x)), d(size(x)), c(size(x)), r(size(x)), h(size(x)) !< Thomas sweep.
   integer                :: n, i          !< Table size, node.

   n = size(x)
   if (n < 3 .or. size(f) /= n) error stop 'electron_table_params: need n >= 3 nodes and as many values'
   if (abs(x(1)) > 0._R8P .or. any(x(2:) <= x(:n-1))) error stop 'electron_table_params: x(1) = 0, increasing'
   if (any(f <= 0._R8P)) error stop 'electron_table_params: f must be positive'
   y = log(f)
   h(:n-1) = x(2:) - x(:n-1)
   ! clamped left end, 2 h_1 M_1 + h_1 M_2 = 6 (y_2 - y_1) / h_1; interior rows; M_n = 0
   d(1) = 2._R8P * h(1) ; c(1) = h(1) ; r(1) = 6._R8P * (y(2) - y(1)) / h(1)
   do i = 2, n - 1
      d(i) = 2._R8P * (h(i-1) + h(i)) - h(i-1) * c(i-1) / d(i-1)
      c(i) = h(i)
      r(i) = 6._R8P * ((y(i+1) - y(i)) / h(i) - (y(i) - y(i-1)) / h(i-1)) - h(i-1) * r(i-1) / d(i-1)
   enddo
   m(n) = 0._R8P
   do i = n - 1, 1, -1
      m(i) = (r(i) - c(i) * m(i+1)) / d(i)
   enddo
   p = [real(n, R8P), x, y, m]
   endfunction electron_table_params

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
