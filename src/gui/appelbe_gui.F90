!< appelbe-gui: a desktop GUI over the appelbe library for non-Maxwellian electron f0 (issue #2).
program appelbe_gui
!< appelbe-gui: a desktop GUI over the appelbe library for non-Maxwellian electron f0 (issue #2).
!<
!< Usage: appelbe-gui [--remote PORT] [--version] [--help]
!<   (none)         a window (SDL3 + OpenGL 3)
!<   --remote PORT  no window: the interface is served to a web browser on PORT (FIGURE's remote mode), for a machine
!<                  without a usable OpenGL; the address and its access token are printed
!<   --version      print the version and exit
use, intrinsic :: iso_fortran_env, only : int32, output_unit, error_unit
use figure,                        only : app_object
use appelbe_gui_app,               only : gui_object, gui_version

implicit none
type(app_object)   :: app    !< FIGURE's application.
type(gui_object)   :: gui    !< The GUI.
character(len=256) :: arg    !< A command argument.
integer(int32)     :: port   !< Remote mode's port.
integer(int32)     :: ios    !< Status.

call get_command_argument(1, arg)
select case (trim(arg))
case ('--version')
   write(output_unit, '(A)') 'appelbe-gui '//gui_version
   stop
case ('--help', '-h')
   write(output_unit, '(A)') 'usage: appelbe-gui [--remote PORT] [--version] [--help]'
   stop
case ('--remote')
   call get_command_argument(2, arg)
   read(arg, *, iostat=ios) port
   if (ios /= 0) then
      write(error_unit, '(A)') 'appelbe-gui: --remote needs a port number'
      error stop 2
   endif
   call app%init_remote(port=port, width=1280_int32, height=800_int32)
case ('')
   call app%init('appelbe: non-Maxwellian electrons', 1280_int32, 800_int32)
case default
   write(error_unit, '(A)') 'appelbe-gui: unknown argument '//trim(arg)//' (--help)'
   error stop 2
endselect
call gui%init()
do while (app%next_frame())
   call gui%frame(app)
   if (gui%quit) call app%quit()
enddo
call app%destroy()
endprogram appelbe_gui
