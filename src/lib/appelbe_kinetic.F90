!< Steady electron f1 equation with electron-fast ion collisions (Eq. 13), solved as in Appendix B.
module appelbe_kinetic
!< Steady electron f1 equation with electron-fast ion collisions (Eq. 13), solved as in Appendix B.
!<
!< Normalisation: u = v / v_Te, f normalised by n / v_Te^3 of its own species (so int f0 d^3u = 1), times in units of
!< tau_ei. Every tau_ei * Y_ab * n_b term of Eqs. (A8)-(A13) and (15) then becomes a pure number:
!<
!<    tau_ei Y_ei n_i / v_Te^3 = 3 sqrt(pi)/4                                            (k_i)
!<    tau_ei Y_ee n_e / v_Te^3 = 3 sqrt(pi)/4 * (1/Z_i) * lnL_ee/lnL_ei                 (k_e)
!<    tau_ei Y_ea n_a / v_Te^3 = 3 sqrt(pi)/4 * (Z_a^2/Z_i) * (n_a/n_e) * lnL_ea/lnL_ei (k_a)
!<
!< using n_e = Z_i n_i (the paper's convention, Sec. III). Driving forces become dimensionless with the mean free path
!< lambda = v_Te tau_ei: eps_E = lambda e E / T_e, eps_T = lambda grad(T_e) / T_e.
!<
!< Magnetisation: with b = z and the drive along x, write f1 = f1x + i f1y. Then b x f1 = i f1 and Eqs. (B6)-(B7) reduce to
!< the single complex system (G + i omega tau) f1 = g7: the real part is the component along the drive (the paper's "perp"),
!< the imaginary part the component along b x drive ("wedge"), matching the tensor convention of Eq. (27).
!<
!< Two interchangeable solution methods (algebraically identical, numerically different):
!< - method_complex (default): one complex solve of (G + i omega tau) f1 = g7.
!< - method_paper: the paper's Appendix B procedure, i.e. the real systems of Eqs. (B6)-(B7) built on the squared operator
!<   GG + Omega^2 (GG by matrix multiplication), and Eq. (B8) G f1 = g7 for omega tau = 0 (parallel direction).
use penf,                  only : I4P, R8P
use appelbe_constants,     only : pi, sqrt_pi
use appelbe_linear_solver, only : solve_dense
use appelbe_velocity_grid, only : velocity_grid

implicit none
private
public :: kinetic_params, kinetic_operator, kinetic_response
public :: method_complex, method_paper

integer(I4P), parameter :: method_complex = 1_I4P  !< Solve (G + i omega tau) f1 = g7.
integer(I4P), parameter :: method_paper   = 2_I4P  !< Solve Eqs. (B6)-(B8) as in the paper.
integer(I4P), parameter :: default_nodes = 401_I4P !< Default number of speed nodes.
real(R8P),    parameter :: default_u_max = 7._R8P  !< Default largest normalised speed.

type :: kinetic_params
   !< Physical parameters of the three-species problem (Sec. II).
   real(R8P) :: z_i          = 1._R8P !< Thermal ion charge state.
   real(R8P) :: z_a          = 2._R8P !< Fast-ion charge state.
   real(R8P) :: mass_ratio   = 0._R8P !< m_e / m_a.
   real(R8P) :: u_a          = 0._R8P !< Fast-ion speed v_a / v_Te; 0 disables the fast-ion drive.
   real(R8P) :: n_ratio      = 0._R8P !< n_a / n_e of the isotropic component F0 kept in the operator (Sec. VI).
   real(R8P) :: lnl_ee_ratio = 1._R8P !< lnL_ee / lnL_ei.
   real(R8P) :: lnl_ea_ratio = 1._R8P !< lnL_ea / lnL_ei.
endtype kinetic_params

type :: kinetic_response
   !< Linear response of the electrons at one Hall parameter; complex numbers carry (perp, wedge) = (real, imag).
   !<
   !< Transport coefficients are in Epperlein-Haines units: sigma [n_e e^2 tau_ei / m_e], mu [n_e e T_e tau_ei / m_e],
   !< tau [n_e e tau_ei / m_e], thermal_diffusion [n_e T_e tau_ei / m_e] (Eqs. 18-19).
   complex(R8P) :: sigma             = (0._R8P, 0._R8P) !< Electric conductivity.
   complex(R8P) :: mu                = (0._R8P, 0._R8P) !< Energy conductivity.
   complex(R8P) :: tau               = (0._R8P, 0._R8P) !< Thermoelectric coefficient.
   complex(R8P) :: thermal_diffusion = (0._R8P, 0._R8P) !< Thermal diffusion K.
   complex(R8P) :: j_nu              = (0._R8P, 0._R8P) !< j0_ea / (Z_a e n_a <v_a>) (Eqs. C1-C2).
   complex(R8P) :: zeta_nu           = (0._R8P, 0._R8P) !< zeta_ea / (n_a <v_a> T_e) (Eqs. C3-C4).
   contains
      procedure, pass(self) :: beta        !< Thermoelectric tensor beta (Eq. 26).
      procedure, pass(self) :: kappa       !< Thermal conductivity kappa (Eq. 25).
      procedure, pass(self) :: resistivity !< Inverse conductivity 1/sigma.
endtype kinetic_response

type :: kinetic_operator
   !< Discretised collision operator G of Eq. (B2), reduced to the unknowns f1(2..n-1).
   type(velocity_grid)    :: grid   !< Speed grid.
   type(kinetic_params)   :: par    !< Physical parameters.
   real(R8P), allocatable :: g(:,:) !< Reduced operator, (n-2) x (n-2).
   contains
      procedure, pass(self) :: init             !< Assemble the operator.
      procedure, pass(self) :: solve            !< Solve (G + i omega tau) f1 = rhs.
      procedure, pass(self) :: solve_paper      !< Solve Eqs. (B6)-(B8) as in the paper.
      procedure, pass(self) :: residual         !< Relative residual of a solution of (G + i omega tau) f1 = rhs.
      procedure, pass(self) :: moment           !< int_0^u_max u^p f1 du.
      procedure, pass(self) :: response         !< Transport coefficients and fast-ion response at one omega tau.
      procedure, pass(self) :: source_electric  !< g7 for a unit electric drive.
      procedure, pass(self) :: source_thermal   !< g7 for a unit temperature-gradient drive.
      procedure, pass(self) :: source_fast_flux !< g7 for a unit fast-ion flux.
endtype kinetic_operator

contains
   ! kinetic_response methods
   pure function beta(self) result(b)
   !< Thermoelectric tensor beta = (e/T_e) mu sigma^-1 - 5/2 (Eq. 26), dimensionless.
   class(kinetic_response), intent(in) :: self !< The response.
   complex(R8P)                        :: b    !< beta (perp, wedge).

   b = self%mu / self%sigma - 2.5_R8P
   endfunction beta

   pure function kappa(self) result(k)
   !< Thermal conductivity kappa = K - mu sigma^-1 mu / T_e + (3/2e) mu (Eq. 25), in units n_e T_e tau_ei / m_e.
   class(kinetic_response), intent(in) :: self !< The response.
   complex(R8P)                        :: k    !< kappa (perp, wedge).

   k = self%thermal_diffusion - self%mu**2 / self%sigma + 1.5_R8P * self%mu
   endfunction kappa

   pure function resistivity(self) result(r)
   !< Inverse conductivity 1/sigma in units m_e / (n_e e^2 tau_ei); at omega tau = 0 it is alpha_par of Eq. (42).
   class(kinetic_response), intent(in) :: self !< The response.
   complex(R8P)                        :: r    !< 1/sigma.

   r = 1._R8P / self%sigma
   endfunction resistivity

   ! kinetic_operator methods
   subroutine init(self, par, n_nodes, u_max)
   !< Assemble the reduced operator G (Eqs. 13, A8-A13, B2) with the boundary conditions of Eqs. (B14)-(B15).
   class(kinetic_operator), intent(inout)        :: self    !< The operator.
   type(kinetic_params),    intent(in)           :: par     !< Physical parameters.
   integer(I4P),            intent(in), optional :: n_nodes !< Number of speed nodes (odd).
   real(R8P),               intent(in), optional :: u_max   !< Largest normalised speed.
   integer(I4P)           :: n, j                   !< Nodes, counter.
   real(R8P)              :: ke, ka, ki, mr, a, u    !< Normalised collision strengths, mass ratio, fast speed, speed.
   real(R8P)              :: ie0, ie2, je            !< I_0, I_2, J_-1 of f0.
   real(R8P)              :: ia0, ia2, ja            !< I_0, I_2, J_-1 of F0.
   real(R8P)              :: g1, g2, g3, g4, g5, g6  !< Coefficient functions at u (Eqs. A8-A13).
   real(R8P), allocatable :: row(:), delta(:)        !< Operator row, discrete delta(u - u_a).
   integer(I4P)           :: ierr                    !< Allocation status.
   character(len=256)     :: emsg                    !< Allocation message.
   real(R8P)              :: u_top                   !< Grid extent actually used.

   n = default_nodes ; if (present(n_nodes)) n = n_nodes
   self%par = par
   u_top = default_u_max ; if (present(u_max)) u_top = u_max
   ! align a node with u_a: the Heaviside jumps and the delta functions of F0, F1 (Eqs. 29-30) then sit on a node, which
   ! removes an erratic O(h) error in the fast-ion moments (u_max is stretched by less than half a cell)
   if (par%u_a > 0._R8P) u_top = par%u_a * real(n - 1_I4P, R8P) / real(nint(par%u_a * real(n - 1_I4P, R8P) / u_top), R8P)
   call self%grid%init(n=n, u_max=u_top)
   if (allocated(self%g)) deallocate(self%g)
   allocate(self%g(n-2, n-2), row(n), delta(n), stat=ierr, errmsg=emsg)
   if (ierr /= 0_I4P) error stop 'kinetic_operator%init: '//trim(emsg)

   ki = 0.75_R8P * sqrt_pi
   ke = ki / par%z_i * par%lnl_ee_ratio
   ka = ki * par%z_a**2 / par%z_i * par%n_ratio * par%lnl_ea_ratio
   mr = par%mass_ratio
   a  = par%u_a
   delta = 0._R8P
   if (ka > 0._R8P) delta = delta_weights(self%grid, a)

   do j = 2_I4P, n - 1_I4P
      u   = self%grid%u(j)
      ie0 = i0_maxwellian(u)
      ie2 = i2_maxwellian(u)
      je  = jm1_maxwellian(u)
      ia0 = 0._R8P ; ia2 = 0._R8P ; ja = 0._R8P
      if (ka > 0._R8P) then
         ia0 = heaviside(u - a, self%grid%h)
         ia2 = (a / u)**2 * heaviside(u - a, self%grid%h)
         ja  = (u / a) * heaviside(a - u, self%grid%h)
      endif
      g1 = ke / (3._R8P * u) * (ie2 + je) + ka / (3._R8P * u) * (ia2 + ja)
      g2 = ke / (3._R8P * u**2) * (3._R8P * ie0 - ie2 + 2._R8P * je) &
         + ka / (3._R8P * u**2) * (3._R8P * mr * ia0 - ia2 + 2._R8P * ja)
      g3 = -ki / u**3 + 8._R8P * pi * ke * maxwellian(u) + ke / (3._R8P * u**3) * (-3._R8P * ie0 + ie2 - 2._R8P * je) &
         + ka * mr * delta(j) / u**2 + ka / (3._R8P * u**3) * (-3._R8P * ia0 + ia2 - 2._R8P * ja)
      g4 = 16._R8P * pi * ke / 5._R8P * maxwellian(u) / u**2
      g5 = -8._R8P * pi * ke / 3._R8P * maxwellian(u) / u**2
      g6 = 8._R8P * pi * ke / 5._R8P * (2._R8P * u**2 - 5._R8P / 3._R8P) * u * maxwellian(u)

      row = 0._R8P
      call self%grid%add_second_derivative(j=j, c=g1, row=row)
      call self%grid%add_first_derivative(j=j, c=g2, row=row)
      row(j) = row(j) + g3
      row = row + (g4 * self%grid%u**5 + g5 * self%grid%u**3) * self%grid%lower_weights(j) &
                + g6 * self%grid%upper_weights(j)
      ! reduce: f(1) = f(2) folds column 1 into column 2, f(n) = 0 drops column n
      self%g(j-1, :) = row(2:n-1)
      self%g(j-1, 1) = self%g(j-1, 1) + row(1)
   enddo
   endsubroutine init

   function solve(self, omega_tau, rhs) result(f1)
   !< Solve (G + i omega tau) f1 = rhs for every column of rhs; f1 is returned on the full grid.
   class(kinetic_operator), intent(in) :: self       !< The operator.
   real(R8P),               intent(in) :: omega_tau  !< Electron Hall parameter.
   real(R8P),               intent(in) :: rhs(:,:)   !< Sources g7 on the full grid, (n, ncol).
   complex(R8P), allocatable           :: f1(:,:)    !< Solutions on the full grid, (n, ncol).
   complex(R8P), allocatable           :: a(:,:)     !< System matrix, LU factors on exit.
   complex(R8P), allocatable           :: b(:,:)     !< Right-hand sides, solutions on exit.
   integer(I4P)                        :: n, i       !< Nodes, counter.

   n = self%grid%n
   a = cmplx(self%g, 0._R8P, kind=R8P)
   do i = 1_I4P, n - 2_I4P
      a(i, i) = a(i, i) + cmplx(0._R8P, omega_tau, kind=R8P)
   enddo
   b = cmplx(rhs(2:n-1, :), 0._R8P, kind=R8P)
   call solve_dense(a=a, b=b)
   allocate(f1(n, size(b, dim=2)))
   f1(1, :)     = b(1, :)
   f1(2:n-1, :) = b
   f1(n, :)     = (0._R8P, 0._R8P)
   endfunction solve

   function solve_paper(self, omega_tau, rhs) result(f1)
   !< The paper's Appendix B solution for a drive along x (g7y = 0), returned as f1 = f1x + i f1y on the full grid.
   !<
   !< omega tau = 0: Eq. (B8), G f1 = g7 (the parallel-direction equation).
   !< omega tau > 0: Eq. (B5) with b = z gives, in components,
   !<    (GG + Omega^2) f1x = G g7x + Omega g7y   ->  G g7x          (B6)
   !<    (GG + Omega^2) f1y = G g7y - Omega g7x   -> -Omega g7x      (B7)
   !< The printed Eqs. (B6)-(B7) read "(G +/- Omega) g7x,y": shorthand that drops the cross-component coupling; the
   !< form above is the one derived from (B5). GG is obtained by matrix multiplication, as stated after Eq. (B19).
   class(kinetic_operator), intent(in) :: self      !< The operator.
   real(R8P),               intent(in) :: omega_tau !< Electron Hall parameter.
   real(R8P),               intent(in) :: rhs(:,:)  !< Sources g7x on the full grid, (n, ncol).
   complex(R8P), allocatable           :: f1(:,:)   !< Solutions on the full grid, (n, ncol).
   real(R8P), allocatable              :: a(:,:)    !< System matrix, destroyed by the solve.
   real(R8P), allocatable              :: b(:,:)    !< Right-hand sides, solutions on exit.
   integer(I4P)                        :: n, m, nc, i !< Nodes, unknowns, columns, counter.

   n  = self%grid%n
   m  = n - 2_I4P
   nc = size(rhs, dim=2, kind=I4P)
   allocate(f1(n, nc))
   if (omega_tau == 0._R8P) then
      a = self%g
      b = rhs(2:n-1, :)
      call solve_dense(a=a, b=b)
      f1(2:n-1, :) = cmplx(b, 0._R8P, kind=R8P)
   else
      a = matmul(self%g, self%g)
      do i = 1_I4P, m
         a(i, i) = a(i, i) + omega_tau**2
      enddo
      allocate(b(m, 2 * nc))
      b(:, 1:nc)        = matmul(self%g, rhs(2:n-1, :))
      b(:, nc+1:2*nc)   = -omega_tau * rhs(2:n-1, :)
      call solve_dense(a=a, b=b)
      f1(2:n-1, :) = cmplx(b(:, 1:nc), b(:, nc+1:2*nc), kind=R8P)
   endif
   f1(1, :) = f1(2, :)
   f1(n, :) = (0._R8P, 0._R8P)
   endfunction solve_paper

   function residual(self, omega_tau, rhs, f1) result(res)
   !< Relative residual ||(G + i omega tau) f1 - g7||_2 / ||g7||_2 per column, on the reduced unknowns.
   !<
   !< It measures how well a solution satisfies the original first-order system, whichever method produced it.
   class(kinetic_operator), intent(in) :: self       !< The operator.
   real(R8P),               intent(in) :: omega_tau  !< Electron Hall parameter.
   real(R8P),               intent(in) :: rhs(:,:)   !< Sources g7 on the full grid, (n, ncol).
   complex(R8P),            intent(in) :: f1(:,:)    !< Solutions on the full grid, (n, ncol).
   real(R8P), allocatable              :: res(:)     !< Relative residual per column.
   complex(R8P), allocatable           :: r(:,:)     !< Residual vectors.
   integer(I4P)                        :: n, j       !< Nodes, counter.

   n = self%grid%n
   r = matmul(cmplx(self%g, 0._R8P, kind=R8P), f1(2:n-1, :)) + cmplx(0._R8P, omega_tau, kind=R8P) * f1(2:n-1, :) &
     - cmplx(rhs(2:n-1, :), 0._R8P, kind=R8P)
   allocate(res(size(rhs, dim=2)))
   do j = 1_I4P, size(rhs, dim=2, kind=I4P)
      res(j) = sqrt(sum(abs(r(:, j))**2)) / sqrt(sum(rhs(2:n-1, j)**2))
   enddo
   endfunction residual

   pure function moment(self, f1, p) result(m)
   !< Moment int_0^u_max u^p f1 du by composite Simpson on the whole grid.
   class(kinetic_operator), intent(in) :: self  !< The operator.
   complex(R8P),            intent(in) :: f1(:) !< Distribution on the full grid.
   integer(I4P),            intent(in) :: p     !< Power of u.
   complex(R8P)                        :: m     !< Moment.

   m = sum(self%grid%lower_weights(self%grid%n) * self%grid%u**p * f1)
   endfunction moment

   function response(self, omega_tau, method) result(r)
   !< Transport coefficients (Eqs. 18-19) and fast-ion response (Eqs. 16-17, 20, C1-C4) at one Hall parameter.
   !<
   !< Moments: j = -(4 pi e/3) int v^3 f1 dv and q = (2 pi m_e/3) int v^5 f1 dv. For a unit electric drive this gives
   !< sigma = -(8pi/3) M3 and mu = -(8pi/3) M5; for a unit temperature-gradient drive tau = -(8pi/3) M3 and
   !< K = -(8pi/3) M5. The fast-ion source is built for a unit flux (n_a/n_e = 1, gamma_a = 1, the result is linear in
   !< both), so j_nu = 1 - 4 pi M3 / (Z_a u_a) and zeta_nu = 4 pi M5 / u_a.
   class(kinetic_operator), intent(in)           :: self      !< The operator.
   real(R8P),               intent(in)           :: omega_tau !< Electron Hall parameter.
   integer(I4P),            intent(in), optional :: method    !< method_complex (default) or method_paper.
   type(kinetic_response)                        :: r         !< The response.
   real(R8P), allocatable                        :: rhs(:,:)  !< Sources.
   complex(R8P), allocatable                     :: f1(:,:)   !< Solutions.
   logical                                       :: fast      !< Fast-ion drive active.
   integer(I4P)                                  :: method_   !< Selected method.
   real(R8P), parameter                          :: c = -8._R8P * pi / 3._R8P !< Moment prefactor.

   method_ = method_complex ; if (present(method)) method_ = method
   fast = self%par%u_a > 0._R8P
   allocate(rhs(self%grid%n, merge(3, 2, fast)))
   rhs(:, 1) = self%source_electric()
   rhs(:, 2) = self%source_thermal()
   if (fast) rhs(:, 3) = self%source_fast_flux()
   select case (method_)
   case (method_complex)
      f1 = self%solve(omega_tau=omega_tau, rhs=rhs)
   case (method_paper)
      f1 = self%solve_paper(omega_tau=omega_tau, rhs=rhs)
   case default
      error stop 'kinetic_operator%response: unknown method'
   endselect

   r%sigma             = c * self%moment(f1(:, 1), 3_I4P)
   r%mu                = c * self%moment(f1(:, 1), 5_I4P)
   r%tau               = c * self%moment(f1(:, 2), 3_I4P)
   r%thermal_diffusion = c * self%moment(f1(:, 2), 5_I4P)
   if (fast) then
      r%j_nu    = 1._R8P - 4._R8P * pi * self%moment(f1(:, 3), 3_I4P) / (self%par%z_a * self%par%u_a)
      r%zeta_nu = 4._R8P * pi * self%moment(f1(:, 3), 5_I4P) / self%par%u_a
   endif
   endfunction response

   pure function source_electric(self) result(s)
   !< g7 for eps_E = 1: u f0, from the (2/v_Te^2) a term of Eq. (15).
   class(kinetic_operator), intent(in) :: self           !< The operator.
   real(R8P)                           :: s(self%grid%n) !< Source on the full grid.

   s = self%grid%u * maxwellian(self%grid%u)
   endfunction source_electric

   pure function source_thermal(self) result(s)
   !< g7 for eps_T = 1: u f0 (u^2 - 3/2), from the grad(T_e) term of Eq. (15).
   class(kinetic_operator), intent(in) :: self           !< The operator.
   real(R8P)                           :: s(self%grid%n) !< Source on the full grid.

   s = self%grid%u * maxwellian(self%grid%u) * (self%grid%u**2 - 1.5_R8P)
   endfunction source_thermal

   pure function source_fast_flux(self) result(s)
   !< g7 for a unit fast-ion flux: the F1 terms of Eq. (15) with F1 = delta(u - u_a) / (4 pi u^2), i.e. Eq. (30) with
   !< gamma_a = 1 and n_a / n_e = 1.
   class(kinetic_operator), intent(in) :: self               !< The operator.
   real(R8P)                           :: s(self%grid%n)     !< Source on the full grid.
   real(R8P)                           :: ka, mr, a, u       !< Unit-flux collision strength, mass ratio, fast speed, speed.
   real(R8P)                           :: i1, i3, jm2        !< I_1, I_3, J_-2 of F1.
   real(R8P)                           :: delta(self%grid%n) !< Discrete delta(u - u_a).
   integer(I4P)                        :: j                  !< Counter.

   ka = 0.75_R8P * sqrt_pi * self%par%z_a**2 / self%par%z_i * self%par%lnl_ea_ratio
   mr = self%par%mass_ratio
   a  = self%par%u_a
   delta = delta_weights(self%grid, a)
   s = 0._R8P
   do j = 2_I4P, self%grid%n - 1_I4P
      u   = self%grid%u(j)
      i1  = (a / u) * heaviside(u - a, self%grid%h)
      i3  = (a / u)**3 * heaviside(u - a, self%grid%h)
      jm2 = (u / a)**2 * heaviside(a - u, self%grid%h)
      s(j) = -ka * maxwellian(u) * (mr * delta(j) / u**2 + 0.8_R8P * u * i3                                         &
                                    + 0.4_R8P * (2._R8P * u**2 - 10._R8P / 3._R8P + 5._R8P * mr / 3._R8P) * jm2 / u &
                                    - 2._R8P / 15._R8P * (-5._R8P + 10._R8P * mr) * i1 / u)
   enddo
   endfunction source_fast_flux

   ! private helpers
   elemental function maxwellian(u) result(f)
   !< Normalised Maxwellian f0 = pi^(-3/2) exp(-u^2) (Eq. 4), int f0 d^3u = 1.
   real(R8P), intent(in) :: u !< Normalised speed.
   real(R8P)             :: f !< f0.

   f = exp(-u**2) / sqrt_pi**3
   endfunction maxwellian

   elemental function i0_maxwellian(u) result(v)
   !< I_0 of f0 (Eq. A3): 4 pi int_0^u U^2 f0 dU = erf(u) - (2/sqrt(pi)) u exp(-u^2).
   real(R8P), intent(in) :: u !< Normalised speed.
   real(R8P)             :: v !< I_0.

   v = erf(u) - 2._R8P / sqrt_pi * u * exp(-u**2)
   endfunction i0_maxwellian

   elemental function i2_maxwellian(u) result(v)
   !< I_2 of f0 (Eq. A3): (4 pi / u^2) int_0^u U^4 f0 dU = [3/2 erf(u) - (2/sqrt(pi)) (u^3 + 3u/2) exp(-u^2)] / u^2.
   real(R8P), intent(in) :: u !< Normalised speed, > 0.
   real(R8P)             :: v !< I_2.

   v = (1.5_R8P * erf(u) - 2._R8P / sqrt_pi * (u**3 + 1.5_R8P * u) * exp(-u**2)) / u**2
   endfunction i2_maxwellian

   elemental function jm1_maxwellian(u) result(v)
   !< J_-1 of f0 (Eq. A4): 4 pi u int_u^inf U f0 dU = (2/sqrt(pi)) u exp(-u^2).
   real(R8P), intent(in) :: u !< Normalised speed.
   real(R8P)             :: v !< J_-1.

   v = 2._R8P / sqrt_pi * u * exp(-u**2)
   endfunction jm1_maxwellian

   elemental function heaviside(x, spacing) result(h)
   !< Heaviside step, 1/2 at the origin; closed form of the I/J integrals of the delta-function F0, F1 (Eqs. 29-30).
   !<
   !< |x| below 1e-8 of the grid spacing counts as the origin: with a node aligned to u_a, u_j - u_a is zero only up to
   !< rounding, and a random 0/1 there would make the fast-ion moments jump erratically with the grid.
   real(R8P), intent(in) :: x       !< Argument.
   real(R8P), intent(in) :: spacing !< Grid spacing setting the tolerance.
   real(R8P)             :: h       !< Step.

   if (abs(x) <= 1.e-8_R8P * spacing) then
      h = 0.5_R8P
   elseif (x > 0._R8P) then
      h = 1._R8P
   else
      h = 0._R8P
   endif
   endfunction heaviside

   pure function delta_weights(grid, a) result(d)
   !< Discrete delta(u - a) as a unit-area hat function spread on the two nodes bracketing a.
   type(velocity_grid), intent(in) :: grid      !< Speed grid.
   real(R8P),           intent(in) :: a         !< Location of the delta.
   real(R8P)                       :: d(grid%n) !< Nodal values.
   integer(I4P)                    :: k         !< Node at or below a.
   real(R8P)                       :: t         !< Position of a within [u_k, u_k+1] in units of h.

   if (a < 4._R8P * grid%h) error stop 'kinetic: u_a under-resolved, increase n_nodes (need u_a >= 4 h)'
   if (a > grid%u(grid%n - 1)) error stop 'kinetic: u_a beyond the grid, increase u_max'
   k = int(a / grid%h, I4P) + 1_I4P
   t = (a - grid%u(k)) / grid%h
   d = 0._R8P
   d(k)     = (1._R8P - t) / grid%h
   d(k + 1) = t / grid%h
   endfunction delta_weights
endmodule appelbe_kinetic
