!< GUI test, headless: the f0 panel shows what the library computes, after inputs set through the widgets.
program test_gui_f0
!< GUI test, headless: the f0 panel shows what the library computes, after inputs set through the widgets.
!<
!< The oracle is a direct library call on the same inputs (kinetic_operator%init with electron_bipolar, the Maxwellian
!< of the same energy), never a snapshot of the GUI's own output: the arrays the plot reads must equal it bit for bit.
use, intrinsic :: iso_fortran_env, only : int32, real64
use penf,                          only : I4P, R8P
use figure,                        only : app_object
use figure_testing,                only : test_item_type_text, test_item_click, test_run, test_item_exists, &
                                          test_id_conflicts, test_unnamed_items
use appelbe,                       only : kinetic_params, kinetic_operator, electron_bipolar, electron_maxwellian, &
                                          kinetic_temperature, m_e, m_alpha, MeV_J, keV_J, speed_ratio
use appelbe_gui_app,               only : gui_object, WINDOW_INPUTS, WINDOW_F0
use gui_assert,                    only : check, check_summary

implicit none
type(app_object)       :: app   !< Application, headless.
type(gui_object)       :: gui   !< The GUI.
type(kinetic_params)   :: par   !< Oracle's parameters.
type(kinetic_operator) :: ob, ot !< Oracle's operators.

call app%init_headless(1280_int32, 800_int32)
call app%set_checks('abort')
call gui%init()
call run()
call check('the inputs and the f0 windows are drawn', test_item_exists(WINDOW_INPUTS) .and. test_item_exists(WINDOW_F0))
call check('the f0 plot is drawn', test_item_exists(WINDOW_F0//'/f0 and the Maxwellians'))
call check('no id conflict', test_id_conflicts() == 0_int32)
call check('every interactive item named', test_unnamed_items() == 0_int32)

! the driver's reference case by default
par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%n_ratio = 1.e-3_R8P
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, 10._R8P * keV_J)
call ob%init(par=par, n_nodes=801_I4P, electrons=electron_bipolar, electron_params=[0.1_R8P, 2._R8P, 0.25_R8P])
call check('default: the reference case, f0 bit for bit', gui%view%valid .and. all(gui%view%prof(:, 5) == ob%f0))

! A and w typed into their fields: the plot's f0 is the library's on those inputs
call test_item_type_text(WINDOW_INPUTS//'/A', '0.2')
call run()
call test_item_type_text(WINDOW_INPUTS//'/w', '0.5')
call run()
call ob%init(par=par, n_nodes=801_I4P, electrons=electron_bipolar, electron_params=[0.2_R8P, 2._R8P, 0.5_R8P])
call check('A = 0.2, w = 0.5 typed: f0 bit for bit', gui%view%valid .and. all(gui%view%prof(:, 5) == ob%f0))
call check('A = 0.2, w = 0.5 typed: u_L axis', all(gui%view%prof(:, 2) == sqrt(2._R8P) * ob%grid%u))
call ot%init(par=par, n_nodes=801_I4P, electrons=electron_maxwellian, electron_params=[kinetic_temperature(ob)])
call check('the equal-energy Maxwellian bit for bit', all(gui%view%prof_kin(:, 4) == ot%f0))

! T_e typed: u_a follows (speed_ratio), and so the grid's alignment
call test_item_type_text(WINDOW_INPUTS//'/T_e [keV]', '5')
call run()
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, 5._R8P * keV_J)
call ob%init(par=par, n_nodes=801_I4P, electrons=electron_bipolar, electron_params=[0.2_R8P, 2._R8P, 0.5_R8P])
call check('T_e = 5 keV typed: u_a and the grid', gui%view%u_a == par%u_a .and. all(gui%view%prof(:, 1) == ob%grid%u))

! an input the library rejects: a message, no stop
call test_item_type_text(WINDOW_INPUTS//'/A', '-3')
call run()
call check('A = -3 (negative f0): a message, the program runs', .not. gui%view%valid .and. index(gui%view%error, 'negative') > 0)
call test_item_type_text(WINDOW_INPUTS//'/nodes', '400')
call run()
call check('an even number of nodes: a message', .not. gui%view%valid)
call test_item_type_text(WINDOW_INPUTS//'/A', '0.2')
call run()
call test_item_type_text(WINDOW_INPUTS//'/nodes', '801')
call run()
call check('valid inputs again: the view is back', gui%view%valid .and. all(gui%view%prof(:, 5) == ob%f0))

! a table: the example shipped with the GUI
call gui%open_table('src/gui/share/f0_two_temperature.dat')
call run()
call check('the example table is read and selected', gui%view%valid .and. gui%inp%f0_kind == 3_int32)
call gui%open_table('no/such/table.dat')
call check('a missing table: a message, the table kept', index(gui%message, 'read_table') > 0 .and. gui%view%valid)

call app%destroy()
call check_summary()

contains
   subroutine run()
   !< Draw frames until the interface is idle.
   do while (test_run(200_int32))
      if (.not. app%next_frame()) exit
      call gui%frame(app)
   enddo
   if (app%next_frame()) call gui%frame(app) ! one more: the last input's effect drawn
   endsubroutine run
endprogram test_gui_f0
