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
!<
!< Fast-ion population: monoenergetic by default (Eqs. 29-30, the I/J integrals of Eqs. A6-A7 in closed form), or any
!< speed distribution F(u) passed to init (footnote 30), with F1 = gamma_a F0 of the same shape and the I/J integrals
!< computed by quadrature on the grid. Either way the distribution is normalised to unit density.
!<
!< Electron f0: Maxwellian by default (Eq. 4, its I/J integrals in closed form), or any isotropic distribution passed to
!< init. The operator then uses the general forms of Eqs. (A2) and (A5), with f0, df0/du and d2f0/du2 instead of their
!< Maxwellian values (the Maxwellian reduction of those forms gives Eqs. A11-A13), and the drives become
!<    electric field:        g7 = -(1/2) df0/du                      (u f0 for a Maxwellian)
!<    temperature gradient:  g7 = -u (3/2 f0 + 1/2 u df0/du)         (u f0 (u^2 - 3/2) for a Maxwellian)
!< the latter assuming that f0 keeps its shape in v/v_Te as T_e varies, f0 = n/v_Te^3 phi(v/v_Te). Speeds, times and
!< coefficients are then in units of the reference temperature T_e that defines v_Te and tau_ei.
use penf,                  only : I4P, R8P
use appelbe_constants,     only : pi, sqrt_pi
use appelbe_linear_solver, only : solve_dense
use appelbe_velocity_grid, only : velocity_grid

implicit none
private
public :: kinetic_params, kinetic_operator, kinetic_response, speed_distribution, maxwellian
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
   real(R8P) :: u_a          = 0._R8P !< Fast-ion speed v_a / v_Te (aligned with a node); 0 disables the fast ions.
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
   type(velocity_grid)    :: grid                    !< Speed grid.
   type(kinetic_params)   :: par                     !< Physical parameters.
   real(R8P), allocatable :: g(:,:)                  !< Reduced operator, (n-2) x (n-2).
   logical                :: monoenergetic = .true.  !< Delta-function population (closed-form I/J integrals).
   logical                :: aligned = .true.        !< A node sits on u_a (see init).
   logical                :: maxwellian_f0 = .true.  !< Maxwellian electrons (closed-form I/J integrals of f0).
   real(R8P), allocatable :: f0(:)                   !< Electron f0 on the grid, 4 pi int u^2 f0 du = 1.
   real(R8P), allocatable :: df0(:)                  !< df0/du on the grid.
   real(R8P), allocatable :: d2f0(:)                 !< d2f0/du2 on the grid.
   real(R8P), allocatable :: fast(:)                 !< Fast-ion distribution on the grid, 4 pi int u^2 F du = 1.
   real(R8P)              :: u_flux = 0._R8P         !< 4 pi int u^3 F du = 3 <v_a> / (gamma_a v_Te); u_a if monoenergetic.
   real(R8P)              :: u_energy = 0._R8P       !< sqrt(4 pi int u^4 F du): speed of the mean energy; u_a if monoenergetic.
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
      procedure, pass(self) :: fast_integrals   !< I/J integrals of the fast-ion distribution at one node.
      procedure, pass(self), private :: init_fast !< Sample and normalise the fast-ion distribution.
      procedure, pass(self), private :: init_electrons !< Sample and normalise the electron f0 and its derivatives.
      procedure, pass(self) :: electron_integrals !< I_0, I_2, J_-1 of the electron f0 at one node.
endtype kinetic_operator

abstract interface
   pure function speed_distribution(u, p) result(f)
   !< Isotropic fast-ion speed distribution F(u), any normalisation (it is normalised to unit density on the grid).
   import :: R8P
   real(R8P), intent(in) :: u    !< Normalised speed v / v_Te.
   real(R8P), intent(in) :: p(:) !< Shape parameters.
   real(R8P)             :: f    !< F(u).
   endfunction speed_distribution
endinterface

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
   subroutine init(self, par, n_nodes, u_max, distribution, shape_params, align, electrons, electron_params)
   !< Assemble the reduced operator G (Eqs. 13, A8-A13, B2) with the boundary conditions of Eqs. (B14)-(B15).
   !<
   !< Without distribution the fast ions are monoenergetic at par%u_a (Eqs. 29-30). With distribution, F(u) is sampled on
   !< the grid (it must vanish well before u_max) and par%u_a is only a reference speed (> 0) aligned with a node.
   !<
   !< With electrons, the electron f0 is that isotropic distribution instead of a Maxwellian (see the module header).
   !<
   !< align = .false. keeps the grid as given, so that u_a generally falls between two nodes: the Heaviside steps of the
   !< I/J integrals then jump between nodes and the moments carry an O(h) error that depends on where u_a falls in its
   !< cell. This is not a numerical option for physics: it emulates the paper's own discretisation (appelbe_paper).
   class(kinetic_operator),       intent(inout)        :: self         !< The operator.
   type(kinetic_params),          intent(in)           :: par          !< Physical parameters.
   integer(I4P),                  intent(in), optional :: n_nodes      !< Number of speed nodes (odd).
   real(R8P),                     intent(in), optional :: u_max        !< Largest normalised speed.
   procedure(speed_distribution),             optional :: distribution !< Fast-ion speed distribution (footnote 30).
   real(R8P),                     intent(in), optional :: shape_params(:) !< Parameters passed to distribution.
   logical,                       intent(in), optional :: align        !< Align a node with u_a (default .true.).
   procedure(speed_distribution),             optional :: electrons    !< Electron f0 (default: Maxwellian).
   real(R8P),                     intent(in), optional :: electron_params(:) !< Parameters passed to electrons.
   integer(I4P)           :: n, j                   !< Nodes, counter.
   real(R8P)              :: ke, ka, ki, mr, u       !< Normalised collision strengths, mass ratio, speed.
   real(R8P)              :: ie0, ie2, je            !< I_0, I_2, J_-1 of f0.
   real(R8P)              :: fi(6)                   !< I_0, I_2, J_-1 of F0 (then I_1, I_3, J_-2 of F1, unused here).
   real(R8P)              :: g1, g2, g3, g4, g5, g6  !< Coefficient functions at u (Eqs. A8-A13).
   real(R8P), allocatable :: row(:)                  !< Operator row.
   integer(I4P)           :: ierr                    !< Allocation status.
   character(len=256)     :: emsg                    !< Allocation message.
   real(R8P)              :: u_top                   !< Grid extent actually used.

   n = default_nodes ; if (present(n_nodes)) n = n_nodes
   self%par = par
   u_top = default_u_max ; if (present(u_max)) u_top = u_max
   ! align a node with u_a: the Heaviside jumps and the delta functions of F0, F1 (Eqs. 29-30) then sit on a node, which
   ! removes an erratic O(h) error in the fast-ion moments (u_max is stretched by less than half a cell)
   self%aligned = .true. ; if (present(align)) self%aligned = align
   if (par%u_a > 0._R8P .and. self%aligned) &
      u_top = par%u_a * real(n - 1_I4P, R8P) / real(nint(par%u_a * real(n - 1_I4P, R8P) / u_top), R8P)
   call self%grid%init(n=n, u_max=u_top)
   if (allocated(self%g)) deallocate(self%g)
   if (allocated(self%fast)) deallocate(self%fast)
   allocate(self%g(n-2, n-2), row(n), self%fast(n), stat=ierr, errmsg=emsg)
   if (ierr /= 0_I4P) error stop 'kinetic_operator%init: '//trim(emsg)
   call self%init_fast(distribution, shape_params)
   call self%init_electrons(electrons, electron_params)

   ki = 0.75_R8P * sqrt_pi
   ke = ki / par%z_i * par%lnl_ee_ratio
   ka = ki * par%z_a**2 / par%z_i * par%n_ratio * par%lnl_ea_ratio
   mr = par%mass_ratio

   do j = 2_I4P, n - 1_I4P
      u   = self%grid%u(j)
      call self%electron_integrals(j, ie0, ie2, je)
      fi = 0._R8P
      if (ka > 0._R8P) fi = self%fast_integrals(j)
      g1 = ke / (3._R8P * u) * (ie2 + je) + ka / (3._R8P * u) * (fi(2) + fi(3))
      g2 = ke / (3._R8P * u**2) * (3._R8P * ie0 - ie2 + 2._R8P * je) &
         + ka / (3._R8P * u**2) * (3._R8P * mr * fi(1) - fi(2) + 2._R8P * fi(3))
      g3 = -ki / u**3 + 8._R8P * pi * ke * self%f0(j) + ke / (3._R8P * u**3) * (-3._R8P * ie0 + ie2 - 2._R8P * je) &
         + 4._R8P * pi * ka * mr * self%fast(j) + ka / (3._R8P * u**3) * (-3._R8P * fi(1) + fi(2) - 2._R8P * fi(3))
      ! the I_1, I_3, J_-2 terms of f1 in Eq. (A2), multiplying f0'' and f0' (Eqs. A11-A13 for a Maxwellian)
      g4 = 4._R8P * pi * ke * (self%d2f0(j) / (5._R8P * u**4) - self%df0(j) / (5._R8P * u**5))
      g5 = 4._R8P * pi * ke * self%df0(j) / (3._R8P * u**3)
      g6 = 4._R8P * pi * ke * (u * self%d2f0(j) / 5._R8P + 2._R8P * self%df0(j) / 15._R8P)

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
      ! explicit allocation, not b = rhs(2:n-1, :): nvfortran 26.9 corrupts the heap on that reallocating assignment here
      ! (valgrind: copy past the end of rhs and b; test_solvers aborts in malloc). Same semantics on every compiler.
      allocate(b(m, nc))
      b(:, :) = rhs(2:n-1, :)
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
   !< K = -(8pi/3) M5. The fast-ion source is built for n_a/n_e = 1 and gamma_a = 1 (the result is linear in both), i.e. a
   !< flux 3 n_a <v_a> / (n_e v_Te) = u_flux, so j_nu = 1 - 4 pi M3 / (Z_a u_flux) and zeta_nu = 4 pi M5 / u_flux
   !< (u_flux = u_a for the monoenergetic population, Eq. 31).
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
      r%j_nu    = 1._R8P - 4._R8P * pi * self%moment(f1(:, 3), 3_I4P) / (self%par%z_a * self%u_flux)
      r%zeta_nu = 4._R8P * pi * self%moment(f1(:, 3), 5_I4P) / self%u_flux
   endif
   endfunction response

   pure function source_electric(self) result(s)
   !< g7 for eps_E = 1: -(1/2) df0/du, from the electric-field term of Eq. (15) (u f0 for a Maxwellian).
   class(kinetic_operator), intent(in) :: self           !< The operator.
   real(R8P)                           :: s(self%grid%n) !< Source on the full grid.

   s = -0.5_R8P * self%df0
   endfunction source_electric

   pure function source_thermal(self) result(s)
   !< g7 for eps_T = 1: -u (3/2 f0 + 1/2 u df0/du), from the grad(T_e) term of Eq. (15) for f0 = n/v_Te^3 phi(v/v_Te)
   !< (u f0 (u^2 - 3/2) for a Maxwellian).
   class(kinetic_operator), intent(in) :: self           !< The operator.
   real(R8P)                           :: s(self%grid%n) !< Source on the full grid.

   s = -self%grid%u * (1.5_R8P * self%f0 + 0.5_R8P * self%grid%u * self%df0)
   endfunction source_thermal

   pure function source_fast_flux(self) result(s)
   !< g7 for a unit fast-ion population: the F1 terms of Eq. (A5) with F1 = F (Eq. 30 with gamma_a = 1, n_a / n_e = 1),
   !< F the normalised fast-ion distribution (delta(u - u_a) / (4 pi u^2) if monoenergetic), for any electron f0.
   class(kinetic_operator), intent(in) :: self           !< The operator.
   real(R8P)                           :: s(self%grid%n) !< Source on the full grid.
   real(R8P)                           :: ka, mr, u      !< Unit-population collision strength, mass ratio, speed.
   real(R8P)                           :: fi(6)          !< I/J integrals; I_1, I_3, J_-2 of F1 in fi(4:6).
   integer(I4P)                        :: j              !< Counter.

   ka = 0.75_R8P * sqrt_pi * self%par%z_a**2 / self%par%z_i * self%par%lnl_ea_ratio
   mr = self%par%mass_ratio
   s = 0._R8P
   do j = 2_I4P, self%grid%n - 1_I4P
      u  = self%grid%u(j)
      fi = self%fast_integrals(j)
      s(j) = -ka * (4._R8P * pi * mr * self%fast(j) * self%f0(j)                                             &
                    + (fi(5) + fi(6)) / (5._R8P * u) * self%d2f0(j)                                          &
                    + (-3._R8P * fi(5) + (7._R8P - 5._R8P * mr) * fi(6) + (-5._R8P + 10._R8P * mr) * fi(4)) &
                      / (15._R8P * u**2) * self%df0(j))
   enddo
   endfunction source_fast_flux

   pure function fast_integrals(self, j) result(fi)
   !< I/J integrals (Eqs. A3-A4, A6-A7) of the unit-density fast-ion distribution F at node j:
   !<
   !<    fi = [I_0, I_2, J_-1, I_1, I_3, J_-2],   I_k = (4 pi / u^k) int_0^u w^(k+2) F dw,
   !<                                             J_k = (4 pi / u^k) int_u^inf w^(k+2) F dw,
   !<
   !< the first three for F0 (operator), the last three for F1 = F (source). Monoenergetic population: closed forms of
   !< the delta function, with the Heaviside step 1/2 at u_a; otherwise composite quadrature on the grid.
   class(kinetic_operator), intent(in) :: self      !< The operator.
   integer(I4P),            intent(in) :: j         !< Node, 2 <= j <= n-1.
   real(R8P)                           :: fi(6)     !< The integrals.
   real(R8P)                           :: a, u, h   !< Fast speed, speed, spacing.
   real(R8P)                           :: low(self%grid%n), up(self%grid%n) !< Quadrature weights of [0, u], [u, u_max].

   u = self%grid%u(j)
   if (self%monoenergetic) then
      a = self%par%u_a
      h = self%grid%h
      fi = [heaviside(u - a, h), (a / u)**2 * heaviside(u - a, h), (u / a) * heaviside(a - u, h), &
            (a / u) * heaviside(u - a, h), (a / u)**3 * heaviside(u - a, h), (u / a)**2 * heaviside(a - u, h)]
   else
      low = 4._R8P * pi * self%grid%lower_weights(j) * self%fast
      up  = 4._R8P * pi * self%grid%upper_weights(j) * self%fast
      fi = [sum(low * self%grid%u**2), sum(low * self%grid%u**4) / u**2, u * sum(up * self%grid%u), &
            sum(low * self%grid%u**3) / u, sum(low * self%grid%u**5) / u**3, u**2 * sum(up)]
   endif
   endfunction fast_integrals

   subroutine init_fast(self, distribution, shape_params)
   !< Sample the fast-ion distribution on the grid, normalise it to unit density, compute u_flux and u_energy.
   !<
   !< Monoenergetic: F = delta(u - u_a) / (4 pi u^2), with the delta as a unit-area hat on the two nodes around u_a (only
   !< its node values enter, through the mass-ratio terms); u_flux = u_energy = u_a.
   class(kinetic_operator),       intent(inout) :: self         !< The operator.
   procedure(speed_distribution), optional      :: distribution !< Fast-ion speed distribution.
   real(R8P),           intent(in), optional    :: shape_params(:) !< Parameters passed to distribution.
   real(R8P)                                    :: w(self%grid%n) !< Quadrature weights of [0, u_max].
   integer(I4P)                                 :: j            !< Counter.

   self%fast = 0._R8P
   self%u_flux = 0._R8P
   self%u_energy = 0._R8P
   self%monoenergetic = .not. present(distribution)
   if (self%par%u_a <= 0._R8P) return
   if (self%monoenergetic) then
      self%fast = delta_weights(self%grid, self%par%u_a, merge(4._R8P, 0.5_R8P, self%aligned)) ! node 1 dropped
      self%fast(2:) = self%fast(2:) / (4._R8P * pi * self%grid%u(2:)**2)
      self%fast(1) = 0._R8P ! u = 0: boundary node, outside the operator rows (only reached when u_a < h, unaligned)
      self%u_flux = self%par%u_a
      self%u_energy = self%par%u_a
   else
      if (.not. present(shape_params)) error stop 'kinetic: a fast-ion distribution needs shape_params'
      self%fast = [(distribution(self%grid%u(j), shape_params), j=1_I4P, self%grid%n)]
      w = 4._R8P * pi * self%grid%lower_weights(self%grid%n)
      if (self%fast(self%grid%n) > 1.e-12_R8P * maxval(self%fast)) &
         error stop 'kinetic: fast-ion distribution does not vanish at u_max, increase u_max'
      self%fast = self%fast / sum(w * self%grid%u**2 * self%fast)
      self%u_flux = sum(w * self%grid%u**3 * self%fast)
      self%u_energy = sqrt(sum(w * self%grid%u**4 * self%fast))
   endif
   endsubroutine init_fast

   subroutine init_electrons(self, electrons, electron_params)
   !< Sample the electron f0 on the grid, normalise it to unit density, and compute df0/du, d2f0/du2.
   !<
   !< Maxwellian: closed forms. Otherwise the derivatives come from five-point differences of the function itself (step
   !< 1e-3, error ~1e-10), so f0 must be smooth and defined slightly beyond each node.
   class(kinetic_operator),       intent(inout) :: self               !< The operator.
   procedure(speed_distribution), optional      :: electrons          !< Electron f0.
   real(R8P),           intent(in), optional    :: electron_params(:) !< Parameters passed to electrons.
   real(R8P), parameter                         :: d = 1.e-3_R8P      !< Difference step.
   real(R8P)                                    :: norm               !< Density of the sampled f0.
   real(R8P)                                    :: fm2, fm1, fp1, fp2 !< f0 at u - 2d, u - d, u + d, u + 2d.
   integer(I4P)                                 :: j                  !< Counter.

   if (allocated(self%f0)) deallocate(self%f0, self%df0, self%d2f0)
   allocate(self%f0(self%grid%n), self%df0(self%grid%n), self%d2f0(self%grid%n))
   self%maxwellian_f0 = .not. present(electrons)
   if (self%maxwellian_f0) then
      self%f0   = maxwellian(self%grid%u)
      self%df0  = -2._R8P * self%grid%u * self%f0
      self%d2f0 = (4._R8P * self%grid%u**2 - 2._R8P) * self%f0
      return
   endif
   if (.not. present(electron_params)) error stop 'kinetic: an electron distribution needs electron_params'
   do j = 1_I4P, self%grid%n
      associate(u => self%grid%u(j))
         self%f0(j) = electrons(u, electron_params)
         fm2 = electrons(u - 2._R8P * d, electron_params) ; fm1 = electrons(u - d, electron_params)
         fp1 = electrons(u + d, electron_params)          ; fp2 = electrons(u + 2._R8P * d, electron_params)
      endassociate
      self%df0(j)  = (fm2 - 8._R8P * fm1 + 8._R8P * fp1 - fp2) / (12._R8P * d)
      self%d2f0(j) = (-fm2 + 16._R8P * fm1 - 30._R8P * self%f0(j) + 16._R8P * fp1 - fp2) / (12._R8P * d**2)
   enddo
   if (self%f0(self%grid%n) > 1.e-12_R8P * maxval(self%f0)) &
      error stop 'kinetic: electron distribution does not vanish at u_max, increase u_max'
   norm = 4._R8P * pi * sum(self%grid%lower_weights(self%grid%n) * self%grid%u**2 * self%f0)
   self%f0 = self%f0 / norm ; self%df0 = self%df0 / norm ; self%d2f0 = self%d2f0 / norm
   endsubroutine init_electrons

   pure subroutine electron_integrals(self, j, i0, i2, jm1)
   !< I_0, I_2, J_-1 of the electron f0 at node j (Eqs. A3-A4): closed forms for a Maxwellian, quadrature otherwise.
   class(kinetic_operator), intent(in)  :: self !< The operator.
   integer(I4P),            intent(in)  :: j    !< Node, 2 <= j <= n-1.
   real(R8P),               intent(out) :: i0   !< 4 pi int_0^u U^2 f0 dU.
   real(R8P),               intent(out) :: i2   !< (4 pi / u^2) int_0^u U^4 f0 dU.
   real(R8P),               intent(out) :: jm1  !< 4 pi u int_u^inf U f0 dU.
   real(R8P)                            :: low(self%grid%n), up(self%grid%n) !< Weights times 4 pi f0.
   real(R8P)                            :: u    !< Speed.

   u = self%grid%u(j)
   if (self%maxwellian_f0) then
      i0 = i0_maxwellian(u) ; i2 = i2_maxwellian(u) ; jm1 = jm1_maxwellian(u)
   else
      low = 4._R8P * pi * self%grid%lower_weights(j) * self%f0
      up  = 4._R8P * pi * self%grid%upper_weights(j) * self%f0
      i0  = sum(low * self%grid%u**2)
      i2  = sum(low * self%grid%u**4) / u**2
      jm1 = u * sum(up * self%grid%u)
   endif
   endsubroutine electron_integrals

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

   pure function delta_weights(grid, a, min_cells) result(d)
   !< Discrete delta(u - a) as a unit-area hat function spread on the two nodes bracketing a.
   type(velocity_grid), intent(in) :: grid      !< Speed grid.
   real(R8P),           intent(in) :: a         !< Location of the delta.
   real(R8P),           intent(in) :: min_cells !< Smallest a / h accepted (4 for accuracy; 0.5 to emulate the paper).
   real(R8P)                       :: d(grid%n) !< Nodal values.
   integer(I4P)                    :: k         !< Node at or below a.
   real(R8P)                       :: t         !< Position of a within [u_k, u_k+1] in units of h.

   if (a < min_cells * grid%h) error stop 'kinetic: u_a under-resolved, increase n_nodes (need u_a >= 4 h)'
   if (a > grid%u(grid%n - 1)) error stop 'kinetic: u_a beyond the grid, increase u_max'
   k = int(a / grid%h, I4P) + 1_I4P
   t = (a - grid%u(k)) / grid%h
   d = 0._R8P
   d(k)     = (1._R8P - t) / grid%h
   d(k + 1) = t / grid%h
   endfunction delta_weights
endmodule appelbe_kinetic
