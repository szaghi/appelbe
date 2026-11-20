!< GUI test, headless: the scans, the exports, the session file and a plot saved as PNG.
program test_gui_files
!< GUI test, headless: the scans, the exports, the session file and a plot saved as PNG.
!<
!< - Exports of the default inputs (the driver's reference case) are byte for byte the files appelbe_electrons writes:
!<   the oracle writes them here with the library, as the driver does (electron_profile, electron_f1, the scan loop with
!<   scan_value and electron_scan_row); when the driver's own results/electrons_*.dat exist (fobis rule --ex figures, or
!<   bin/appelbe_electrons, run from the root), the exports are compared with them too.
!< - The scans run as tasks from the Scans window (radio buttons, Run scan).
!< - A session saved and loaded gives the same inputs bit for bit (a tabulated f0 included), and so the same views; a
!<   file that is not a session changes nothing.
!< - A plot saved as PNG is written (FIGURE's CPU renderer in headless mode).
use, intrinsic :: iso_fortran_env, only : int32, int64, real64
use penf,                          only : I4P, R8P
use figure,                        only : app_object, ig_focus_window
use figure_testing,                only : test_item_click, test_run, test_item_type_text, test_id_conflicts, &
                                          test_unnamed_items
use appelbe,                       only : kinetic_params, kinetic_operator, kinetic_response, electron_bipolar,       &
                                          electron_profile, electron_f1, electron_scan_row, scan_value, write_table, &
                                          write_scan_row, profile_header, f1_header, scan_header, n_readouts, m_e,   &
                                          m_alpha, MeV_J, keV_J, speed_ratio
use appelbe_gui_app,               only : gui_object, WINDOW_INPUTS, WINDOW_SCANS, WINDOW_F0
use appelbe_gui_model,             only : gui_inputs
use gui_assert,                    only : check, check_summary

implicit none
type(app_object)            :: app        !< Application, headless.
type(gui_object)            :: gui        !< The GUI.
type(kinetic_params)        :: par        !< The driver's parameters.
type(kinetic_operator)      :: ob, om     !< The driver's operators.
type(kinetic_response)      :: rm(2)      !< The driver's Maxwellian responses.
type(gui_inputs)            :: saved      !< Inputs saved in a session.
real(R8P), allocatable      :: prof(:,:)  !< A profile.
integer(int32)              :: k          !< Counter.
logical                     :: exists     !< A file exists.
character(len=*), parameter :: tmp = 'test_gui_files.' !< Prefix of the scratch files (in the working directory).
real(R8P),    parameter     :: ref(3) = [0.1_R8P, 2._R8P, 0.25_R8P] !< The driver's reference case.
character(len=*), parameter :: names(3) = [character(len=2) :: 'A', 'u0', 'w'] !< The driver's scan files.
character(len=*), parameter :: radios(3) = [character(len=12) :: 'A##scan', 'u_0##scan', 'w##scan'] !< Their buttons.
real(R8P),    parameter     :: p_min(3) = [-0.3_R8P, 0.5_R8P, 0.1_R8P], p_max(3) = [0.3_R8P, 4._R8P, 1._R8P] !< Ranges.
integer(I4P), parameter     :: n_p(3) = [13_I4P, 15_I4P, 19_I4P] !< Values.

call app%init_headless(1280_int32, 860_int32)
call app%set_checks('abort')
call gui%init()
call run()

! the driver's set-up, by the library
par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%n_ratio = 1.e-3_R8P
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, 10._R8P * keV_J)
call om%init(par=par, n_nodes=801_I4P)
call ob%init(par=par, n_nodes=801_I4P, electrons=electron_bipolar, electron_params=ref)
rm(1) = om%response(omega_tau=0._R8P) ; rm(2) = om%response(omega_tau=1._R8P)

! the f0 profile
call gui%export(1_int32, tmp//'profile.dat')
call write_reference(tmp//'profile.ref', profile_header, electron_profile(ob, om))
call check('export: f0 profile = the driver''s, byte for byte', same_file(tmp//'profile.dat', tmp//'profile.ref'))
call compare_driver(tmp//'profile.dat', 'results/electrons_profile.dat')

! f1: Solve first (a task), then export
call gui%export(2_int32, tmp//'f1.dat')
call check('export before a solve: a message, no file', index(gui%message, 'Solve first') > 0)
call gui%start_solve()
call wait(1_int32)
call gui%export(2_int32, tmp//'f1.dat')
call write_reference(tmp//'f1.ref', f1_header, electron_f1(ob, om, [0._R8P, 1._R8P]))
call check('export: f1 = the driver''s, byte for byte', same_file(tmp//'f1.dat', tmp//'f1.ref'))
call compare_driver(tmp//'f1.dat', 'results/electrons_f1.dat')
call gui%export(3_int32, tmp//'readouts.dat')
call gui%export(4_int32, tmp//'sweep.dat')
call check('export: readouts and sweep written', line_count(tmp//'readouts.dat') == 2 .and. &
           line_count(tmp//'sweep.dat') == 1 + size(gui%job%wt))

! the three scans, from the Scans window
call show(WINDOW_SCANS)
call check('Scans: no id conflict', test_id_conflicts() == 0_int32)
call check('Scans: every item named', test_unnamed_items() == 0_int32)
do k = 1_int32, 3_int32
   call test_item_click(WINDOW_SCANS//'/'//trim(radios(k)))
   call run()
   call check('scan '//trim(names(k))//': the radio button selects it', gui%inp%scan_param == k)
   call test_item_click(WINDOW_SCANS//'/Run scan')
   call run()
   call wait(2_int32)
   call check('scan '//trim(names(k))//': finished', gui%scan%finished() .and. .not. gui%scan%failed)
   call gui%export(5_int32, tmp//'scan.dat')
   call write_scan_reference(tmp//'scan.ref', k)
   call check('scan '//trim(names(k))//' = the driver''s, byte for byte', same_file(tmp//'scan.dat', tmp//'scan.ref'))
   call compare_driver(tmp//'scan.dat', 'results/electrons_scan_'//trim(names(k))//'.dat')
enddo

! a session: inputs changed (a custom species and a table), saved, the defaults restored, loaded back
call gui%open_table('src/gui/share/f0_two_temperature.dat')
call test_item_type_text(WINDOW_INPUTS//'/T_e [keV]', '3.3')
call run()
gui%inp%species = 4_int32 ; gui%inp%z_a = 1._R8P / 3._R8P ; gui%inp%mass_amu = 2.0141_R8P ; gui%inp%e_mev = 0.1_R8P
gui%inp%scan_min(2) = 0.123456789012345678_R8P
call gui%inputs_changed()
saved = gui%inp
prof = gui%view%prof
call gui%write_session(tmp//'session.ses')
call check('session saved', index(gui%message, 'session saved') > 0)
gui%inp = gui_inputs()
call gui%inputs_changed()
call gui%open_session(tmp//'session.ses')
call check('session loaded', index(gui%message, 'session read') > 0)
call check('session: the same inputs, bit for bit', same_inputs(gui%inp, saved))
call check('session: the same f0 view, bit for bit', gui%view%valid .and. all(gui%view%prof == prof))
open(newunit=k, file=tmp//'bad.ses', status='replace')
write(k, '(A)') '# appelbe-gui session, version 0', 'te_kev = 10', 'no_such_key = 1'
close(k)
call gui%open_session(tmp//'bad.ses')
call check('a bad session: a message naming the line, the inputs kept', index(gui%message, 'line 3') > 0 .and. &
           same_inputs(gui%inp, saved))
call gui%open_session('src/gui/share/f0_two_temperature.dat')
call check('a file that is not a session: refused', index(gui%message, 'not an appelbe-gui session') > 0)

! a plot as PNG: the f0 plot, in front
call show(WINDOW_F0)
gui%png_plot = 1_int32
gui%png_path = tmp//'f0.png'
do k = 1_int32, 4_int32
   if (app%next_frame()) call gui%frame(app)
enddo
inquire(file=tmp//'f0.png', exist=exists)
call check('a plot saved as PNG', exists .and. index(gui%message, 'saved') > 0)

call cleanup()
call app%destroy()
call check_summary()

contains
   subroutine run()
   !< Draw frames until the interface is idle, then one more.
   do while (test_run(400_int32))
      if (.not. app%next_frame()) exit
      call gui%frame(app)
   enddo
   if (app%next_frame()) call gui%frame(app)
   endsubroutine run

   subroutine wait(which)
   !< Draw frames while the solve (1) or the scan (2) runs, at most 30 minutes of wall time.
   integer(int32), intent(in) :: which !< Task.
   integer(int64)             :: c0, c, rate !< Clock.

   call system_clock(c0, rate)
   do while ((which == 1 .and. gui%solving) .or. (which == 2 .and. gui%scanning))
      if (.not. app%next_frame()) exit
      call gui%frame(app)
      call system_clock(c)
      if (c - c0 > 1800_int64 * rate) exit
   enddo
   endsubroutine wait

   subroutine show(window)
   !< Bring a docked window's tab to the front.
   character(*), intent(in) :: window  !< Window.
   logical                  :: focused !< Done.
   integer                  :: f       !< Frame.

   focused = .false.
   do f = 1, 10
      if (.not. app%next_frame()) exit
      call gui%frame(app)
      if (.not. focused) focused = ig_focus_window(window)
   enddo
   call run()
   endsubroutine show

   subroutine write_reference(path, header, table)
   !< A table as the driver writes it (open_results' header line, write_table).
   character(*), intent(in) :: path, header !< File, header.
   real(R8P),    intent(in) :: table(:,:)   !< Table.
   integer(I4P)             :: unit         !< Unit.

   open(newunit=unit, file=path, status='replace', action='write')
   write(unit, '(A)') '# '//header
   call write_table(unit, table)
   close(unit)
   endsubroutine write_reference

   subroutine write_scan_reference(path, ip)
   !< The driver's scan loop (appelbe_electrons, subroutine scan), on the library directly.
   character(*),   intent(in) :: path  !< File.
   integer(int32), intent(in) :: ip    !< Parameter.
   real(R8P)                  :: p(3), o(n_readouts), max_dev !< Parameters, readouts, ECE-TS distance.
   integer(I4P)               :: i, unit, monotone !< Counter, unit, flag.
   type(kinetic_operator)     :: os    !< The row's operator.
   character(len=*), parameter :: labels(3) = [character(len=3) :: 'A', 'u_0', 'w'] !< The driver's labels.

   open(newunit=unit, file=path, status='replace', action='write')
   write(unit, '(A)') '# '//scan_header(trim(labels(ip)))
   do i = 1_I4P, n_p(ip)
      p = ref
      p(ip) = scan_value(p_min(ip), p_max(ip), n_p(ip), i)
      call os%init(par=par, n_nodes=801_I4P, electrons=electron_bipolar, electron_params=p)
      call electron_scan_row(os, rm, [0._R8P, 1._R8P], o, max_dev, monotone)
      call write_scan_row(unit, p(ip), o, max_dev, monotone)
   enddo
   close(unit)
   endsubroutine write_scan_reference

   subroutine compare_driver(path, driver)
   !< When the driver's own file exists, the export must equal it: byte for byte when both were built alike (the
   !< driver's -O2 run, this test's -O2 build), else to one unit of the last printed digit (-O0 against -O2 rounds the
   !< 7th digit differently). Otherwise say it was skipped.
   character(*), intent(in) :: path, driver !< Export, driver's file.
   logical                  :: there        !< The driver's file exists.

   inquire(file=driver, exist=there)
   if (.not. there) then
      write(*, '(A)') 'SKIP '//driver//' not found (run bin/appelbe_electrons from the root to compare)'
   elseif (same_file(path, driver)) then
      call check('export = '//driver//' (the driver''s run), byte for byte', .true.)
   else
      call check('export = '//driver//' (the driver''s run), to the last printed digit', same_numbers(path, driver))
   endif
   endsubroutine compare_driver

   function same_numbers(a, b) result(same)
   !< The same table, every number within two units of its 7th significant digit (ES15.6), the headers equal.
   character(*), intent(in) :: a, b      !< Files.
   logical                  :: same      !< Equal to the printed precision.
   integer                  :: ua, ub, ia, ib, row !< Units, statuses, row.
   character(len=1024)      :: la, lb    !< Lines.
   real(R8P)                :: xa(40), xb(40) !< Values of a row.
   integer                  :: n         !< Values per row.

   open(newunit=ua, file=a, status='old', action='read')
   open(newunit=ub, file=b, status='old', action='read')
   read(ua, '(A)') la ; read(ub, '(A)') lb
   same = la == lb
   row = 0
   do while (same)
      read(ua, '(A)', iostat=ia) la ; read(ub, '(A)', iostat=ib) lb
      if (ia /= 0 .or. ib /= 0) then
         same = ia /= 0 .and. ib /= 0 .and. row > 0 ; exit
      endif
      row = row + 1
      n = count_values(la)
      same = n == count_values(lb) .and. n <= size(xa)
      if (.not. same) exit
      read(la, *) xa(:n) ; read(lb, *) xb(:n)
      same = all(abs(xa(:n) - xb(:n)) <= 2.01e-6_R8P * abs(xa(:n)) + tiny(1._R8P))
   enddo
   close(ua) ; close(ub)
   endfunction same_numbers

   pure function count_values(line) result(n)
   !< Blank-separated fields of a line.
   character(*), intent(in) :: line !< Line.
   integer                  :: n    !< Fields.
   integer                  :: i    !< Counter.
   logical                  :: in   !< Inside a field.

   n = 0 ; in = .false.
   do i = 1, len_trim(line)
      if (line(i:i) /= ' ' .and. .not. in) n = n + 1
      in = line(i:i) /= ' '
   enddo
   endfunction count_values

   function file_text(path) result(text)
   !< A whole file.
   character(*), intent(in)      :: path !< File.
   character(len=:), allocatable :: text !< Content.
   integer                       :: unit, n, ios !< Unit, size, status.

   open(newunit=unit, file=path, access='stream', form='unformatted', action='read', status='old', iostat=ios)
   if (ios /= 0) then
      text = '' ; return
   endif
   inquire(unit=unit, size=n)
   allocate(character(len=n) :: text)
   if (n > 0) read(unit) text
   close(unit)
   endfunction file_text

   function same_file(a, b) result(same)
   !< Two files, byte for byte (and not empty).
   character(*), intent(in) :: a, b !< Files.
   logical                  :: same !< Equal.
   character(len=:), allocatable :: ta, tb !< Contents.

   ta = file_text(a) ; tb = file_text(b)
   same = len(ta) > 0 .and. ta == tb .and. len(ta) == len(tb)
   endfunction same_file

   function line_count(path) result(n)
   !< Lines of a text file.
   character(*), intent(in)      :: path !< File.
   integer                       :: n    !< Lines.
   character(len=:), allocatable :: t    !< Content.
   integer                       :: i    !< Counter.

   t = file_text(path)
   n = 0
   do i = 1, len(t)
      if (t(i:i) == new_line('a')) n = n + 1
   enddo
   endfunction line_count

   pure function same_inputs(a, b) result(same)
   !< Every input equal, bit for bit.
   type(gui_inputs), intent(in) :: a, b !< Inputs.
   logical                      :: same !< Equal.

   same = a%f0_kind == b%f0_kind .and. a%t_ratio == b%t_ratio .and. all(a%bipolar == b%bipolar) .and. &
          a%te_kev == b%te_kev .and. a%z_i == b%z_i .and. a%species == b%species .and. a%z_a == b%z_a .and. &
          a%mass_amu == b%mass_amu .and. a%e_mev == b%e_mev .and. a%n_ratio == b%n_ratio .and. &
          a%n_nodes == b%n_nodes .and. a%u_max == b%u_max .and. a%omega_tau == b%omega_tau .and. &
          a%scan_param == b%scan_param .and. all(a%scan_min == b%scan_min) .and. all(a%scan_max == b%scan_max) .and. &
          all(a%scan_n == b%scan_n) .and. trim(a%table_path) == trim(b%table_path) .and. &
          (allocated(a%table_x) .eqv. allocated(b%table_x))
   if (same .and. allocated(a%table_x)) same = size(a%table_x) == size(b%table_x) .and. &
                                              all(a%table_x == b%table_x) .and. all(a%table_f == b%table_f)
   endfunction same_inputs

   subroutine cleanup()
   !< Remove the scratch files.
   character(len=12), parameter :: files(10) = [character(len=12) :: 'profile.dat', 'profile.ref', 'f1.dat', &
      'f1.ref', 'readouts.dat', 'sweep.dat', 'scan.dat', 'scan.ref', 'session.ses', 'bad.ses']
   integer :: i, unit, ios !< Counter, unit, status.

   do i = 1, size(files)
      open(newunit=unit, file=tmp//trim(files(i)), status='old', iostat=ios)
      if (ios == 0) close(unit, status='delete')
   enddo
   open(newunit=unit, file=tmp//'f0.png', status='old', iostat=ios)
   if (ios == 0) close(unit, status='delete')
   endsubroutine cleanup
endprogram test_gui_files
