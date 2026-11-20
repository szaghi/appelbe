!< appelbe-gui --screenshots DIR: the pictures of the user guide, recorded from the program itself, headless.
module appelbe_gui_shots
!< appelbe-gui --screenshots DIR: the pictures of the user guide, recorded from the program itself, headless.
!<
!< The default inputs (the driver's reference case, 801 nodes), a solve and a scan of w, then each panel in front,
!< captured by FIGURE's CPU renderer (test_capture: the same pixels on every machine) into DIR/<panel>.png. The guide
!< (docs/guide/gui-user.md) shows them from docs/public/gui/: regenerate them there after a change of the interface.
use, intrinsic :: iso_fortran_env, only : int32, int64, output_unit
use figure,                        only : app_object, ig_focus_window
use figure_testing,                only : test_capture
use appelbe_gui_app,               only : gui_object, WINDOW_F0, WINDOW_DIAGNOSTICS, WINDOW_TRANSPORT, WINDOW_SCANS, &
                                          WINDOW_HELP

implicit none
private
public :: screenshots

contains
   function screenshots(app, gui, dir) result(ok)
   !< Write DIR/f0.png, diagnostics.png, transport.png, scans.png, help.png.
   type(app_object), intent(inout) :: app  !< FIGURE's application, headless.
   type(gui_object), intent(inout) :: gui  !< The GUI, initialised.
   character(*),     intent(in)    :: dir  !< Folder (it must exist).
   logical                          :: ok   !< Every picture asked for.
   character(len=*), parameter      :: windows(5) = [character(len=12) :: WINDOW_F0, WINDOW_DIAGNOSTICS, &
                                                     WINDOW_TRANSPORT, WINDOW_SCANS, WINDOW_HELP] !< The panels.
   character(len=*), parameter      :: files(5) = [character(len=16) :: 'f0', 'diagnostics', 'transport', 'scans', &
                                                   'help'] !< Their pictures.
   integer                          :: k, f !< Counters.
   logical                          :: shown !< In front.

   ok = .true.
   gui%inp%scan_param = 3_int32               ! the scan of w, as in the driver's figure
   call gui%start_solve()
   call wait_tasks()
   call gui%start_scan()
   call wait_tasks()
   gui%scan_show = 17_int32                   ! d kappa vs T_kin: the shape effect the guide talks about
   do k = 1, size(windows)
      shown = .false.
      do f = 1, 12
         if (.not. app%next_frame()) exit
         call gui%frame(app)
         if (.not. shown) shown = ig_focus_window(trim(windows(k)))
         if (f == 11) call test_capture(dir//'/'//trim(files(k))//'.png')
      enddo
      ok = ok .and. shown
      write(output_unit, '(A)') merge('written ', 'FAILED  ', shown)//dir//'/'//trim(files(k))//'.png'
   enddo
   if (app%next_frame()) call gui%frame(app) ! the last capture is written when its frame is rendered

   contains
      subroutine wait_tasks()
      !< Draw frames while a task runs (at most 30 minutes).
      integer(int64) :: c0, c, rate !< Clock.

      call system_clock(c0, rate)
      do while (gui%solving .or. gui%scanning)
         if (.not. app%next_frame()) exit
         call gui%frame(app)
         call system_clock(c)
         if (c - c0 > 1800_int64 * rate) exit
      enddo
      endsubroutine wait_tasks
   endfunction screenshots
endmodule appelbe_gui_shots
