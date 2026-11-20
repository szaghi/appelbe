!< appelbe-gui --self-test: the packaged program checks itself, headless, without a display or a GPU.
module appelbe_gui_selftest
!< appelbe-gui --self-test: the packaged program checks itself, headless, without a display or a GPU.
!<
!< Run on a clean machine from the unpacked archive (CI's package smoke test, and a user who wonders), it shows that
!< the program starts with only what the package holds: its libraries resolve, every panel is drawn, a solve runs on
!< a worker thread and gives the library's readouts, a scan row runs, a plot is written as PNG (FIGURE's CPU
!< renderer). Each check prints a line; the result is false at the first failure.
use, intrinsic :: iso_fortran_env, only : int32, int64, output_unit
use penf,                          only : I4P, R8P
use figure,                        only : app_object, ig_focus_window
use appelbe,                       only : kinetic_operator, kinetic_response, electron_bipolar, electron_readouts, &
                                          n_readouts
use appelbe_gui_app,               only : gui_object, gui_version, WINDOW_INPUTS, WINDOW_F0, WINDOW_DIAGNOSTICS,  &
                                          WINDOW_TRANSPORT, WINDOW_SCANS
use appelbe_gui_model,             only : physical_params

implicit none
private
public :: self_test

contains
   function self_test(app, gui) result(ok)
   !< Drive the GUI headless (app%init_headless done by the caller) through every panel, a solve, a scan, a PNG.
   type(app_object), intent(inout) :: app   !< FIGURE's application, headless.
   type(gui_object), intent(inout) :: gui   !< The GUI, initialised.
   logical                          :: ok    !< Every check passed.
   character(len=*), parameter      :: windows(5) = [character(len=12) :: WINDOW_INPUTS, WINDOW_F0, WINDOW_DIAGNOSTICS, &
                                                     WINDOW_TRANSPORT, WINDOW_SCANS] !< The panels.
   character(len=*), parameter      :: png = 'appelbe-gui-self-test.png' !< Scratch picture.
   type(kinetic_operator)           :: ob, om !< Direct library calls.
   type(kinetic_response)           :: rm(2)  !< Their Maxwellian responses.
   real(R8P)                        :: o(n_readouts) !< Their readouts.
   integer                          :: k, unit, ios  !< Counters, unit, status.
   logical                          :: shown, exists !< A panel in front; the picture written.

   ok = .true.
   write(output_unit, '(A)') 'appelbe-gui '//gui_version//' self-test (headless)'
   gui%inp%n_nodes = 201_I4P                ! small: seconds, not minutes, for every check below
   gui%inp%scan_n(1) = 3_I4P
   call gui%inputs_changed()
   call report('the f0 of the default inputs', gui%view%valid)
   do k = 1, size(windows)
      call frames(10, windows(k), shown)
      call report('panel '//trim(windows(k))//' drawn', shown)
   enddo
   call gui%start_solve()
   call wait_tasks()
   call report('a solve on a worker thread', gui%job%done > 0 .and. gui%job%done == gui%job%steps())
   call ob%init(par=physical_params(gui%inp), n_nodes=201_I4P, electrons=electron_bipolar, &
                electron_params=gui%inp%bipolar)
   call om%init(par=physical_params(gui%inp), n_nodes=201_I4P)
   rm(1) = om%response(omega_tau=0._R8P) ; rm(2) = om%response(omega_tau=gui%inp%omega_tau)
   call electron_readouts(ob, rm, [0._R8P, gui%inp%omega_tau], o)
   call report('its readouts = the library''s', all(gui%job%readouts == o))
   call gui%start_scan()
   call wait_tasks()
   call report('a scan on a worker thread', gui%scan%done > 0 .and. gui%scan%finished() .and. .not. gui%scan%failed)
   call frames(10, WINDOW_F0, shown)
   gui%png_plot = 1_int32
   gui%png_path = png
   call frames(4, '', shown)
   inquire(file=png, exist=exists)
   call report('a plot written as PNG', exists)
   if (exists) then
      open(newunit=unit, file=png, status='old', iostat=ios)
      if (ios == 0) close(unit, status='delete')
   endif
   if (ok) then
      write(output_unit, '(A)') 'self-test: ok'
   else
      write(output_unit, '(A)') 'self-test: FAILED'
   endif

   contains
      subroutine report(label, pass)
      !< One check.
      character(*), intent(in) :: label !< What.
      logical,      intent(in) :: pass  !< Outcome.

      write(output_unit, '(A)') merge('  ok    ', '  FAIL  ', pass)//label
      ok = ok .and. pass
      endsubroutine report

      subroutine frames(n, window, focused)
      !< Draw n frames, bringing window (if any) to the front.
      integer,      intent(in)  :: n       !< Frames.
      character(*), intent(in)  :: window  !< Window ('' none).
      logical,      intent(out) :: focused !< Brought to the front.
      integer                   :: f       !< Frame.

      focused = len_trim(window) == 0
      do f = 1, n
         if (.not. app%next_frame()) exit
         call gui%frame(app)
         if (.not. focused) focused = ig_focus_window(trim(window))
      enddo
      endsubroutine frames

      subroutine wait_tasks()
      !< Draw frames while a task runs (at most 10 minutes).
      integer(int64) :: c0, c, rate !< Clock.

      call system_clock(c0, rate)
      do while (gui%solving .or. gui%scanning)
         if (.not. app%next_frame()) exit
         call gui%frame(app)
         call system_clock(c)
         if (c - c0 > 600_int64 * rate) exit
      enddo
      endsubroutine wait_tasks
   endfunction self_test
endmodule appelbe_gui_selftest
