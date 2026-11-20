!< appelbe-gui: a desktop GUI over the appelbe library for non-Maxwellian electron f0 (issue #2).
program appelbe_gui
!< appelbe-gui: a desktop GUI over the appelbe library for non-Maxwellian electron f0 (issue #2).
!<
!< Usage: appelbe-gui [SESSION] [--remote PORT] [--self-test] [--screenshots DIR] [--version] [--help]
!<   (none)         a window (SDL3 + OpenGL 3)
!<   SESSION        a session file (File > Save session) to open at start
!<   --remote PORT  no window: the interface is served to a web browser on PORT (FIGURE's remote mode), for a machine
!<                  without a usable OpenGL; the address and its access token are printed
!<   --self-test    no window: check, headless, that the program runs (every panel, a solve, a scan, a PNG); exit
!<                  status 0 when every check passes (CI's smoke test of the packaged program)
!<   --screenshots DIR  no window: the user guide's pictures, DIR/<panel>.png (docs/public/gui)
!<   --version      print the version and exit
use, intrinsic :: iso_fortran_env, only : int32, output_unit, error_unit
use figure,                        only : app_object
use appelbe_gui_app,               only : gui_object, gui_version
use appelbe_gui_selftest,          only : self_test
use appelbe_gui_shots,             only : screenshots

implicit none
type(app_object)   :: app    !< FIGURE's application.
type(gui_object)   :: gui    !< The GUI.
character(len=4096) :: arg   !< A command argument.
character(len=4096) :: session !< A session to open at start ('' none).
integer(int32)     :: port   !< Remote mode's port.
integer(int32)     :: ios    !< Status.

session = ''
call get_command_argument(1, arg)
select case (trim(arg))
case ('--version')
   write(output_unit, '(A)') 'appelbe-gui '//gui_version
   stop
case ('--help', '-h')
   write(output_unit, '(A)') 'usage: appelbe-gui [SESSION] [--remote PORT] [--self-test] [--screenshots DIR] '// &
                             '[--version] [--help]'
   stop
case ('--self-test')
   call app%init_headless(1280_int32, 860_int32)
   call gui%init()
   if (.not. self_test(app, gui)) error stop 1
   call gui%destroy()
   call app%destroy()
   stop
case ('--screenshots')
   call get_command_argument(2, arg)
   if (len_trim(arg) == 0) then
      write(error_unit, '(A)') 'appelbe-gui: --screenshots needs a folder'
      error stop 2
   endif
   call app%init_headless(1180_int32, 760_int32)
   call gui%init()
   if (.not. screenshots(app, gui, trim(arg))) error stop 1
   call gui%destroy()
   call app%destroy()
   stop
case ('--remote')
   call get_command_argument(2, arg)
   read(arg, *, iostat=ios) port
   if (ios /= 0) then
      write(error_unit, '(A)') 'appelbe-gui: --remote needs a port number'
      error stop 2
   endif
   call app%init_remote(port=port, width=1280_int32, height=800_int32)
case default
   if (len_trim(arg) > 0) then
      if (arg(1:1) == '-') then
         write(error_unit, '(A)') 'appelbe-gui: unknown option '//trim(arg)//' (--help)'
         error stop 2
      endif
      session = arg
   endif
   call app%init('appelbe: non-Maxwellian electrons', 1280_int32, 800_int32)
endselect
call gui%init()
if (len_trim(session) > 0) call gui%open_session(trim(session))
do while (app%next_frame())
   call gui%frame(app)
   if (gui%quit) call app%quit()
enddo
call gui%destroy()
call app%destroy()
endprogram appelbe_gui
