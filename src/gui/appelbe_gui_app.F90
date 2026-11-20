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
                                          ip_setup_axes, ip_setup_axes_limits, ip_setup_legend, ig_item_rect,          &
                                          ig_separator, ip_scatter, markdown_view_object, ig_open_popup,               &
                                          ig_begin_popup_modal, ig_end_popup, ig_close_current_popup,                  &
                                          ig_text_link_url, ig_align_text_to_frame_padding, ig_tooltip, ig_available
use appelbe,                       only : n_readouts
use appelbe_gui_model,             only : gui_inputs, f0_view, solve_job, scan_job, F0_MAXWELLIAN, F0_BIPOLAR,       &
                                          F0_TABLE, F0_KINDS, SPECIES_CUSTOM, SPECIES_NAMES, CURVE_F0,                 &
                                          CURVE_MAXWELLIAN, CURVE_EQUAL_ENERGY, N_CURVES, SCAN_PARAMETERS,             &
                                          SCAN_COLUMNS, species_defaults, compute_f0_view, load_table
use appelbe_gui_tasks,             only : solve_work, scan_work
use appelbe_gui_export,            only : export_profile, export_f1, export_readouts, export_sweep, export_scan
use appelbe_gui_session,           only : save_session, load_session
use appelbe_gui_help,              only : help_text, HELP_SITE

implicit none
private
public :: gui_object, gui_version, TABLE_FILTERS
public :: WINDOW_INPUTS, WINDOW_F0, WINDOW_DIAGNOSTICS, WINDOW_TRANSPORT, WINDOW_SCANS, WINDOW_HELP
public :: EXPORTS, PLOT_TITLES, N_PLOTS, SESSION_FILTERS
public :: QUANTITIES, Q_SIGMA, Q_BETA, Q_KAPPA, Q_J_NU, Q_ZETA_NU, DRIVES, READOUT_LABELS

character(len=*), parameter :: gui_version        = '0.1.0'        !< Version of the GUI.
character(len=*), parameter :: WINDOW_INPUTS      = 'Inputs'       !< The inputs' window.
character(len=*), parameter :: WINDOW_F0          = 'Electron f0'  !< The f0 panel.
character(len=*), parameter :: WINDOW_DIAGNOSTICS = 'Diagnostics'  !< What TS and ECE read.
character(len=*), parameter :: WINDOW_TRANSPORT   = 'Transport'    !< Transport and the alpha closure.
character(len=*), parameter :: WINDOW_SCANS       = 'Scans'        !< One-parameter scans of the bipolar f0.
character(len=*), parameter :: WINDOW_HELP        = 'Help'         !< The user guide.
!> Types offered by the session dialogs.
character(len=*), parameter :: SESSION_FILTERS(2) = [character(len=32) :: 'Sessions|ses', 'All files|*']
!> What File > Export writes (the dialog ids are 'export:' and the index).
character(len=*), parameter :: EXPORTS(5) = [character(len=40) :: 'f0 profile (.dat)...', 'f1 profiles (.dat)...', &
                                             'readouts (.dat)...', 'omega tau sweep (.dat)...', 'scan (.dat)...']
!> Default file names of the exports.
character(len=*), parameter :: EXPORT_FILES(5) = [character(len=24) :: 'electrons_profile.dat', 'electrons_f1.dat', &
                                                  'electrons_readouts.dat', 'electrons_sweep.dat', 'electrons_scan.dat']
integer(int32), parameter :: N_PLOTS = 8_int32 !< Plots that File > Save a plot as PNG offers.
!> Their titles, as ip_begin_plot names them (P_* codes).
character(len=*), parameter :: PLOT_TITLES(N_PLOTS) = [character(len=32) :: 'f0 and the Maxwellians', &
   'Relative distortion', 'ECE: slope temperature', 'TS spectrum', 'Quantity against omega tau', &
   'Change of the modulus', 'f1 profile', 'Scan']
integer(int32), parameter :: P_F0 = 1_int32, P_DIST = 2_int32, P_SLOPE = 3_int32, P_TS = 4_int32, P_QTY = 5_int32, &
                             P_MOD = 6_int32, P_F1 = 7_int32, P_SCAN = 8_int32 !< Plot codes.
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
   type(task_object)             :: scan_task            !< The scan's task.
   logical                       :: scanning = .false.   !< The scan's task runs.
   type(scan_job)                :: scan                 !< The last complete scan (scan%done = 0: none yet).
   integer(int32)                :: scan_revision = -1_int32 !< The inputs' revision the scan was started on.
   integer(int32)                :: scan_show = 10_int32 !< Column of the scan plot (SCAN_COLUMNS).
   real(real64)                  :: rect(4, N_PLOTS) = 0._real64 !< Each plot's rectangle, as last drawn [pixels].
   integer(int32)                :: drawn(N_PLOTS) = -1_int32 !< The frame each plot was last drawn in.
   integer(int32)                :: frames = 0_int32     !< Frames declared.
   integer(int32)                :: png_plot = 0_int32   !< The plot to save as PNG (0: none asked).
   character(len=:), allocatable :: png_path             !< Its file, once chosen.
   character(len=:), allocatable :: message              !< The last message (a table loaded, a failure): '' for none.
   logical                       :: quit = .false.       !< File > Quit was picked.
   logical                       :: front = .false.      !< The f0 tab was brought to the front (once, at start).
   type(markdown_view_object)    :: help                 !< The user guide (Help window).
   character(len=:), allocatable :: link                 !< The last link clicked in the guide ('' none).
   logical                       :: show_help = .false.  !< Help > User guide was picked: bring the Help tab forward.
   logical                       :: about = .false.      !< Help > About was picked: open its box.
   contains
      procedure, pass(self) :: init        !< The views of the default inputs.
      procedure, pass(self) :: frame       !< Declare one frame: menus, dock space, windows.
      procedure, pass(self) :: open_table  !< Load a table file (as the dialog does).
      procedure, pass(self) :: start_solve !< Start the solve's task on the current inputs.
      procedure, pass(self) :: poll_solve  !< Take the solve's result once its task is done.
      procedure, pass(self) :: stale       !< The inputs changed since the shown solve.
      procedure, pass(self) :: inputs_changed !< Recompute the views after an input change.
      procedure, pass(self) :: select_curves  !< Fill tx, ty, tdy from the job for the chosen quantity, component.
      procedure, pass(self) :: start_scan  !< Start the scan's task on the current inputs.
      procedure, pass(self) :: poll_scan   !< Take the scan's result once its task is done.
      procedure, pass(self) :: open_session !< Load a session file.
      procedure, pass(self) :: write_session !< Save the inputs as a session file.
      procedure, pass(self) :: export      !< Write one of the EXPORTS.
      procedure, pass(self) :: destroy     !< Release what FIGURE holds for the GUI (before app%destroy).
endtype gui_object

contains
   subroutine init(self)
   !< Compute the views of the current inputs (the driver's reference case by default).
   class(gui_object), intent(inout) :: self !< The GUI.

   self%message = ''
   self%link = ''
   call compute_f0_view(self%inp, self%view)
   if (.not. self%help%is_initialized()) call self%help%init()
   call self%help%set_text(help_text())
   endsubroutine init

   subroutine destroy(self)
   !< Release the help's document (FIGURE's native state); call before app%destroy.
   class(gui_object), intent(inout) :: self !< The GUI.

   if (self%help%is_initialized()) call self%help%destroy()
   endsubroutine destroy

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

   subroutine open_session(self, path)
   !< Load a session: every input; a file that cannot be read changes nothing, with the reason.
   class(gui_object), intent(inout) :: self   !< The GUI.
   character(*),      intent(in)    :: path   !< File.
   integer(I4P)                     :: stat   !< Status.
   character(len=:), allocatable    :: errmsg !< Why not.

   call load_session(path, self%inp, stat, errmsg)
   if (stat /= 0_I4P) then
      self%message = errmsg
   else
      self%message = 'session read: '//trim(path)
      call self%inputs_changed()
   endif
   endsubroutine open_session

   subroutine write_session(self, path)
   !< Save the inputs as a session.
   class(gui_object), intent(inout) :: self   !< The GUI.
   character(*),      intent(in)    :: path   !< File.
   integer(I4P)                     :: stat   !< Status.
   character(len=:), allocatable    :: errmsg !< Why not.

   call save_session(self%inp, path, gui_version, stat, errmsg)
   if (stat /= 0_I4P) then
      self%message = errmsg
   else
      self%message = 'session saved: '//trim(path)
   endif
   endsubroutine write_session

   subroutine export(self, kind, path)
   !< Write EXPORTS(kind) to path: the f0 profile, f1, the readouts, the omega tau sweep, the scan.
   class(gui_object), intent(inout) :: self   !< The GUI.
   integer(int32),    intent(in)    :: kind   !< Which.
   character(*),      intent(in)    :: path   !< File.
   integer(I4P)                     :: stat   !< Status.
   character(len=:), allocatable    :: errmsg !< Why not.

   select case (kind)
   case (1)    ; call export_profile(path, self%view, stat, errmsg)
   case (2)    ; call export_f1(path, self%job, stat, errmsg)
   case (3)    ; call export_readouts(path, self%job, stat, errmsg)
   case (4)    ; call export_sweep(path, self%job, stat, errmsg)
   case default; call export_scan(path, self%scan, stat, errmsg)
   endselect
   if (stat /= 0_I4P) then
      self%message = errmsg
   else
      self%message = 'written: '//trim(path)
   endif
   endsubroutine export

   subroutine start_scan(self)
   !< Start the scan of inp%scan_param on a worker thread, on a copy of the current inputs.
   class(gui_object), intent(inout) :: self !< The GUI.
   type(scan_job)                   :: job  !< The job given to the task (copied by FIGURE).
   integer(int32)                   :: stat !< Status.

   if (self%scanning) return
   call job%setup(self%inp)
   call self%scan_task%start(scan_work, job, stat=stat)
   if (stat /= FIG_OK) then
      self%message = 'the scan could not start a thread'
      return
   endif
   self%scanning = .true.
   self%scan_revision = self%revision
   endsubroutine start_scan

   subroutine poll_scan(self)
   !< Once the scan's task is done, take its job (a cancelled one is dropped: the last complete scan stays shown).
   class(gui_object), intent(inout) :: self !< The GUI.
   class(*), allocatable            :: data !< The task's data.
   integer(int32)                   :: stat !< Status.

   if (.not. self%scanning) return
   if (.not. self%scan_task%done()) return
   self%scanning = .false.
   call self%scan_task%result(data, stat=stat)
   if (stat /= FIG_OK) then
      self%message = 'the scan failed'
      return
   endif
   select type (data)
   type is (scan_job)
      if (data%failed) then
         self%message = 'scan: '//data%error
      elseif (data%finished()) then
         self%scan = data
         self%message = ''
      else
         self%message = 'scan cancelled'
      endif
   endselect
   endsubroutine poll_scan

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

   self%frames = self%frames + 1_int32
   call self%poll_solve()
   call self%poll_scan()
   call menus(self, app)
   call dialogs(self, app)
   call layout()
   call inputs_window(self, app)
   call f0_window(self)
   call diagnostics_window(self)
   call transport_window(self)
   call scans_window(self)
   call help_window(self)
   call about_box(self)
   call save_png(self, app)
   ! the tab in front after the layout is Dear ImGui's choice: the f0 panel, once its window exists
   if (.not. self%front) self%front = ig_focus_window(WINDOW_F0)
   if (self%show_help) self%show_help = .not. ig_focus_window(WINDOW_HELP)
   endsubroutine frame

   ! private
   subroutine menus(self, app)
   !< The main menu bar: File (a table, sessions, exports, a plot as PNG, quit).
   type(gui_object), intent(inout) :: self !< The GUI.
   type(app_object), intent(inout) :: app  !< FIGURE's application.
   integer(int32)                   :: k    !< Counter.
   character(len=2)                 :: id   !< Dialog id suffix.

   if (ig_begin_main_menu_bar()) then
      if (ig_begin_menu('File')) then
         if (ig_menu_item('Open f0 table...')) call ask_open(app, 'table', TABLE_FILTERS)
         call ig_separator()
         if (ig_menu_item('Open session...')) call ask_open(app, 'session_open', SESSION_FILTERS)
         if (ig_menu_item('Save session...')) call ask_save(app, 'session_save', SESSION_FILTERS, 'appelbe.ses')
         call ig_separator()
         if (ig_begin_menu('Export')) then
            do k = 1_int32, size(EXPORTS, kind=int32)
               write(id, '(I0)') k
               if (ig_menu_item(trim(EXPORTS(k)))) &
                  call ask_save(app, 'export:'//trim(id), [character(len=32) :: 'Tables|dat', 'All files|*'], &
                                trim(EXPORT_FILES(k)))
            enddo
            call ig_end_menu()
         endif
         if (ig_begin_menu('Save a plot as PNG')) then
            do k = 1_int32, N_PLOTS
               if (ig_menu_item(trim(PLOT_TITLES(k)), enabled=self%drawn(k) >= self%frames - 1_int32)) then
                  self%png_plot = k
                  call ask_save(app, 'png', [character(len=32) :: 'PNG images|png'], 'plot.png')
               endif
            enddo
            call ig_end_menu()
         endif
         call ig_separator()
         if (ig_menu_item('Quit')) self%quit = .true.
         call ig_end_menu()
      endif
      if (ig_begin_menu('Help')) then
         if (ig_menu_item('User guide')) self%show_help = .true.
         if (ig_menu_item('About appelbe-gui')) self%about = .true.
         call ig_end_menu()
      endif
      call ig_end_main_menu_bar()
   endif
   endsubroutine menus

   subroutine dialogs(self, app)
   !< The answers of the file dialogs: a table, a session to read or to write, an export, a PNG.
   type(gui_object), intent(inout) :: self   !< The GUI.
   type(app_object), intent(inout) :: app    !< FIGURE's application.
   character(len=:), allocatable    :: chosen !< Path chosen.
   logical                          :: done, cancelled !< Answered, cancelled.
   integer(int32)                   :: stat, k !< Status, counter.
   character(len=2)                 :: id     !< Dialog id suffix.

   call app%file_dialog_result('table', chosen, done, cancelled, stat=stat)
   if (done .and. .not. cancelled .and. stat == FIG_OK) call self%open_table(chosen)
   call app%file_dialog_result('session_open', chosen, done, cancelled, stat=stat)
   if (done .and. .not. cancelled .and. stat == FIG_OK) call self%open_session(chosen)
   call app%file_dialog_result('session_save', chosen, done, cancelled, stat=stat)
   if (done .and. .not. cancelled .and. stat == FIG_OK) call self%write_session(chosen)
   do k = 1_int32, size(EXPORTS, kind=int32)
      write(id, '(I0)') k
      call app%file_dialog_result('export:'//trim(id), chosen, done, cancelled, stat=stat)
      if (done .and. .not. cancelled .and. stat == FIG_OK) call self%export(k, chosen)
   enddo
   call app%file_dialog_result('png', chosen, done, cancelled, stat=stat)
   if (done .and. .not. cancelled .and. stat == FIG_OK) self%png_path = chosen
   if (done .and. cancelled) self%png_plot = 0_int32
   endsubroutine dialogs

   subroutine save_png(self, app)
   !< At the end of the frame: the plot asked for, as drawn in this frame, to the PNG file chosen; the outcome later.
   type(gui_object), intent(inout) :: self    !< The GUI.
   type(app_object), intent(inout) :: app     !< FIGURE's application.
   character(len=:), allocatable    :: written !< File written.
   logical                          :: done    !< Outcome known.
   integer(int32)                   :: stat    !< Status.

   if (self%png_plot > 0_int32 .and. allocated(self%png_path)) then
      if (self%drawn(self%png_plot) == self%frames) then
         associate(r => self%rect(:, self%png_plot))
            call app%save_image(self%png_path, r(1), r(2), r(3), r(4), stat=stat)
         endassociate
         if (stat /= FIG_OK) self%message = 'the picture cannot be saved'
      else
         self%message = 'the plot "'//trim(PLOT_TITLES(self%png_plot))//'" is not shown: bring its tab to the front'
      endif
      self%png_plot = 0_int32
      deallocate(self%png_path)
   endif
   call app%image_result(written, done, stat=stat)
   if (done) then
      if (stat == FIG_OK) then
         self%message = 'saved '//written
      else
         self%message = 'the picture cannot be written: '//written
      endif
   endif
   endsubroutine save_png

   subroutine plotted(self, k)
   !< Record the rectangle of plot k, just drawn (call right after its ip_end_plot).
   type(gui_object), intent(inout) :: self !< The GUI.
   integer(int32),   intent(in)    :: k    !< Plot code (P_*).

   associate(r => self%rect(:, k))
      call ig_item_rect(r(1), r(2), r(3), r(4))
   endassociate
   self%drawn(k) = self%frames
   endsubroutine plotted

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
      call ig_dock_window(WINDOW_SCANS, right)
      call ig_dock_window(WINDOW_HELP, right)
      call ig_dock_layout_end(root)
   endif
   call ig_dock_space(root)
   endsubroutine layout

   subroutine ask_open(app, id, filters)
   !< The system's dialog to open a file, or FIGURE's browser where there is none (remote mode).
   type(app_object), intent(inout) :: app        !< FIGURE's application.
   character(*),     intent(in)    :: id         !< Dialog id.
   character(*),     intent(in)    :: filters(:) !< Types offered.
   integer(int32)                   :: stat       !< Status.

   call app%open_file_dialog(id, filters, stat=stat)
   if (stat /= FIG_OK) call app%open_file_browser(id, filters)
   endsubroutine ask_open

   subroutine ask_save(app, id, filters, default_path)
   !< The system's dialog to choose where to save, or FIGURE's browser where there is none (remote mode).
   type(app_object), intent(inout) :: app          !< FIGURE's application.
   character(*),     intent(in)    :: id           !< Dialog id.
   character(*),     intent(in)    :: filters(:)   !< Types offered.
   character(*),     intent(in)    :: default_path !< Suggested name.
   integer(int32)                   :: stat         !< Status.

   call app%save_file_dialog(id, filters, default_path=default_path, stat=stat)
   if (stat /= FIG_OK) call app%save_file_browser(id, filters, default_path=default_path)
   endsubroutine ask_save

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
   logical                          :: changed !< An input changed.
   integer(int32)                   :: species !< Species before the combo.
   character(len=64)                :: line    !< Text.

   changed = .false.
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
         if (ig_button('Open table...')) call ask_open(app, 'table', TABLE_FILTERS)
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
            call plotted(self, P_F0)
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
               call plotted(self, P_DIST)
            endif
            if (ip_begin_plot('ECE: slope temperature', height=h)) then
               call ip_setup_axes('u_L', 'T_slope = -2 u f0 / f0'' [T_e]')
               call ip_setup_axes_limits(1._real64, 4._real64, 0.5_real64, 1.5_real64)
               call ip_setup_legend('ne')
               call ip_line('T_slope', p(:, 2), p(:, 8))
               call ip_inf_lines('T_TS, w <= 2', [v%t_ts(1)], horizontal=.true.)
               call ip_inf_lines('T_kin', [v%t_kin], horizontal=.true.)
               call ip_end_plot()
               call plotted(self, P_SLOPE)
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
               call plotted(self, P_TS)
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
   real(real64)                     :: cw, ch   !< Column width, height available [pixels].
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
            ! four columns, each a quarter of the width: the field 6 em, its label in the rest
            call ig_available(cw, ch)
            cw = max(cw / 4._real64, ig_em(12))
            call ig_push_item_width(ig_em(6))
            do k = 1_int32, 12_int32
               call readout(trim(READOUT_LABELS(k)), 100._R8P * self%job%readouts(5 + k), '%+.4f')
               if (mod(k, 4_int32) /= 0_int32) call ig_same_line(cw * real(mod(k, 4_int32), real64))
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
            call plotted(self, P_QTY)
         endif
         if (ip_begin_plot('Change of the modulus', height=h)) then
            call ip_setup_axes('omega tau', '|q_f0| / |q_M| - 1', xscale='log')
            call ip_setup_legend('ne')
            call ip_line('against T_kin', self%tx, self%tdy(:, 1))
            call ip_line('against T_e', self%tx, self%tdy(:, 2))
            call ip_end_plot()
            call plotted(self, P_MOD)
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
            call plotted(self, P_F1)
         endif
      endif
   endif
   call ig_end()
   endsubroutine transport_window
   subroutine scans_window(self)
   !< One-parameter scans of the bipolar f0 around the values of Inputs, on a task, as appelbe_electrons does them.
   type(gui_object), intent(inout) :: self     !< The GUI.
   real(R8P)                        :: fraction !< Progress.
   character(len=:), allocatable    :: msg      !< Progress message.
   integer(int32)                   :: ip       !< Scanned parameter.
   real(R8P), allocatable           :: y(:)     !< Column shown.

   if (ig_begin(WINDOW_SCANS)) then
      call ig_text_wrapped('A scan varies one parameter of the bipolar f0 (A, u_0, w), the others at their values in '// &
                           'Inputs, and solves at every value: the readouts of Diagnostics and Transport, one row each.')
      ip = self%inp%scan_param
      call ig_push_item_width(ig_em(7))
      if (ig_radio('A##scan', self%inp%scan_param, 1_int32)) continue
      call ig_same_line()
      if (ig_radio('u_0##scan', self%inp%scan_param, 2_int32)) continue
      call ig_same_line()
      if (ig_radio('w##scan', self%inp%scan_param, 3_int32)) continue
      ip = self%inp%scan_param
      ! the words before their fields: "from [a] to [b], [n] values"
      call ig_align_text_to_frame_padding()
      call ig_text(trim(SCAN_PARAMETERS(ip))//' from')
      call ig_same_line()
      if (ig_input('##from', self%inp%scan_min(ip), format='%.4g')) continue
      call ig_tooltip('first value of the scan')
      call ig_same_line()
      call ig_text('to')
      call ig_same_line()
      if (ig_input('##to', self%inp%scan_max(ip), format='%.4g')) continue
      call ig_tooltip('last value of the scan')
      call ig_same_line()
      if (ig_input('values', self%inp%scan_n(ip), step=1_int32)) self%inp%scan_n(ip) = max(2_int32, self%inp%scan_n(ip))
      call ig_pop_item_width()
      call ig_begin_disabled(self%scanning)
      if (ig_button('Run scan')) call self%start_scan()
      call ig_end_disabled()
      if (self%scanning) then
         call ig_same_line()
         if (ig_button('Cancel##scan')) call self%scan_task%cancel()
         call self%scan_task%progress(fraction, msg)
         call ig_progress_bar(max(0._R8P, fraction), msg)
      elseif (self%scan%done > 0 .and. self%scan_revision /= self%revision) then
         call ig_text_colored('[!] the inputs changed since this scan: run it again', [0.95_real64, 0.75_real64, 0.30_real64])
      endif
      if (len(self%message) > 0 .and. index(self%message, 'scan') > 0) call ig_text_colored(self%message, RED)
      if (self%scan%done > 0) then
         call ig_push_item_width(ig_em(14))
         if (ig_combo('show', self%scan_show, SCAN_COLUMNS)) continue
         call ig_pop_item_width()
         y = self%scan%column(self%scan_show)
         if (ip_begin_plot('Scan', height=-1.0_real64)) then
            call ip_setup_axes(trim(SCAN_PARAMETERS(self%scan%inp%scan_param)), trim(SCAN_COLUMNS(self%scan_show)))
            call ip_line(trim(SCAN_COLUMNS(self%scan_show)), self%scan%p(:size(y)), y)
            call ip_scatter('##points', self%scan%p(:size(y)), y)
            call ip_end_plot()
            call plotted(self, P_SCAN)
         endif
      endif
   endif
   call ig_end()
   endsubroutine scans_window
   subroutine help_window(self)
   !< The user guide (docs/guide/gui-user.md, compiled in), with its contents and a search (ctrl+f); a link clicked is
   !< shown below, to open in the browser.
   type(gui_object), intent(inout) :: self !< The GUI.
   character(len=:), allocatable    :: url  !< A link clicked in this frame.

   if (ig_begin(WINDOW_HELP)) then
      if (self%help%draw('guide', url, height=-ig_em(2))) self%link = url
      if (len(self%link) > 0) then
         call ig_text_link_url(self%link, self%link)
      else
         call ig_text_link_url('This guide online', HELP_SITE)
      endif
   endif
   call ig_end()
   endsubroutine help_window

   subroutine about_box(self)
   !< Help > About: the version, the licence, the sources.
   type(gui_object), intent(inout) :: self !< The GUI.

   if (self%about) then
      call ig_open_popup('About appelbe-gui')
      self%about = .false.
   endif
   if (ig_begin_popup_modal('About appelbe-gui')) then
      call ig_text('appelbe-gui '//gui_version)
      call ig_text_wrapped('Non-Maxwellian electron f0, its diagnostics and the transport it implies, on the appelbe '// &
                           'library (Appelbe et al., Phys. Plasmas 26, 102704, 2019). F. Negro, L. Senni, S. Zaghi.')
      call ig_text_wrapped('Free software under the GNU GPL v3; built with FIGURE (MIT), Dear ImGui, ImPlot and SDL3: '// &
                           'their licences are in the licenses folder of the package.')
      call ig_text_link_url('https://github.com/szaghi/appelbe', 'https://github.com/szaghi/appelbe')
      if (ig_button('Close')) call ig_close_current_popup()
      call ig_end_popup()
   endif
   endsubroutine about_box
endmodule appelbe_gui_app
