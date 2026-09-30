!< The simple-algebraic closure: Appendix C fits of j0_ea and zeta_ea for alpha particles in DT (Eqs. C1-C8, Tables I-IV).
module appelbe_fits
!< The simple-algebraic closure: Appendix C fits of j0_ea and zeta_ea for alpha particles in DT (Eqs. C1-C8, Tables I-IV).
!<
!< Valid for Z_a = 2, Z_i = 1 only. Results are complex numbers (perp, wedge) = (real, imag):
!<    (j0_ea)   = Z_a e n_a <v_a> j_nu    (C1-C2)
!<    (zeta_ea) = n_a <v_a> T_e zeta_nu   (C3-C4), T_e in joules
!<
!< Choices the paper leaves open (see CLAUDE.md):
!< - x = log10(omega tau) is clamped to the fitted range [-3, 3]; fit(-3) matches the omega tau = 0 column to < 0.8%.
!< - Between the six v_a/v_Te nodes the fitted values are interpolated linearly in log(v_a/v_Te); outside [0.025, 1] the
!<   nearest node is used.
use penf, only : I4P, R8P

implicit none
private
public :: n_nodes, v_nodes, fit_response, fit_node_response, fit_zero_column

integer(I4P), parameter :: n_nodes = 6_I4P !< Number of tabulated v_a/v_Te values.
real(R8P),    parameter :: v_nodes(n_nodes) = [1._R8P, 0.5_R8P, 0.33_R8P, 0.25_R8P, 0.1_R8P, 0.025_R8P] !< v_a/v_Te nodes.

! Each table column is one row of the paper's table: (omega tau = 0 value, numerator coefficients, denominator coefficients).
real(R8P), parameter :: table_j_perp(9, n_nodes) = reshape([                                             & !< Table I (C5).
   -1.42_R8P, 9.72_R8P,  7.68_R8P, 41.49_R8P, 9.40_R8P, 2.59_R8P, 26.80_R8P, 18.53_R8P, 19.55_R8P, &
   -1.39_R8P, 8.71_R8P,  9.15_R8P, 36.13_R8P, 6.13_R8P, 2.82_R8P, 23.32_R8P, 16.81_R8P, 18.25_R8P, &
   -1.21_R8P, 8.17_R8P,  9.63_R8P, 33.78_R8P, 6.63_R8P, 2.45_R8P, 22.75_R8P, 16.32_R8P, 18.11_R8P, &
   -1.13_R8P, 7.98_R8P,  9.80_R8P, 33.07_R8P, 6.92_R8P, 2.27_R8P, 22.68_R8P, 16.21_R8P, 18.19_R8P, &
   -1.02_R8P, 7.74_R8P, 10.16_R8P, 32.96_R8P, 7.73_R8P, 2.00_R8P, 23.10_R8P, 16.31_R8P, 18.77_R8P, &
   -0.99_R8P, 7.70_R8P, 10.25_R8P, 32.98_R8P, 7.90_R8P, 1.94_R8P, 23.20_R8P, 16.34_R8P, 18.90_R8P], [9, n_nodes])

real(R8P), parameter :: table_j_wedge(8, n_nodes) = reshape([                                            & !< Table II (C6).
   0._R8P, 0.1145_R8P, 0.1201_R8P, -1.074_R8P, 0.993_R8P, 2.213_R8P, 1.252_R8P, 1.170_R8P, &
   0._R8P, 0.1509_R8P, 0.0895_R8P, -1.410_R8P, 0.523_R8P, 2.314_R8P, 1.382_R8P, 1.559_R8P, &
   0._R8P, 0.1447_R8P, 0.0660_R8P, -1.377_R8P, 0.465_R8P, 2.406_R8P, 1.456_R8P, 1.659_R8P, &
   0._R8P, 0.1396_R8P, 0.0527_R8P, -1.354_R8P, 0.457_R8P, 2.449_R8P, 1.488_R8P, 1.693_R8P, &
   0._R8P, 0.1307_R8P, 0.0450_R8P, -1.283_R8P, 0.461_R8P, 2.459_R8P, 1.496_R8P, 1.699_R8P, &
   0._R8P, 0.1293_R8P, 0.0445_R8P, -1.269_R8P, 0.461_R8P, 2.459_R8P, 1.496_R8P, 1.698_R8P], [8, n_nodes])

real(R8P), parameter :: table_zeta_perp(9, n_nodes) = reshape([                                          & !< Table III (C7).
   14.10_R8P, -14.06_R8P, 61.74_R8P, -81.46_R8P, 35.16_R8P, 6.84_R8P, 26.99_R8P, 23.01_R8P, 16.38_R8P, &
   12.30_R8P, -12.82_R8P, 56.77_R8P, -74.79_R8P, 31.06_R8P, 6.81_R8P, 27.34_R8P, 22.94_R8P, 16.59_R8P, &
   11.14_R8P, -11.68_R8P, 51.80_R8P, -68.22_R8P, 28.16_R8P, 6.81_R8P, 27.39_R8P, 22.93_R8P, 16.62_R8P, &
   10.68_R8P, -11.22_R8P, 49.80_R8P, -65.57_R8P, 27.01_R8P, 6.81_R8P, 27.41_R8P, 22.93_R8P, 16.63_R8P, &
   10.08_R8P, -10.60_R8P, 47.02_R8P, -61.91_R8P, 25.49_R8P, 6.81_R8P, 27.41_R8P, 22.93_R8P, 16.63_R8P, &
    9.96_R8P, -10.48_R8P, 46.50_R8P, -61.23_R8P, 25.21_R8P, 6.81_R8P, 27.41_R8P, 22.93_R8P, 16.63_R8P], [9, n_nodes])

real(R8P), parameter :: table_zeta_wedge(8, n_nodes) = reshape([                                         & !< Table IV (C8).
   0._R8P, -0.6999_R8P, -0.5442_R8P, 6.606_R8P, 1.552_R8P, 3.133_R8P, 2.013_R8P, 1.356_R8P, &
   0._R8P, -0.5771_R8P, -0.4996_R8P, 5.471_R8P, 1.531_R8P, 2.983_R8P, 1.868_R8P, 1.274_R8P, &
   0._R8P, -0.519_R8P,  -0.4577_R8P, 4.920_R8P, 1.528_R8P, 2.962_R8P, 1.849_R8P, 1.262_R8P, &
   0._R8P, -0.4964_R8P, -0.4404_R8P, 4.706_R8P, 1.527_R8P, 2.955_R8P, 1.843_R8P, 1.259_R8P, &
   0._R8P, -0.4680_R8P, -0.4157_R8P, 4.437_R8P, 1.526_R8P, 2.953_R8P, 1.841_R8P, 1.258_R8P, &
   0._R8P, -0.4627_R8P, -0.4110_R8P, 4.387_R8P, 1.526_R8P, 2.953_R8P, 1.841_R8P, 1.258_R8P], [8, n_nodes])

contains
   pure subroutine fit_response(v_ratio, omega_tau, j_nu, zeta_nu)
   !< Algebraic closure at arbitrary v_a/v_Te and omega tau (log-linear interpolation between table nodes).
   real(R8P),    intent(in)  :: v_ratio   !< v_a / v_Te.
   real(R8P),    intent(in)  :: omega_tau !< Electron Hall parameter (>= 0).
   complex(R8P), intent(out) :: j_nu      !< j0_ea / (Z_a e n_a <v_a>), (perp, wedge).
   complex(R8P), intent(out) :: zeta_nu   !< zeta_ea / (n_a <v_a> T_e), (perp, wedge).
   complex(R8P)              :: j_hi, z_hi, j_lo, z_lo !< Values at the bracketing nodes.
   real(R8P)                 :: x, t      !< log10(omega tau), interpolation weight.
   integer(I4P)              :: k         !< Upper bracketing node (larger v_a/v_Te).

   x = clamped_log(omega_tau)
   if (v_ratio >= v_nodes(1)) then
      call fit_node_response(1_I4P, x, j_nu, zeta_nu)
   elseif (v_ratio <= v_nodes(n_nodes)) then
      call fit_node_response(n_nodes, x, j_nu, zeta_nu)
   else
      k = count(v_nodes > v_ratio, kind=I4P)
      call fit_node_response(k,         x, j_hi, z_hi)
      call fit_node_response(k + 1_I4P, x, j_lo, z_lo)
      t = log(v_ratio / v_nodes(k + 1)) / log(v_nodes(k) / v_nodes(k + 1))
      j_nu    = t * j_hi + (1._R8P - t) * j_lo
      zeta_nu = t * z_hi + (1._R8P - t) * z_lo
   endif
   endsubroutine fit_response

   pure subroutine fit_node_response(k, x, j_nu, zeta_nu)
   !< Evaluate the four rational fits (Eqs. C5-C8) of table row k at x = log10(omega tau), without clamping.
   integer(I4P), intent(in)  :: k       !< Table row (1..n_nodes).
   real(R8P),    intent(in)  :: x       !< log10(omega tau).
   complex(R8P), intent(out) :: j_nu    !< (j_perp, j_wedge).
   complex(R8P), intent(out) :: zeta_nu !< (zeta_perp, zeta_wedge).

   j_nu    = cmplx(cubic_over_quartic(table_j_perp(2:5, k),       table_j_perp(6:9, k),       x), &
                   quadratic_over_quartic(table_j_wedge(2:4, k),    table_j_wedge(5:8, k),    x), kind=R8P)
   zeta_nu = cmplx(cubic_over_quartic(table_zeta_perp(2:5, k),    table_zeta_perp(6:9, k),    x), &
                   quadratic_over_quartic(table_zeta_wedge(2:4, k), table_zeta_wedge(5:8, k), x), kind=R8P)
   endsubroutine fit_node_response

   pure subroutine fit_zero_column(k, j_perp0, zeta_perp0)
   !< Tabulated omega tau = 0 values of row k (the wedge components vanish there).
   integer(I4P), intent(in)  :: k          !< Table row (1..n_nodes).
   real(R8P),    intent(out) :: j_perp0    !< j_perp at omega tau = 0.
   real(R8P),    intent(out) :: zeta_perp0 !< zeta_perp at omega tau = 0.

   j_perp0    = table_j_perp(1, k)
   zeta_perp0 = table_zeta_perp(1, k)
   endsubroutine fit_zero_column

   ! private helpers
   pure function clamped_log(omega_tau) result(x)
   !< x = log10(omega tau) clamped to the fitted range [-3, 3].
   real(R8P), intent(in) :: omega_tau !< Hall parameter.
   real(R8P)             :: x         !< Clamped log.

   x = log10(max(omega_tau, 1.e-3_R8P))
   x = min(x, 3._R8P)
   endfunction clamped_log

   pure function cubic_over_quartic(p, q, x) result(f)
   !< (p1 x^3 + p2 x^2 + p3 x + p4) / (x^4 + q1 x^3 + q2 x^2 + q3 x + q4), Eqs. (C5), (C7).
   real(R8P), intent(in) :: p(4) !< Numerator coefficients.
   real(R8P), intent(in) :: q(4) !< Denominator coefficients.
   real(R8P), intent(in) :: x    !< log10(omega tau).
   real(R8P)             :: f    !< Fit value.

   f = (((p(1) * x + p(2)) * x + p(3)) * x + p(4)) / ((((x + q(1)) * x + q(2)) * x + q(3)) * x + q(4))
   endfunction cubic_over_quartic

   pure function quadratic_over_quartic(r, s, x) result(f)
   !< (r1 x^2 + r2 x + r3) / (x^4 + s1 x^3 + s2 x^2 + s3 x + s4), Eqs. (C6), (C8).
   real(R8P), intent(in) :: r(3) !< Numerator coefficients.
   real(R8P), intent(in) :: s(4) !< Denominator coefficients.
   real(R8P), intent(in) :: x    !< log10(omega tau).
   real(R8P)             :: f    !< Fit value.

   f = ((r(1) * x + r(2)) * x + r(3)) / ((((x + s(1)) * x + s(2)) * x + s(3)) * x + s(4))
   endfunction quadratic_over_quartic
endmodule appelbe_fits
