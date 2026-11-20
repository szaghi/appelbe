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
use appelbe_eedf,           only : ts_temperature, kinetic_temperature
use appelbe_electron_study, only : electron_profile, ts_windows, ece_window
use appelbe_io,             only : read_table
use appelbe_kinetic,        only : kinetic_params, kinetic_operator
use appelbe_plasma,         only : speed_ratio

implicit none
private
public :: F0_MAXWELLIAN, F0_BIPOLAR, F0_TABLE, F0_KINDS
public :: SPECIES_ALPHA, SPECIES_PROTON, SPECIES_CARBON, SPECIES_CUSTOM, SPECIES_NAMES
public :: gui_inputs, f0_view
public :: species_defaults, input_error, physical_params, init_electrons, load_table, compute_f0_view

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
   real(R8P)                     :: t_slope(2) = 0._R8P !< Range of the slope temperature in the ECE window [T_e].
   real(R8P)                     :: u_a = 0._R8P    !< v_a / v_Te of the fast ions.
endtype f0_view

contains
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
   v%t_ts     = [ts_temperature(v%ob, ts_windows(1)), ts_temperature(v%ob, ts_windows(2))]
   t   = v%prof(:, 8)
   win = v%prof(:, 2) >= ece_window(1) .and. v%prof(:, 2) <= ece_window(2)
   v%t_slope = [minval(t, mask=win), maxval(t, mask=win)]
   v%u_a = v%ob%par%u_a
   v%valid = .true.
   endsubroutine compute_f0_view
endmodule appelbe_gui_model
