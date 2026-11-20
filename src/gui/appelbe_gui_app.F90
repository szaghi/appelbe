!< The GUI's interface: the windows and their widgets, declared every frame from the state (FIGURE, immediate mode).
module appelbe_gui_app
!< The GUI's interface: the windows and their widgets, declared every frame from the state (FIGURE, immediate mode).
!<
!< gui_object holds the inputs and the views the panels draw; gui%frame(app) declares one frame. The program
!< (appelbe_gui) and the headless tests (src/gui/tests) call the same procedure, so the tests drive the interface that
!< ships. The panels draw arrays computed by appelbe_gui_model (library calls) and never compute physics themselves.
!< Numbers are shown in read-only fields: a test reads them by path ('Diagnostics/T_kin') as the user sees them.
use, intrinsic :: iso_fortran_env, only : int32, real64
use penf,                          only : I4P, R8P
use figure,                        only : app_object, FIG_OK, task_object, ig_begin, ig_begin_disabled,                &
                                          ig_begin_main_menu_bar, ig_begin_menu, ig_button, ig_collapsing_header,      &
                                          ig_combo, ig_dock_id, ig_dock_layout_begin, ig_dock_layout_end,              &
                                          ig_dock_space, ig_dock_split, ig_dock_window, ig_em, ig_end,                 &
                                          ig_end_disabled, ig_end_main_menu_bar, ig_end_menu, ig_focus_window,         &
                                          ig_input, ig_menu_item,                                                      &
                                          ig_pop_item_width, ig_progress_bar, ig_push_item_width, ig_radio,            &
                                          ig_same_line, ig_separator_text, ig_text, ig_text_colored, ig_text_disabled, &
                                          ig_text_wrapped, ip_begin_plot, ip_end_plot, ip_inf_lines, ip_line,          &
                                          ip_setup_axes, ip_setup_axes_limits, ip_setup_legend
use appelbe,                       only : n_readouts
use appelbe_gui_model,             only : gui_inputs, f0_view, solve_job, F0_MAXWELLIAN, F0_BIPOLAR, F0_TABLE,         &
                                          F0_KINDS, SPECIES_CUSTOM, SPECIES_NAMES, CURVE_F0, CURVE_MAXWELLIAN,         &
                                          CURVE_EQUAL_ENERGY, N_CURVES, species_defaults, compute_f0_view, load_table
use appelbe_gui_tasks,             only : solve_work

implicit none
private
public :: gui_object, gui_version, TABLE_FILTERS
public :: WINDOW_INPUTS, WINDOW_F0, WINDOW_DIAGNOSTICS, WINDOW_TRANSPORT
public :: QUANTITIES, Q_SIGMA, Q_BETA, Q_KAPPA, Q_J_NU, Q_ZETA_NU, DRIVES, READOUT_LABELS

character(len=*), parameter :: gui_version        = '0.1.0'        !< Version of the GUI.
character(len=*), parameter :: WINDOW_INPUTS      = 'Inputs'       !< The inputs' window.
character(len=*), parameter :: WINDOW_F0          = 'Electron f0'  !< The f0 panel.
character(len=*), parameter :: WINDOW_DIAGNOSTICS = 'Diagnostics'  !< What TS and ECE read.
character(len=*), parameter :: WINDOW_TRANSPORT   = 'Transport'    !< Transport and the alpha closure.
!> Types offered by the table dialog.
character(len=*), parameter :: TABLE_FILTERS(2) = [character(len=32) :: 'Tables|dat;txt;csv;tab', 'All files|*']

integer(int32), parameter :: Q_SIGMA = 1_int32, Q_BETA = 2_int32, Q_KAPPA = 3_int32, Q_J_NU = 4_int32, &
                             Q_ZETA_NU = 5_int32 !< Quantities of the transport plots.
!> Their names, in the order of the Q_* codes.
character(len=*), parameter :: QUANTITIES(5) = [character(len=40) :: 'sigma (conductivity)', 'beta (thermoelectric)', &
                                                'kappa (thermal conductivity)', 'j_nu (alpha current)', &
                                                'zeta_nu (alpha heat flow)']
!> The f1 profiles of electron_f1, in its column pairs (Maxwellian, f0): columns 2:3, 4:5, 6:7, then 8/10 and 9/11.
character(len=*), parameter :: DRIVES(5) = [character(len=40) :: 'E field, wt = 0', 'grad T, wt = 0', &
                                            'alpha flux, wt = 0', 'alpha flux, wt: perp', 'alpha flux, wt: wedge']
!> Labels of the transport readouts (electron_readouts 6:17), shown in %.
character(len=*), parameter :: READOUT_LABELS(12) = [character(len=40) ::                                        &
   'sigma, wt = 0',       'kappa, wt = 0',       'j_nu, wt = 0',       'zeta_nu, wt = 0',                      &
   '|sigma|, wt',         '|kappa|, wt',         '|j_nu|, wt',         '|zeta_nu|, wt',                        &
   'sigma vs T_kin',      'kappa vs T_kin',      'j_nu vs T_kin',      'zeta_nu vs T_kin']
real(real64), parameter :: RED(3) = [0.90_real64, 0.35_real64, 0.30_real64] !< Colour of errors.

type :: gui_object
   !< The GUI's state: inputs, the views computed from them, the solve on its task, the plots' selections.
   type(gui_inputs)              :: inp                  !< What the user set.
   type(f0_view)                 :: view                 !< The f0 panel's content, recomputed on every input change.
   integer(int32)                :: revision = 0_int32   !< Bumped on every input change.
   type(task_object)             :: task                 !< The solve's task.
   logical                       :: solving = .false.    !< The task runs.
   type(solve_job)               :: job                  !< The last solve's result (job%done = 0: none yet).
   integer(int32)                :: job_revision = -1_int32 !< The inputs' revision the job was started on.
   integer(int32)                :: quantity = Q_J_NU    !< Quantity of the transport plots (Q_*).
   integer(int32)                :: component = 1_int32  !< 1 perp, 2 wedge.
   integer(int32)                :: drive = 3_int32      !< f1 profile shown (DRIVES).
   real(R8P), allocatable        :: tx(:)                !< The sweep's omega tau > 0.
   real(R8P), allocatable        :: ty(:,:)              !< The chosen component of the quantity (wt, curve).
   real(R8P), allocatable        :: tdy(:,:)             !< |q_f0| / |q_ref| - 1: ref T_kin (1), T_e (2) (wt, ref).
   character(len=:), allocatable :: message              !< The last message (a table loaded, a failure): '' for none.
   logical                       :: quit = .false.       !< File > Quit was picked.
   logical                       :: front = .false.      !< The f0 tab was brought to the front (once, at start).
   contains
      procedure, pass(self) :: init        !< The views of the default inputs.
      procedure, pass(self) :: frame       !< Declare one frame: menus, dock space, windows.
      procedure, pass(self) :: open_table  !< Load a table file (as the dialog does).
      procedure, pass(self) :: start_solve !< Start the solve's task on the current inputs.
      procedure, pass(self) :: poll_solve  !< Take the solve's result once its task is done.
      procedure, pass(self) :: stale       !< The inputs changed since the shown solve.
      procedure, pass(self) :: inputs_changed !< Recompute the views after an input change.
      procedure, pass(self) :: select_curves  !< Fill tx, ty, tdy from the job for the chosen quantity, component.
endtype gui_object

contains
   subroutine init(self)
   !< Compute the views of the current inputs (the driver's reference case by default).
   class(gui_object), intent(inout) :: self !< The GUI.

   self%message = ''
   call compute_f0_view(self%inp, self%view)
   endsubroutine init

   subroutine inputs_changed(self)
   !< Recompute the f0 view (milliseconds) and mark the solve stale.
   class(gui_object), intent(inout) :: self !< The GUI.

   self%revision = self%revision + 1_int32
   call compute_f0_view(self%inp, self%view)
   endsubroutine inputs_changed

   pure function stale(self) result(yes)
   !< A solve is shown and the inputs changed since it started.
   class(gui_object), intent(in) :: self !< The GUI.
   logical                       :: yes  !< Stale.

   yes = self%job%done > 0 .and. self%job_revision /= self%revision
   endfunction stale

   subroutine open_table(self, path)
   !< Load a table (u_L, f0) and show it; a file the library refuses leaves the inputs as they were, with the reason.
   class(gui_object), intent(inout) :: self   !< The GUI.
   character(*),      intent(in)    :: path   !< File.
   integer(I4P)                     :: stat   !< Status.
   character(len=:), allocatable    :: errmsg !< Why not.

   call load_table(self%inp, path, stat, errmsg)
   if (stat /= 0_I4P) then
      self%message = errmsg
   else
      self%message = 'table read: '//trim(path)
      call self%inputs_changed()
   endif
   endsubroutine open_table

   subroutine start_solve(self)
   !< Start the solves (readouts, f1, the omega tau sweep) on a worker thread, on a copy of the current inputs.
   class(gui_object), intent(inout) :: self !< The GUI.
   type(solve_job)                  :: job  !< The job given to the task (copied by FIGURE).
   integer(int32)                   :: stat !< Status.

   if (self%solving) return
   call job%setup(self%inp)
   call self%task%start(solve_work, job, stat=stat)
   if (stat /= FIG_OK) then
      self%message = 'the solve could not start a thread'
      return
   endif
   self%solving = .true.
   self%job_revision = self%revision
   endsubroutine start_solve

   subroutine poll_solve(self)
   !< Once the task is done, take its job (a cancelled one is dropped: the last complete solve stays shown).
   class(gui_object), intent(inout) :: self !< The GUI.
   class(*), allocatable            :: data !< The task's data.
   integer(int32)                   :: stat !< Status.

   if (.not. self%solving) return
   if (.not. self%task%done()) return
   self%solving = .false.
   call self%task%result(data, stat=stat)
   if (stat /= FIG_OK) then
      self%message = 'the solve failed'
      return
   endif
   select type (data)
   type is (solve_job)
      if (data%failed) then
         self%message = 'solve: '//data%error
      elseif (data%finished()) then
         self%job = data
         self%message = ''
         call self%select_curves()
      else
         self%message = 'solve cancelled'
      endif
   endselect
   endsubroutine poll_solve

   subroutine select_curves(self)
   !< The arrays the transport plots read: the chosen component of the chosen quantity for each curve, and the change
   !< of its modulus against the two Maxwellians, at omega tau > 0 (the log axis).
   class(gui_object), intent(inout) :: self !< The GUI.
   complex(R8P), allocatable        :: q(:,:) !< The quantity (wt, curve).
   integer                          :: n, k, c !< Sizes, counters.

   if (self%job%done == 0) return
   n = size(self%job%wt) - 1
   allocate(q(n, N_CURVES))
   do c = 1, N_CURVES
      do k = 1, n
         associate(r => self%job%r(k + 1, c))
            select case (self%quantity)
            case (Q_SIGMA)   ; q(k, c) = r%sigma
            case (Q_BETA)    ; q(k, c) = r%beta()
            case (Q_KAPPA)   ; q(k, c) = r%kappa()
            case (Q_J_NU)    ; q(k, c) = r%j_nu
            case default     ; q(k, c) = r%zeta_nu
            endselect
         endassociate
      enddo
   enddo
   self%tx = self%job%wt(2:)
   if (self%component == 1_int32) then
      self%ty = real(q, R8P)
   else
      self%ty = aimag(q)
   endif
   self%tdy = reshape([abs(q(:, CURVE_F0)) / abs(q(:, CURVE_EQUAL_ENERGY)) - 1._R8P, &
                       abs(q(:, CURVE_F0)) / abs(q(:, CURVE_MAXWELLIAN)) - 1._R8P], [n, 2])
   endsubroutine select_curves

   subroutine frame(self, app)
   !< One frame of the interface (after app%next_frame()).
   class(gui_object), intent(inout) :: self !< The GUI.
   type(app_object),  intent(inout) :: app  !< FIGURE's application.

   call self%poll_solve()
   call menus(self, app)
   call layout()
   call inputs_window(self, app)
   call f0_window(self)
   call diagnostics_window(self)
   call transport_window(self)
   ! the tab in front after the layout is Dear ImGui's choice: the f0 panel, once its window exists
   if (.not. self%front) self%front = ig_focus_window(WINDOW_F0)
   endsubroutine frame

   ! private
   subroutine menus(self, app)
   !< The main menu bar: File (open a table, quit).
   type(gui_object), intent(inout) :: self !< The GUI.
   type(app_object), intent(inout) :: app  !< FIGURE's application.

   if (ig_begin_main_menu_bar()) then
      if (ig_begin_menu('File')) then
         if (ig_menu_item('Open f0 table...')) call ask_table(app)
         if (ig_menu_item('Quit')) self%quit = .true.
         call ig_end_menu()
      endif
      call ig_end_main_menu_bar()
   endif
   endsubroutine menus

   subroutine layout()
   !< The dock space: inputs on the left, the panels on the right (tabs), on the first frame; then as the user moves them.
   integer(int32) :: root, left, right !< Dock nodes.

   root = ig_dock_id('appelbe')
   if (ig_dock_layout_begin(root)) then
      call ig_dock_split(root, 'left', 0.3_real64, left, right)
      call ig_dock_window(WINDOW_INPUTS, left)
      call ig_dock_window(WINDOW_F0, right)
      call ig_dock_window(WINDOW_DIAGNOSTICS, right)
      call ig_dock_window(WINDOW_TRANSPORT, right)
      call ig_dock_layout_end(root)
   endif
   call ig_dock_space(root)
   endsubroutine layout

   subroutine ask_table(app)
   !< Open the system's file dialog for a table, or FIGURE's browser where there is none (remote mode).
   type(app_object), intent(inout) :: app  !< FIGURE's application.
   integer(int32)                   :: stat !< Status.

   call app%open_file_dialog('table', TABLE_FILTERS, stat=stat)
   if (stat /= FIG_OK) call app%open_file_browser('table', TABLE_FILTERS)
   endsubroutine ask_table

   subroutine readout(label, value, format)
   !< A number shown in a read-only field (a test reads it by path, as shown).
   character(*), intent(in) :: label  !< Label (and path segment).
   real(R8P),    intent(in) :: value  !< Value.
   character(*), intent(in) :: format !< printf format.
   real(R8P)                :: v      !< Copy (the field takes inout).

   v = value
   if (ig_input(label, v, format=format, read_only=.true.)) continue
   endsubroutine readout

   subroutine inputs_window(self, app)
   !< The inputs: electron f0, plasma, fast ions, grid. Any change recomputes the f0 view (milliseconds).
   type(gui_object), intent(inout) :: self    !< The GUI.
   type(app_object), intent(inout) :: app     !< FIGURE's application.
   character(len=:), allocatable    :: chosen  !< Path from the file dialog.
   logical                          :: done, cancelled, changed !< Dialog answered, cancelled; an input changed.
   integer(int32)                   :: stat, species !< Status; species before the combo.
   character(len=64)                :: line    !< Text.

   changed = .false.
   call app%file_dialog_result('table', chosen, done, cancelled, stat=stat)
   if (done .and. .not. cancelled .and. stat == FIG_OK) call self%open_table(chosen)
   if (ig_begin(WINDOW_INPUTS)) then
      call ig_push_item_width(ig_em(9))
      call ig_separator_text('Electron f0')
      changed = ig_combo('f0', self%inp%f0_kind, F0_KINDS) .or. changed
      select case (self%inp%f0_kind)
      case (F0_MAXWELLIAN)
         changed = ig_input('T / T_e', self%inp%t_ratio, format='%.4g') .or. changed
      case (F0_BIPOLAR)
         changed = ig_input('A', self%inp%bipolar(1), format='%.4g') .or. changed
         changed = ig_input('u_0', self%inp%bipolar(2), format='%.4g') .or. changed
         changed = ig_input('w', self%inp%bipolar(3), format='%.4g') .or. changed
         call ig_text_disabled('f0 = f_M [1 + A x exp(-x^2/2)], x = (u_L - u_0) / w')
      case (F0_TABLE)
         if (ig_button('Open table...')) call ask_table(app)
         if (len_trim(self%inp%table_path) > 0) then
            call ig_text_wrapped(trim(self%inp%table_path))
         else
            call ig_text_disabled('no table: two columns u_L = p / sqrt(m_e T_e) and f0')
         endif
      endselect
      call ig_separator_text('Plasma')
      changed = ig_input('T_e [keV]', self%inp%te_kev, format='%.4g') .or. changed
      changed = ig_input('Z_i', self%inp%z_i, format='%.4g') .or. changed
      call ig_separator_text('Fast ions')
      species = self%inp%species
      if (ig_combo('species', self%inp%species, SPECIES_NAMES)) then
         if (self%inp%species /= species) call species_defaults(self%inp)
         changed = .true.
      endif
      if (self%inp%species == SPECIES_CUSTOM) then
         changed = ig_input('Z_a', self%inp%z_a, format='%.4g') .or. changed
         changed = ig_input('mass [amu]', self%inp%mass_amu, format='%.6g') .or. changed
      endif
      changed = ig_input('E [MeV]', self%inp%e_mev, format='%.4g') .or. changed
      changed = ig_input('n_a / n_e', self%inp%n_ratio, format='%.3g') .or. changed
      if (self%view%valid) then
         write(line, '(A,F6.4)') 'v_a / v_Te = ', self%view%u_a
         call ig_text_disabled(trim(line))
      endif
      call ig_separator_text('Grid')
      changed = ig_input('nodes', self%inp%n_nodes, step=2_int32) .or. changed
      changed = ig_input('u_max', self%inp%u_max, format='%.4g') .or. changed
      call ig_pop_item_width()
      if (changed) call self%inputs_changed()
      if (.not. self%view%valid) call ig_text_colored('[!!] '//self%view%error, RED)
      if (len(self%message) > 0) call ig_text_wrapped(self%message)
   endif
   call ig_end()
   endsubroutine inputs_window

   subroutine f0_window(self)
   !< f0 against the Maxwellian at T_e and the one of the same energy (T = T_kin), log scale, against u_L.
   type(gui_object), intent(inout) :: self !< The GUI.

   if (ig_begin(WINDOW_F0)) then
      if (self%view%valid) then
         if (ip_begin_plot('f0 and the Maxwellians', height=-1.0_real64)) then
            call ip_setup_axes('u_L = p / sqrt(m_e T_e)', 'f0', yscale='log')
            call ip_setup_axes_limits(0._real64, 6._real64, 1.e-8_real64, 1._real64)
            call ip_setup_legend('ne')
            associate(p => self%view%prof, k => self%view%prof_kin)
               call ip_line('f0', p(:, 2), p(:, 5))
               call ip_line('Maxwellian, T_e', p(:, 2), p(:, 4))
               call ip_line('Maxwellian, T_kin (same energy)', k(:, 2), k(:, 4))
            endassociate
            call ip_end_plot()
         endif
      else
         call ig_text_colored('[!!] '//self%view%error, RED)
      endif
   endif
   call ig_end()
   endsubroutine f0_window

   subroutine diagnostics_window(self)
   !< What TS and ECE read from f0: the temperatures, the distortion, the slope temperature, the TS spectrum and its fits.
   type(gui_object), intent(inout) :: self !< The GUI.
   real(real64)                     :: h    !< Plot height [pixels].

   if (ig_begin(WINDOW_DIAGNOSTICS)) then
      if (.not. self%view%valid) then
         call ig_text_colored('[!!] '//self%view%error, RED)
      else
         associate(v => self%view, p => self%view%prof, k => self%view%prof_kin)
            call ig_push_item_width(ig_em(7))
            call ig_separator_text('Temperatures [T_e]')
            call readout('T_TS, w <= 2', v%t_ts(1), '%.5f')
            call ig_same_line(ig_em(18))
            call readout('T_TS, w <= 3', v%t_ts(2), '%.5f')
            call readout('T_kin', v%t_kin, '%.5f')
            call ig_same_line(ig_em(18))
            call readout('T_slope min, 1 <= u_L <= 4', v%t_slope(1), '%.5f')
            call readout('T_slope max, 1 <= u_L <= 4', v%t_slope(2), '%.5f')
            call ig_separator_text('Distortion, peak on u_L <= 4 [%]')
            call readout('df/f vs T_e', 100._R8P * v%peak_df(1), '%.4f')
            call ig_same_line(ig_em(18))
            call readout('df/f vs T_kin', 100._R8P * v%peak_df(2), '%.4f')
            call readout('df''/f'' vs T_e', 100._R8P * v%peak_ddf(1), '%.4f')
            call ig_same_line(ig_em(18))
            call readout('df''/f'' vs T_kin', 100._R8P * v%peak_ddf(2), '%.4f')
            call ig_pop_item_width()
            h = ig_em(16)
            if (ip_begin_plot('Relative distortion', height=h)) then
               call ip_setup_axes('u_L', 'relative change')
               call ip_setup_axes_limits(0._real64, 5._real64, -0.3_real64, 0.3_real64)
               call ip_setup_legend('ne')
               call ip_line('f0/f_M - 1, T_e', p(:, 2), p(:, 6))
               call ip_line('f0/f_M - 1, T_kin', k(:, 2), k(:, 6))
               call ip_line('f0''/f_M'' - 1, T_e', p(:, 2), p(:, 7))
               call ip_line('f0''/f_M'' - 1, T_kin', k(:, 2), k(:, 7))
               call ip_end_plot()
            endif
            if (ip_begin_plot('ECE: slope temperature', height=h)) then
               call ip_setup_axes('u_L', 'T_slope = -2 u f0 / f0'' [T_e]')
               call ip_setup_axes_limits(1._real64, 4._real64, 0.5_real64, 1.5_real64)
               call ip_setup_legend('ne')
               call ip_line('T_slope', p(:, 2), p(:, 8))
               call ip_inf_lines('T_TS, w <= 2', [v%t_ts(1)], horizontal=.true.)
               call ip_inf_lines('T_kin', [v%t_kin], horizontal=.true.)
               call ip_end_plot()
            endif
            if (ip_begin_plot('TS spectrum', height=h)) then
               call ip_setup_axes('w = Delta omega / (k v_Te)', 'S(w) / S(0)', yscale='log')
               call ip_setup_axes_limits(0._real64, 4._real64, 1.e-7_real64, 1.5_real64)
               call ip_setup_legend('ne')
               call ip_line('S, f0', p(:, 1), p(:, 10))
               call ip_line('S, Maxwellian T_e', p(:, 1), p(:, 9))
               call ip_line('Gaussian fit, w <= 2', p(:, 1), v%s_fit(:, 1))
               call ip_line('Gaussian fit, w <= 3', p(:, 1), v%s_fit(:, 2))
               call ip_end_plot()
            endif
         endassociate
      endif
   endif
   call ig_end()
   endsubroutine diagnostics_window

   subroutine transport_window(self)
   !< The solve (on a task): its readouts, the chosen quantity against omega tau, the f1 profiles.
   type(gui_object), intent(inout) :: self    !< The GUI.
   real(R8P)                        :: fraction !< Progress.
   character(len=:), allocatable    :: msg      !< Progress message.
   real(real64)                     :: h        !< Plot height [pixels].
   integer(int32)                   :: k        !< Counter.
   logical                          :: sel      !< A selection changed.
   integer(int32), parameter        :: CM(5) = [2_int32, 4_int32, 6_int32, 8_int32, 9_int32] !< Maxwellian column.
   integer(int32), parameter        :: CB(5) = [3_int32, 5_int32, 7_int32, 10_int32, 11_int32] !< f0 column.

   if (ig_begin(WINDOW_TRANSPORT)) then
      call ig_push_item_width(ig_em(7))
      if (ig_input('omega tau', self%inp%omega_tau, format='%.4g')) self%revision = self%revision + 1_int32
      call ig_pop_item_width()
      call ig_same_line()
      call ig_begin_disabled(self%solving .or. .not. self%view%valid)
      if (ig_button('Solve')) call self%start_solve()
      call ig_end_disabled()
      if (self%solving) then
         call ig_same_line()
         if (ig_button('Cancel')) call self%task%cancel()
         call self%task%progress(fraction, msg)
         call ig_progress_bar(max(0._R8P, fraction), msg)
      elseif (self%job%done == 0) then
         call ig_text_disabled('Solve: the readouts at omega tau = 0 and above, f1, and a sweep in omega tau (seconds).')
      elseif (self%stale()) then
         call ig_text_colored('[!] the inputs changed since this solve: Solve again', [0.95_real64, 0.75_real64, 0.30_real64])
      endif
      if (len(self%message) > 0 .and. index(self%message, 'solve') > 0) call ig_text_colored(self%message, RED)
      if (self%job%done > 0) then
         h = ig_em(16)
         if (ig_collapsing_header('Changes against the Maxwellians [%]', default_open=.true.)) then
            call ig_push_item_width(ig_em(7))
            do k = 1_int32, 12_int32
               call readout(trim(READOUT_LABELS(k)), 100._R8P * self%job%readouts(5 + k), '%+.4f')
               if (mod(k, 4_int32) /= 0_int32) call ig_same_line(ig_em(14) * real(mod(k, 4_int32), real64))
            enddo
            call ig_pop_item_width()
            call ig_text_disabled('signed at omega tau = 0; of the modulus at the omega tau above; last row: against the '// &
                                  'Maxwellian of the same energy (omega tau = 0)')
         endif
         call ig_separator_text('Against omega tau')
         call ig_push_item_width(ig_em(14))
         sel = ig_combo('quantity', self%quantity, QUANTITIES)
         call ig_pop_item_width()
         call ig_same_line()
         sel = ig_radio('perp', self%component, 1_int32) .or. sel
         call ig_same_line()
         sel = ig_radio('wedge', self%component, 2_int32) .or. sel
         if (sel) call self%select_curves()
         if (ip_begin_plot('Quantity against omega tau', height=h)) then
            call ip_setup_axes('omega tau', trim(QUANTITIES(self%quantity)), xscale='log')
            call ip_setup_legend('ne')
            call ip_line('f0', self%tx, self%ty(:, CURVE_F0))
            call ip_line('Maxwellian, T_e', self%tx, self%ty(:, CURVE_MAXWELLIAN))
            call ip_line('Maxwellian, T_kin', self%tx, self%ty(:, CURVE_EQUAL_ENERGY))
            call ip_end_plot()
         endif
         if (ip_begin_plot('Change of the modulus', height=h)) then
            call ip_setup_axes('omega tau', '|q_f0| / |q_M| - 1', xscale='log')
            call ip_setup_legend('ne')
            call ip_line('against T_kin', self%tx, self%tdy(:, 1))
            call ip_line('against T_e', self%tx, self%tdy(:, 2))
            call ip_end_plot()
         endif
         call ig_separator_text('f1 for a unit drive')
         call ig_push_item_width(ig_em(14))
         if (ig_combo('drive', self%drive, DRIVES)) continue
         call ig_pop_item_width()
         if (ip_begin_plot('f1 profile', height=h)) then
            call ip_setup_axes('u_L', 'f1')
            call ip_setup_legend('ne')
            associate(f => self%job%f1)
               call ip_line('f0', sqrt(2._R8P) * f(:, 1), f(:, CB(self%drive)))
               call ip_line('Maxwellian, T_e', sqrt(2._R8P) * f(:, 1), f(:, CM(self%drive)))
            endassociate
            call ip_end_plot()
         endif
      endif
   endif
   call ig_end()
   endsubroutine transport_window
endmodule appelbe_gui_app
