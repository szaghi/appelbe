!< The GUI's interface: the windows and their widgets, declared every frame from the state (FIGURE, immediate mode).
module appelbe_gui_app
!< The GUI's interface: the windows and their widgets, declared every frame from the state (FIGURE, immediate mode).
!<
!< gui_object holds the inputs and the views the panels draw; gui%frame(app) declares one frame. The program
!< (appelbe_gui) and the headless tests (src/gui/tests) call the same procedure, so the tests drive the interface that
!< ships. The panels draw arrays computed by appelbe_gui_model (library calls) and never compute physics themselves.
use, intrinsic :: iso_fortran_env, only : int32, real64
use penf,                          only : I4P, R8P
use figure,                        only : app_object, FIG_OK, ig_begin, ig_begin_main_menu_bar, ig_begin_menu,        &
                                          ig_button, ig_combo, ig_dock_id, ig_dock_layout_begin, ig_dock_layout_end, &
                                          ig_dock_space, ig_dock_split, ig_dock_window, ig_end, ig_end_main_menu_bar, &
                                          ig_end_menu, ig_input, ig_menu_item, ig_separator_text, ig_text,            &
                                          ig_text_colored, ig_text_disabled, ig_text_wrapped, ig_push_item_width,     &
                                          ig_pop_item_width, ig_em, ip_begin_plot, ip_end_plot, ip_line,              &
                                          ip_setup_axes, ip_setup_axes_limits, ip_setup_legend
use appelbe_gui_model,             only : gui_inputs, f0_view, F0_MAXWELLIAN, F0_BIPOLAR, F0_TABLE, F0_KINDS,         &
                                          SPECIES_CUSTOM, SPECIES_NAMES, species_defaults, compute_f0_view, load_table

implicit none
private
public :: gui_object, gui_version, WINDOW_INPUTS, WINDOW_F0, TABLE_FILTERS

character(len=*), parameter :: gui_version   = '0.1.0'          !< Version of the GUI.
character(len=*), parameter :: WINDOW_INPUTS = 'Inputs'         !< The inputs' window.
character(len=*), parameter :: WINDOW_F0     = 'Electron f0'    !< The f0 panel.
!> Types offered by the table dialog.
character(len=*), parameter :: TABLE_FILTERS(2) = [character(len=32) :: 'Tables|dat;txt;csv;tab', 'All files|*']

type :: gui_object
   !< The GUI's state: inputs, the views computed from them, the last message.
   type(gui_inputs)              :: inp            !< What the user set.
   type(f0_view)                 :: view           !< The f0 panel's content, recomputed on every input change.
   character(len=:), allocatable :: message        !< The last message (a table loaded, a failure): '' for none.
   logical                       :: quit = .false. !< File > Quit was picked.
   contains
      procedure, pass(self) :: init      !< The views of the default inputs.
      procedure, pass(self) :: frame     !< Declare one frame: menus, dock space, windows.
      procedure, pass(self) :: open_table !< Load a table file (as the dialog does).
endtype gui_object

contains
   subroutine init(self)
   !< Compute the views of the current inputs (the driver's reference case by default).
   class(gui_object), intent(inout) :: self !< The GUI.

   self%message = ''
   call compute_f0_view(self%inp, self%view)
   endsubroutine init

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
      call compute_f0_view(self%inp, self%view)
   endif
   endsubroutine open_table

   subroutine frame(self, app)
   !< One frame of the interface (after app%next_frame()).
   class(gui_object), intent(inout) :: self !< The GUI.
   type(app_object),  intent(inout) :: app  !< FIGURE's application.

   call menus(self, app)
   call layout()
   call inputs_window(self, app)
   call f0_window(self)
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
      if (changed) call compute_f0_view(self%inp, self%view)
      if (.not. self%view%valid) call ig_text_colored('[!!] '//self%view%error, [0.90_real64, 0.35_real64, 0.30_real64])
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
         call ig_text_colored('[!!] '//self%view%error, [0.90_real64, 0.35_real64, 0.30_real64])
      endif
   endif
   call ig_end()
   endsubroutine f0_window
endmodule appelbe_gui_app
