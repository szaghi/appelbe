!< The GUI's model: its inputs, and the library calls that turn them into what the panels show (no FIGURE here).
module appelbe_gui_model
!< The GUI's model: its inputs, and the library calls that turn them into what the panels show (no FIGURE here).
!<
!< Every number the GUI shows comes from a call of the appelbe library made here; the panels only draw these arrays.
!< The GUI adds no physics: what is computed is what the driver appelbe_electrons computes (appelbe_electron_study), on
!< the inputs the user sets. Inputs the library rejects (kinetic_operator%init's stat, read_table's, the table check)
!< become a message the panels show, never a stop.
!<
!< The model has no module variable: every procedure works on the objects it is given, so that a FIGURE task (another
!< thread) can run it on its own copy (docs/guide/gui.md, "Threads").
use penf,                   only : I4P, R8P
use appelbe_constants,      only : m_e, m_alpha, m_proton, m_carbon12, amu, keV_J, MeV_J
use appelbe_distributions,  only : electron_maxwellian, electron_bipolar, electron_table, electron_table_params, &
                                   electron_table_check
use appelbe_eedf,           only : ts_fit, kinetic_temperature
use appelbe_electron_study, only : electron_profile, electron_f1, electron_readouts, electron_scan_row, scan_value, &
                                   n_readouts, ts_windows, ece_window
use appelbe_io,             only : read_table
use appelbe_kinetic,        only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_plasma,         only : speed_ratio

implicit none
private
public :: F0_MAXWELLIAN, F0_BIPOLAR, F0_TABLE, F0_KINDS
public :: SPECIES_ALPHA, SPECIES_PROTON, SPECIES_CARBON, SPECIES_CUSTOM, SPECIES_NAMES
public :: gui_inputs, f0_view, solve_job, scan_job, SCAN_PARAMETERS, SCAN_COLUMNS
public :: species_defaults, input_error, physical_params, init_electrons, load_table, compute_f0_view
public :: CURVE_F0, CURVE_MAXWELLIAN, CURVE_EQUAL_ENERGY, N_CURVES, omega_tau_grid

integer(I4P), parameter :: F0_MAXWELLIAN = 1_I4P !< f0: a Maxwellian at T (electron_maxwellian).
integer(I4P), parameter :: F0_BIPOLAR    = 2_I4P !< f0: the bipolar distortion (electron_bipolar).
integer(I4P), parameter :: F0_TABLE      = 3_I4P !< f0: a table read from a file (electron_table).
!> Names of the f0 kinds, in the order of their constants.
character(len=*), parameter :: F0_KINDS(3) = [character(len=24) :: 'Maxwellian', 'Bipolar distortion', 'Table (file)']

integer(I4P), parameter :: SPECIES_ALPHA  = 1_I4P !< Fusion alpha, 3.45 MeV, Z = 2.
integer(I4P), parameter :: SPECIES_PROTON = 2_I4P !< Proton, 3.02 MeV (D-D), Z = 1.
integer(I4P), parameter :: SPECIES_CARBON = 3_I4P !< Fully ionised carbon-12, Z = 6 (the paper's Sec. V B beam).
integer(I4P), parameter :: SPECIES_CUSTOM = 4_I4P !< Any: Z, mass [amu] and energy set by the user.
character(len=*), parameter :: SPECIES_NAMES(4) = [character(len=24) :: 'alpha (He-4, Z = 2)', 'proton (Z = 1)', &
                                                   'carbon-12 (Z = 6)', 'custom'] !< Their names.

type :: gui_inputs
   !< What the user sets. The defaults are the driver appelbe_electrons' reference case: 3.45 MeV alphas at T_e = 10 keV,
   !< n_a/n_e = 1e-3, Z_i = 1, 801 nodes, u_max = 7, the bipolar f0 A = 0.1, u_0 = 2, w = 0.25, omega tau = 0 and 1.
   integer(I4P)           :: f0_kind     = F0_BIPOLAR                    !< F0_MAXWELLIAN, F0_BIPOLAR or F0_TABLE.
   real(R8P)              :: t_ratio     = 1._R8P                        !< Maxwellian: T / T_e.
   real(R8P)              :: bipolar(3)  = [0.1_R8P, 2._R8P, 0.25_R8P]   !< Bipolar: A, u_0, w (momenta in sqrt(m_e T_e)).
   character(len=1024)    :: table_path  = ''                            !< Table: the file read.
   real(R8P), allocatable :: table_x(:)                                  !< Table: u_L = p / sqrt(m_e T_e).
   real(R8P), allocatable :: table_f(:)                                  !< Table: f0.
   real(R8P)              :: te_kev      = 10._R8P                       !< Electron temperature T_e [keV].
   real(R8P)              :: z_i         = 1._R8P                        !< Thermal ion charge state.
   integer(I4P)           :: species     = SPECIES_ALPHA                 !< Fast-ion species.
   real(R8P)              :: z_a         = 2._R8P                        !< Fast-ion charge state.
   real(R8P)              :: mass_amu    = m_alpha / amu                 !< Fast-ion mass [amu] (custom species).
   real(R8P)              :: e_mev       = 3.45_R8P                      !< Fast-ion energy [MeV].
   real(R8P)              :: n_ratio     = 1.e-3_R8P                     !< n_a / n_e of the isotropic F0 in the operator.
   integer(I4P)           :: n_nodes     = 801_I4P                       !< Speed nodes (odd).
   real(R8P)              :: u_max       = 7._R8P                        !< Grid extent in v_Te (u_L = sqrt(2) u_max).
   real(R8P)              :: omega_tau   = 1._R8P                        !< The Hall parameter of the magnetised readouts.
   integer(I4P)           :: scan_param  = 1_I4P                         !< Scanned bipolar parameter: 1 A, 2 u_0, 3 w.
   real(R8P)              :: scan_min(3) = [-0.3_R8P, 0.5_R8P, 0.1_R8P]  !< Scan ranges (the driver's): from ...
   real(R8P)              :: scan_max(3) = [0.3_R8P, 4._R8P, 1._R8P]     !< ... to ...
   integer(I4P)           :: scan_n(3)   = [13_I4P, 15_I4P, 19_I4P]      !< ... in so many values.
endtype gui_inputs

type :: f0_view
   !< The f0 panel and its diagnostics: what init and appelbe_electron_study give without a solve (milliseconds).
   logical                       :: valid = .false. !< The operators were built: the arrays below hold.
   character(len=:), allocatable :: error           !< Why not ('' when valid).
   type(kinetic_operator)        :: ob              !< The chosen f0.
   type(kinetic_operator)        :: om              !< The Maxwellian at T_e, the same grid (closed forms).
   type(kinetic_operator)        :: ot              !< The Maxwellian of the same energy, T = T_kin (general path).
   real(R8P), allocatable        :: prof(:,:)       !< electron_profile(ob, om): columns of profile_header.
   real(R8P), allocatable        :: prof_kin(:,:)   !< electron_profile(ob, ot): the same against the equal-energy one.
   real(R8P)                     :: t_kin = 0._R8P  !< Kinetic temperature (2/3) <u^2> [T_e].
   real(R8P)                     :: t_ts(2) = 0._R8P !< TS temperatures, Gaussian fit on w <= ts_windows(1:2) [T_e].
   real(R8P)                     :: c_ts(2) = 0._R8P !< Their intercepts: the fit is exp(c - w^2 / T).
   real(R8P), allocatable        :: s_fit(:,:)      !< The fitted spectra exp(c - w^2 / T) at w = u, both windows.
   real(R8P)                     :: peak_df(2) = 0._R8P  !< max |f0/f_M - 1| on u_L <= 4: against T_e, against T_kin.
   real(R8P)                     :: peak_ddf(2) = 0._R8P !< max |f0'/f_M' - 1| on 0 < u_L <= 4: the same.
   real(R8P)                     :: t_slope(2) = 0._R8P !< Range of the slope temperature in the ECE window [T_e].
   real(R8P)                     :: u_a = 0._R8P    !< v_a / v_Te of the fast ions.
endtype f0_view

integer(I4P), parameter :: CURVE_F0           = 1_I4P !< Responses of the chosen f0.
integer(I4P), parameter :: CURVE_MAXWELLIAN   = 2_I4P !< Responses of the Maxwellian at T_e.
integer(I4P), parameter :: CURVE_EQUAL_ENERGY = 3_I4P !< Responses of the Maxwellian of the same energy (T = T_kin).
integer(I4P), parameter :: N_CURVES           = 3_I4P !< Curves of the omega tau sweep.

type :: solve_job
   !< The solves of the transport panel, as a sequence of steps (solve_job%step) that a FIGURE task runs on its own copy
   !< of the job, reporting its progress between steps and stopping at a cancel. Step 1 builds the operators, the
   !< readouts (electron_readouts: omega tau = 0 and inp%omega_tau) and the f1 profiles (electron_f1); step 1 + k the
   !< responses at wt(k) of the three curves (CURVE_*). Every result is a library call's.
   type(gui_inputs)                    :: inp                    !< The inputs solved for (a copy).
   integer(I4P)                        :: done = 0_I4P           !< Steps done.
   logical                             :: failed = .false.       !< A step failed: error says why.
   character(len=:), allocatable       :: error                  !< Why ('' while none).
   real(R8P)                           :: readouts(n_readouts) = 0._R8P !< electron_readouts (readouts_header).
   real(R8P), allocatable              :: f1(:,:)                !< electron_f1 (f1_header).
   real(R8P), allocatable              :: wt(:)                  !< Hall parameters of the sweep.
   type(kinetic_response), allocatable :: r(:,:)                 !< Responses (wt, curve).
   type(kinetic_operator)              :: ob, om, ot             !< Operators: f0, Maxwellian at T_e, at T_kin.
   contains
      procedure, pass(self) :: setup  !< Copy the inputs, size the results.
      procedure, pass(self) :: steps  !< Number of steps.
      procedure, pass(self) :: step   !< Do the next step.
      procedure, pass(self) :: finished !< Every step done (or a failure).
endtype solve_job

!> Names of the scanned parameters (the bipolar A, u_0, w) as the driver's scan files label them.
character(len=*), parameter :: SCAN_PARAMETERS(3) = [character(len=4) :: 'A', 'u_0', 'w']
!> The columns of a scan row after the parameter (scan_header): what the scan plot can show.
character(len=*), parameter :: SCAN_COLUMNS(19) = [character(len=32) ::                                             &
   'T_TS (w <= 2)', 'T_TS (w <= 3)', 'T_kin', 'T_slope min', 'T_slope max', 'max |T_slope - T_TS|', 'monotone f0', &
   'd sigma, wt = 0', 'd kappa, wt = 0', 'd j_nu, wt = 0', 'd zeta_nu, wt = 0',                                 &
   'd |sigma|, wt', 'd |kappa|, wt', 'd |j_nu|, wt', 'd |zeta_nu|, wt',                                         &
   'd sigma vs T_kin', 'd kappa vs T_kin', 'd j_nu vs T_kin', 'd zeta_nu vs T_kin']

type :: scan_job
   !< A one-parameter scan of the bipolar f0, as the driver appelbe_electrons does it: the parameter scan_param of the
   !< reference inp%bipolar takes scan_n values on [scan_min, scan_max] (scan_value); each row is electron_scan_row against
   !< the Maxwellian's responses at omega tau = 0 and inp%omega_tau. Step 1 builds the Maxwellian, step 1 + i row i.
   type(gui_inputs)              :: inp               !< The inputs (a copy).
   integer(I4P)                  :: done = 0_I4P      !< Steps done.
   logical                       :: failed = .false.  !< A step failed: error says why.
   character(len=:), allocatable :: error             !< Why ('' while none).
   real(R8P), allocatable        :: p(:)              !< The parameter's values.
   real(R8P), allocatable        :: o(:,:)            !< Readouts (row, n_readouts).
   real(R8P), allocatable        :: max_dev(:)        !< max |T_slope - T_TS| per row.
   integer(I4P), allocatable     :: monotone(:)       !< Monotone f0 in the ECE window per row.
   type(kinetic_operator)        :: om                !< The Maxwellian at T_e.
   type(kinetic_response)        :: rm(2)             !< Its responses at omega tau = 0 and inp%omega_tau.
   contains
      procedure, pass(self) :: setup    => scan_setup    !< Copy the inputs, size the rows.
      procedure, pass(self) :: steps    => scan_steps    !< Number of steps.
      procedure, pass(self) :: step     => scan_step     !< Do the next step.
      procedure, pass(self) :: finished => scan_finished !< Every step done (or a failure).
      procedure, pass(self) :: column   => scan_column   !< A column of the rows (SCAN_COLUMNS) as reals.
endtype scan_job

contains
   pure function omega_tau_grid() result(wt)
   !< The sweep's Hall parameters: 0, then 10^-2 to 10^2 with four values per decade (18 values).
   real(R8P) :: wt(18) !< Hall parameters.
   integer   :: k      !< Counter.

   wt(1) = 0._R8P
   wt(2:) = [(10._R8P**(-2._R8P + 0.25_R8P * real(k, R8P)), k = 0, 16)]
   endfunction omega_tau_grid

   subroutine setup(self, inp)
   !< Copy the inputs and size the results; no solve yet.
   class(solve_job), intent(inout) :: self !< The job.
   type(gui_inputs), intent(in)    :: inp  !< Inputs.

   self%inp = inp
   self%done = 0_I4P
   self%failed = .false.
   self%error = ''
   self%readouts = 0._R8P
   self%wt = omega_tau_grid()
   if (allocated(self%r)) deallocate(self%r)
   allocate(self%r(size(self%wt), N_CURVES))
   if (allocated(self%f1)) deallocate(self%f1)
   endsubroutine setup

   pure function steps(self) result(n)
   !< Number of steps: the operators, readouts and f1, then one per Hall parameter of the sweep.
   class(solve_job), intent(in) :: self !< The job.
   integer(I4P)                 :: n    !< Steps.

   n = 0_I4P
   if (allocated(self%wt)) n = 1_I4P + size(self%wt, kind=I4P)
   endfunction steps

   pure function finished(self) result(yes)
   !< Every step done, or a step failed.
   class(solve_job), intent(in) :: self !< The job.
   logical                      :: yes  !< Finished.

   yes = self%failed .or. self%done >= self%steps()
   endfunction finished

   subroutine step(self)
   !< Do the next step (nothing once finished). A rejected input sets failed and error.
   class(solve_job), intent(inout) :: self !< The job.
   type(kinetic_response)          :: rm(2) !< Maxwellian responses at omega tau = 0 and inp%omega_tau.
   integer(I4P)                    :: stat  !< Status.
   integer(I4P)                    :: k     !< Hall parameter of this step.

   if (self%finished()) return
   if (self%done == 0_I4P) then
      self%error = input_error(self%inp)
      if (len(self%error) > 0) then
         self%failed = .true. ; return
      endif
      call init_electrons(self%inp, self%ob, stat, self%error)
      if (stat == 0_I4P) call self%om%init(par=physical_params(self%inp), n_nodes=self%inp%n_nodes, &
                                           u_max=self%inp%u_max, stat=stat, errmsg=self%error)
      if (stat == 0_I4P) call self%ot%init(par=physical_params(self%inp), n_nodes=self%inp%n_nodes,          &
                                           u_max=self%inp%u_max, electrons=electron_maxwellian,             &
                                           electron_params=[kinetic_temperature(self%ob)], stat=stat, errmsg=self%error)
      if (stat /= 0_I4P) then
         self%failed = .true. ; return
      endif
      if (.not. self%ob%par%u_a > 0._R8P) then
         self%failed = .true. ; self%error = 'no fast ions: their energy must be positive' ; return
      endif
      rm(1) = self%om%response(omega_tau=0._R8P)
      rm(2) = self%om%response(omega_tau=self%inp%omega_tau)
      call electron_readouts(self%ob, rm, [0._R8P, self%inp%omega_tau], self%readouts, stat=stat, errmsg=self%error)
      if (stat /= 0_I4P) then
         self%failed = .true. ; return
      endif
      self%f1 = electron_f1(self%ob, self%om, [0._R8P, self%inp%omega_tau])
   else
      k = self%done
      self%r(k, CURVE_F0)           = self%ob%response(omega_tau=self%wt(k))
      self%r(k, CURVE_MAXWELLIAN)   = self%om%response(omega_tau=self%wt(k))
      self%r(k, CURVE_EQUAL_ENERGY) = self%ot%response(omega_tau=self%wt(k))
   endif
   self%done = self%done + 1_I4P
   endsubroutine step

   subroutine scan_setup(self, inp)
   !< Copy the inputs and size the rows of the scan inp%scan_param.
   class(scan_job),  intent(inout) :: self !< The job.
   type(gui_inputs), intent(in)    :: inp  !< Inputs.
   integer(I4P)                    :: n, i !< Rows, counter.

   self%inp = inp
   self%done = 0_I4P
   self%failed = .false.
   self%error = ''
   n = max(2_I4P, inp%scan_n(inp%scan_param))
   self%p = [(scan_value(inp%scan_min(inp%scan_param), inp%scan_max(inp%scan_param), n, i), i = 1_I4P, n)]
   if (allocated(self%o)) deallocate(self%o)
   allocate(self%o(n, n_readouts), self%max_dev(n), self%monotone(n))
   self%o = 0._R8P ; self%max_dev = 0._R8P ; self%monotone = 0_I4P
   endsubroutine scan_setup

   pure function scan_steps(self) result(n)
   !< Number of steps: the Maxwellian, then one per row (0 before setup).
   class(scan_job), intent(in) :: self !< The job.
   integer(I4P)                :: n    !< Steps.

   n = 0_I4P
   if (allocated(self%p)) n = 1_I4P + size(self%p, kind=I4P)
   endfunction scan_steps

   pure function scan_finished(self) result(yes)
   !< Every step done, or a step failed.
   class(scan_job), intent(in) :: self !< The job.
   logical                     :: yes  !< Finished.

   yes = self%failed .or. self%done >= self%steps()
   endfunction scan_finished

   subroutine scan_step(self)
   !< Do the next step: the Maxwellian's responses, then one row (the driver's loop body).
   class(scan_job), intent(inout) :: self !< The job.
   type(kinetic_operator)         :: ob   !< The bipolar f0 of this row.
   type(gui_inputs)               :: row  !< The inputs of this row.
   integer(I4P)                   :: stat, i !< Status, row.
   type(kinetic_params)           :: par  !< Its physical parameters.

   if (self%finished()) return
   if (self%done == 0_I4P) then
      row = self%inp
      row%f0_kind = F0_BIPOLAR
      self%error = input_error(row)
      par = physical_params(row)
      if (len(self%error) == 0 .and. .not. par%u_a > 0._R8P) self%error = 'no fast ions: their energy must be positive'
      if (len(self%error) > 0) then
         self%failed = .true. ; return
      endif
      call self%om%init(par=physical_params(row), n_nodes=row%n_nodes, u_max=row%u_max, stat=stat, errmsg=self%error)
      if (stat /= 0_I4P) then
         self%failed = .true. ; return
      endif
      self%rm(1) = self%om%response(omega_tau=0._R8P)
      self%rm(2) = self%om%response(omega_tau=self%inp%omega_tau)
   else
      i = self%done
      row = self%inp
      row%f0_kind = F0_BIPOLAR
      row%bipolar(self%inp%scan_param) = self%p(i)
      self%error = input_error(row)
      if (len(self%error) > 0) then
         self%failed = .true. ; return
      endif
      call init_electrons(row, ob, stat, self%error)
      if (stat == 0_I4P) call electron_scan_row(ob, self%rm, [0._R8P, self%inp%omega_tau], self%o(i, :), &
                                                self%max_dev(i), self%monotone(i), stat=stat, errmsg=self%error)
      if (stat /= 0_I4P) then
         self%failed = .true.
         self%error = trim(SCAN_PARAMETERS(self%inp%scan_param))//' = '//trim(real_text(self%p(i)))//': '//self%error
         return
      endif
   endif
   self%done = self%done + 1_I4P
   endsubroutine scan_step

   pure function scan_column(self, c) result(y)
   !< Column c of SCAN_COLUMNS for the rows done so far: readouts 1:5, max_dev, monotone, readouts 6:17.
   class(scan_job), intent(in) :: self !< The job.
   integer(I4P),    intent(in) :: c    !< Column.
   real(R8P), allocatable      :: y(:) !< Values.
   integer(I4P)                :: n    !< Rows done.

   n = max(0_I4P, self%done - 1_I4P)
   select case (c)
   case (1_I4P:5_I4P) ; y = self%o(:n, c)
   case (6_I4P)       ; y = self%max_dev(:n)
   case (7_I4P)       ; y = real(self%monotone(:n), R8P)
   case default       ; y = self%o(:n, c - 2_I4P)
   endselect
   endfunction scan_column

   pure function real_text(x) result(t)
   !< A real as short text.
   real(R8P), intent(in)         :: x !< Value.
   character(len=:), allocatable :: t !< Text.
   character(len=32)             :: b !< Buffer.

   write(b, '(G0.6)') x
   t = trim(adjustl(b))
   endfunction real_text

   pure subroutine species_defaults(inp)
   !< Z, mass and energy of the chosen species (custom keeps what the user set).
   type(gui_inputs), intent(inout) :: inp !< Inputs.

   select case (inp%species)
   case (SPECIES_ALPHA)
      inp%z_a = 2._R8P ; inp%mass_amu = m_alpha / amu    ; inp%e_mev = 3.45_R8P
   case (SPECIES_PROTON)
      inp%z_a = 1._R8P ; inp%mass_amu = m_proton / amu   ; inp%e_mev = 3.02_R8P
   case (SPECIES_CARBON)
      inp%z_a = 6._R8P ; inp%mass_amu = m_carbon12 / amu ; inp%e_mev = 200._R8P
   endselect
   endsubroutine species_defaults

   pure function input_error(inp) result(msg)
   !< Inputs outside their domain, before any library call ('' when none): a temperature, an energy, a charge or a mass
   !< not positive, a negative density ratio, a width w not positive.
   type(gui_inputs), intent(in)  :: inp !< Inputs.
   character(len=:), allocatable :: msg !< The first input out of its domain.

   msg = ''
   if (.not. inp%te_kev > 0._R8P) then
      msg = 'T_e must be positive'
   elseif (.not. inp%z_i > 0._R8P) then
      msg = 'Z_i must be positive'
   elseif (.not. inp%z_a > 0._R8P) then
      msg = 'Z_a must be positive'
   elseif (.not. inp%mass_amu > 0._R8P) then
      msg = 'the fast-ion mass must be positive'
   elseif (.not. inp%e_mev > 0._R8P) then
      msg = 'the fast-ion energy must be positive'
   elseif (.not. inp%n_ratio >= 0._R8P) then
      msg = 'n_a / n_e must not be negative'
   elseif (.not. inp%u_max > 0._R8P) then
      msg = 'u_max must be positive'
   elseif (.not. inp%omega_tau >= 0._R8P) then
      msg = 'omega tau must not be negative'
   elseif (inp%f0_kind == F0_MAXWELLIAN .and. .not. inp%t_ratio > 0._R8P) then
      msg = 'T / T_e must be positive'
   elseif (inp%f0_kind == F0_BIPOLAR .and. .not. inp%bipolar(3) > 0._R8P) then
      msg = 'the width w must be positive'
   endif
   endfunction input_error

   pure function physical_params(inp) result(par)
   !< kinetic_params of the inputs: Z_i, Z_a, m_e / m_a, n_a / n_e, and u_a = v_a / v_Te from E_a and T_e. The mass is the
   !< library's constant for a named species (m_alpha, m_proton, m_carbon12), the user's amu for a custom one.
   type(gui_inputs), intent(in) :: inp !< Inputs.
   type(kinetic_params)         :: par !< Parameters.
   real(R8P)                    :: m_a !< Fast-ion mass [kg].

   select case (inp%species)
   case (SPECIES_ALPHA)  ; m_a = m_alpha
   case (SPECIES_PROTON) ; m_a = m_proton
   case (SPECIES_CARBON) ; m_a = m_carbon12
   case default          ; m_a = inp%mass_amu * amu
   endselect
   par%z_i        = inp%z_i
   par%z_a        = inp%z_a
   par%mass_ratio = m_e / m_a
   par%n_ratio    = inp%n_ratio
   par%u_a        = speed_ratio(inp%e_mev * MeV_J, m_a, inp%te_kev * keV_J)
   endfunction physical_params

   subroutine init_electrons(inp, op, stat, errmsg)
   !< Build op with the chosen f0 on the inputs' grid; stat /= 0 and the reason when the library rejects the input.
   type(gui_inputs),              intent(in)    :: inp    !< Inputs.
   type(kinetic_operator),        intent(inout) :: op     !< Operator.
   integer(I4P),                  intent(out)   :: stat   !< 0 on success.
   character(len=:), allocatable, intent(out)   :: errmsg !< Why not.

   select case (inp%f0_kind)
   case (F0_MAXWELLIAN)
      call op%init(par=physical_params(inp), n_nodes=inp%n_nodes, u_max=inp%u_max, electrons=electron_maxwellian, &
                   electron_params=[inp%t_ratio], stat=stat, errmsg=errmsg)
   case (F0_BIPOLAR)
      call op%init(par=physical_params(inp), n_nodes=inp%n_nodes, u_max=inp%u_max, electrons=electron_bipolar, &
                   electron_params=inp%bipolar, stat=stat, errmsg=errmsg)
   case default
      if (.not. allocated(inp%table_x)) then
         stat = 1_I4P ; errmsg = 'no table loaded: open a file with two columns, u_L and f0'
         return
      endif
      errmsg = electron_table_check(inp%table_x, inp%table_f)
      if (len(errmsg) > 0) then
         stat = 1_I4P ; return
      endif
      call op%init(par=physical_params(inp), n_nodes=inp%n_nodes, u_max=inp%u_max, electrons=electron_table, &
                   electron_params=electron_table_params(inp%table_x, inp%table_f), stat=stat, errmsg=errmsg)
   endselect
   endsubroutine init_electrons

   subroutine load_table(inp, path, stat, errmsg)
   !< Read a two-column table (u_L, f0; '#' comments) into the inputs and select it; on a failure nothing changes.
   type(gui_inputs),              intent(inout) :: inp    !< Inputs.
   character(*),                  intent(in)    :: path   !< File.
   integer(I4P),                  intent(out)   :: stat   !< 0 on success.
   character(len=:), allocatable, intent(out)   :: errmsg !< Why not.
   real(R8P), allocatable                       :: x(:), f(:) !< Columns.

   call read_table(path, x, f, stat=stat, errmsg=errmsg)
   if (stat /= 0_I4P) return
   errmsg = electron_table_check(x, f)
   if (len(errmsg) > 0) then
      stat = 1_I4P ; errmsg = trim(path)//': '//errmsg
      return
   endif
   call move_alloc(x, inp%table_x)
   call move_alloc(f, inp%table_f)
   inp%table_path = path
   inp%f0_kind = F0_TABLE
   endsubroutine load_table

   subroutine compute_f0_view(inp, v)
   !< The f0 panel's content: the operators of f0, of the Maxwellian at T_e and of the one at T_kin, their profiles, and
   !< the temperatures TS, ECE and the energy moment read (milliseconds at 801 nodes: called on every input change).
   type(gui_inputs), intent(in)    :: inp   !< Inputs.
   type(f0_view),    intent(inout) :: v     !< The view.
   integer(I4P)                    :: stat  !< Status.
   real(R8P), allocatable          :: t(:)  !< Slope temperature.
   logical, allocatable            :: win(:) !< Nodes in the ECE window.

   v%valid = .false.
   v%error = input_error(inp)
   if (len(v%error) > 0) return
   call init_electrons(inp, v%ob, stat, v%error)
   if (stat /= 0_I4P) return
   call v%om%init(par=physical_params(inp), n_nodes=inp%n_nodes, u_max=inp%u_max, stat=stat, errmsg=v%error)
   if (stat /= 0_I4P) return
   v%t_kin = kinetic_temperature(v%ob)
   call v%ot%init(par=physical_params(inp), n_nodes=inp%n_nodes, u_max=inp%u_max, electrons=electron_maxwellian, &
                  electron_params=[v%t_kin], stat=stat, errmsg=v%error)
   if (stat /= 0_I4P) then
      v%error = 'the Maxwellian of the same energy (T = T_kin): '//v%error
      return
   endif
   v%prof     = electron_profile(v%ob, v%om)
   v%prof_kin = electron_profile(v%ob, v%ot)
   call ts_fit(v%ob, ts_windows(1), v%t_ts(1), v%c_ts(1))
   call ts_fit(v%ob, ts_windows(2), v%t_ts(2), v%c_ts(2))
   v%s_fit = reshape([exp(v%c_ts(1) - v%prof(:, 1)**2 / v%t_ts(1)), exp(v%c_ts(2) - v%prof(:, 1)**2 / v%t_ts(2))], &
                     [size(v%prof, 1), 2])
   t   = v%prof(:, 8)
   win = v%prof(:, 2) >= ece_window(1) .and. v%prof(:, 2) <= ece_window(2)
   v%t_slope = [minval(t, mask=win), maxval(t, mask=win)]
   ! the slides' measures of the distortion, on the bulk and the ECE window (u_L <= 4); node 1 has f0' = 0
   win = v%prof(:, 2) <= ece_window(2)
   v%peak_df  = [maxval(abs(v%prof(:, 6)), mask=win), maxval(abs(v%prof_kin(:, 6)), mask=win)]
   win(1) = .false.
   v%peak_ddf = [maxval(abs(v%prof(:, 7)), mask=win), maxval(abs(v%prof_kin(:, 7)), mask=win)]
   v%u_a = v%ob%par%u_a
   v%valid = .true.
   endsubroutine compute_f0_view
endmodule appelbe_gui_model
