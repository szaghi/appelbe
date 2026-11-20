!< GUI test, headless: the Diagnostics and Transport panels show what the library computes, read as the user sees it.
program test_gui_panels
!< GUI test, headless: the Diagnostics and Transport panels show what the library computes, read as the user sees it.
!<
!< Inputs are set through the widgets; the numbers are read from the read-only fields by path (test_item_value, the text
!< drawn) and compared with direct library calls on the same inputs, to the precision of the field's format; the
!< arrays the plots read are compared bit for bit. The oracles are never the GUI's own output.
use, intrinsic :: iso_fortran_env, only : int32, int64, real64
use penf,                          only : I4P, R8P
use figure,                        only : app_object, ig_focus_window
use figure_testing,                only : test_item_type_text, test_item_click, test_run, test_item_value, &
                                          test_id_conflicts, test_unnamed_items
use appelbe,                       only : kinetic_params, kinetic_operator, kinetic_response, electron_bipolar,     &
                                          electron_maxwellian, kinetic_temperature, ts_temperature, ts_fit,        &
                                          slope_temperature, electron_profile, electron_readouts, electron_f1,    &
                                          n_readouts, m_e, m_alpha, MeV_J, keV_J, speed_ratio
use appelbe_gui_app,               only : gui_object, WINDOW_INPUTS, WINDOW_DIAGNOSTICS, WINDOW_TRANSPORT, READOUT_LABELS
use appelbe_gui_model,             only : CURVE_F0, CURVE_MAXWELLIAN, CURVE_EQUAL_ENERGY
use gui_assert,                    only : check, check_summary

implicit none
type(app_object)       :: app            !< Application, headless.
type(gui_object)       :: gui            !< The GUI.
type(kinetic_params)   :: par            !< Oracle's parameters.
type(kinetic_operator) :: ob, om, ot     !< Oracle's operators: f0, Maxwellian at T_e, at T_kin.
type(kinetic_response) :: rm(2), r, rt, rw !< Oracle's responses.
real(R8P)              :: o(n_readouts)  !< Oracle's readouts.
real(R8P)              :: tf, cf         !< Oracle's TS fit.
real(R8P), allocatable :: t(:), prof(:,:), f1(:,:) !< Oracle's slope temperature, profile, f1.
logical, allocatable   :: win(:)         !< ECE window.
integer(int32)         :: k              !< Counter.
real(R8P), parameter   :: bip(3) = [0.15_R8P, 2.5_R8P, 0.4_R8P] !< The f0 set through the widgets.

call app%init_headless(1280_int32, 900_int32)
call app%set_checks('abort')
call gui%init()
call run()
call type_into(WINDOW_INPUTS//'/nodes', '401')
call type_into(WINDOW_INPUTS//'/A', '0.15')
call type_into(WINDOW_INPUTS//'/u_0', '2.5')
call type_into(WINDOW_INPUTS//'/w', '0.4')
call type_into(WINDOW_INPUTS//'/T_e [keV]', '8')

! the oracle: the same inputs, through the library directly
par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%n_ratio = 1.e-3_R8P
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, 8._R8P * keV_J)
call ob%init(par=par, n_nodes=401_I4P, electrons=electron_bipolar, electron_params=bip)
call om%init(par=par, n_nodes=401_I4P)
call ot%init(par=par, n_nodes=401_I4P, electrons=electron_maxwellian, electron_params=[kinetic_temperature(ob)])
call check('the inputs typed reach the model', all(gui%view%prof(:, 5) == ob%f0))

! Diagnostics
call show(WINDOW_DIAGNOSTICS)
call check('Diagnostics: no id conflict', test_id_conflicts() == 0_int32)
call check('Diagnostics: every item named', test_unnamed_items() == 0_int32)
call check_shown(WINDOW_DIAGNOSTICS//'/T_TS, w <= 2', ts_temperature(ob, 2._R8P), 0.5e-5_R8P)
call check_shown(WINDOW_DIAGNOSTICS//'/T_TS, w <= 3', ts_temperature(ob, 3._R8P), 0.5e-5_R8P)
call check_shown(WINDOW_DIAGNOSTICS//'/T_kin', kinetic_temperature(ob), 0.5e-5_R8P)
t = slope_temperature(ob)
win = sqrt(2._R8P) * ob%grid%u >= 1._R8P .and. sqrt(2._R8P) * ob%grid%u <= 4._R8P
call check_shown(WINDOW_DIAGNOSTICS//'/T_slope min, 1 <= u_L <= 4', minval(t, mask=win), 0.5e-5_R8P)
call check_shown(WINDOW_DIAGNOSTICS//'/T_slope max, 1 <= u_L <= 4', maxval(t, mask=win), 0.5e-5_R8P)
win = sqrt(2._R8P) * ob%grid%u <= 4._R8P
call check_shown(WINDOW_DIAGNOSTICS//'/df\/f vs T_e', 100._R8P * maxval(abs(ob%f0 / om%f0 - 1._R8P), mask=win), 0.5e-4_R8P)
call check_shown(WINDOW_DIAGNOSTICS//'/df\/f vs T_kin', 100._R8P * maxval(abs(ob%f0 / ot%f0 - 1._R8P), mask=win), &
                 0.5e-4_R8P)
win(1) = .false.
call check_shown(WINDOW_DIAGNOSTICS//'/df''\/f'' vs T_e', 100._R8P * maxval(abs(ob%df0 / om%df0 - 1._R8P), mask=win), &
                 0.5e-4_R8P)
call check_shown(WINDOW_DIAGNOSTICS//'/df''\/f'' vs T_kin', 100._R8P * maxval(abs(ob%df0 / ot%df0 - 1._R8P), mask=win), &
                 0.5e-4_R8P)
prof = electron_profile(ob, ot)
call check('Diagnostics: the distortion against T_kin, bit for bit', all(gui%view%prof_kin == prof))
call ts_fit(ob, 3._R8P, tf, cf)
call check('Diagnostics: the TS fit (w <= 3): T and c of ts_fit, bit for bit', &
           gui%view%t_ts(2) == tf .and. gui%view%c_ts(2) == cf)
! the curve exp(c - w^2/T): to rounding (two evaluations of exp may differ in the last bit)
call check('Diagnostics: the TS fit curve (w <= 3) = exp(c - w^2/T)', &
           all(abs(gui%view%s_fit(:, 2) - exp(cf - ob%grid%u**2 / tf)) <= 1.e-14_R8P * exp(cf - ob%grid%u**2 / tf)))
call check('Diagnostics: the slope temperature plotted', all(gui%view%prof(:, 8) == slope_temperature(ob)))

! Transport: Solve clicked, the task's result shown
call show(WINDOW_TRANSPORT)
call type_into(WINDOW_TRANSPORT//'/omega tau', '2')
call test_item_click(WINDOW_TRANSPORT//'/Solve')
call run()
call check('Transport: Solve starts the task', gui%solving)
call wait_solve()
call run()
call check('Transport: the solve finished', .not. gui%solving .and. gui%job%done == gui%job%steps())
call check('Transport: not stale', .not. gui%stale())
call check('Transport: no id conflict', test_id_conflicts() == 0_int32)
call check('Transport: every item named', test_unnamed_items() == 0_int32)
rm(1) = om%response(omega_tau=0._R8P) ; rm(2) = om%response(omega_tau=2._R8P)
call electron_readouts(ob, rm, [0._R8P, 2._R8P], o)
do k = 1_int32, 12_int32
   call check_shown(WINDOW_TRANSPORT//'/'//escape(trim(READOUT_LABELS(k))), 100._R8P * o(5 + k), 0.5e-4_R8P)
enddo
f1 = electron_f1(ob, om, [0._R8P, 2._R8P])
call check('Transport: f1 profiles, bit for bit', all(gui%job%f1 == f1))

! the plotted sweep: j_nu perp by default; kappa wedge chosen through the combo and the radio button
k = 5
r  = ob%response(omega_tau=gui%tx(k))
rt = ot%response(omega_tau=gui%tx(k))
rw = om%response(omega_tau=gui%tx(k))
call check('Transport: j_nu perp plotted (f0)', gui%ty(k, CURVE_F0) == real(r%j_nu, R8P))
call check('Transport: |j_nu| change against T_kin plotted', gui%tdy(k, 1) == abs(r%j_nu) / abs(rt%j_nu) - 1._R8P)
call test_item_click(WINDOW_TRANSPORT//'/quantity')
call run()
call test_item_click(WINDOW_TRANSPORT//'/quantity/kappa (thermal conductivity)')
call run()
call test_item_click(WINDOW_TRANSPORT//'/wedge')
call run()
call check('Transport: kappa wedge plotted (f0)', gui%ty(k, CURVE_F0) == aimag(r%kappa()))
call check('Transport: kappa wedge plotted (Maxwellian T_e)', &
           gui%ty(k, CURVE_MAXWELLIAN) == aimag(rw%kappa()))
call check('Transport: kappa wedge plotted (Maxwellian T_kin)', &
           gui%ty(k, CURVE_EQUAL_ENERGY) == aimag(rt%kappa()))

! an input changed: the solve is marked stale, the f0 panels follow at once
call type_into(WINDOW_INPUTS//'/A', '0.05')
call check('an input changed: the solve is stale', gui%stale())

! Solve, then Cancel: the last complete solve stays
call show(WINDOW_TRANSPORT)
call test_item_click(WINDOW_TRANSPORT//'/Solve')
call run()
call test_item_click(WINDOW_TRANSPORT//'/Cancel')
call wait_solve()
call check('Cancel: the task stops, the last solve kept', (.not. gui%solving) .and. all(gui%job%f1 == f1) .and. &
           (gui%message == 'solve cancelled' .or. gui%job_revision == gui%revision))

call app%destroy()
call check_summary()

contains
   subroutine wait_solve()
   !< Draw frames while the solve's task runs (at most 10 minutes of wall time: the debug build is slow).
   integer(int64) :: c0, c, rate !< Clock.

   call system_clock(c0, rate)
   do while (gui%solving)
      if (.not. app%next_frame()) exit
      call gui%frame(app)
      call system_clock(c)
      if (c - c0 > 600_int64 * rate) exit
   enddo
   endsubroutine wait_solve

   subroutine run()
   !< Draw frames until the interface is idle, then one more.
   do while (test_run(400_int32))
      if (.not. app%next_frame()) exit
      call gui%frame(app)
   enddo
   if (app%next_frame()) call gui%frame(app)
   endsubroutine run

   subroutine type_into(path, text)
   !< Type a value into a field and draw until idle.
   character(*), intent(in) :: path, text !< Field, value.

   call test_item_type_text(path, text)
   call run()
   endsubroutine type_into

   subroutine show(window)
   !< Bring a docked window's tab to the front, then draw until idle.
   character(*), intent(in) :: window !< Window.
   logical                  :: focused !< Done.
   integer                  :: f       !< Frame.

   focused = .false.
   do f = 1, 10
      if (.not. app%next_frame()) exit
      call gui%frame(app)
      if (.not. focused) focused = ig_focus_window(window)
   enddo
   call check('the window '//window//' brought to the front', focused)
   call run()
   endsubroutine show

   subroutine check_shown(path, expected, tol)
   !< The number a read-only field shows equals expected to tol (its format's half unit).
   character(*), intent(in)      :: path     !< Field.
   real(R8P),    intent(in)      :: expected !< Oracle.
   real(R8P),    intent(in)      :: tol      !< Tolerance.
   character(len=:), allocatable :: shown    !< Text drawn.
   real(R8P)                     :: x        !< Its value.
   integer                       :: ios      !< Status.
   character(len=32)             :: e        !< Expected, as text.

   if (test_item_value(path, '', shown)) continue
   read(shown, *, iostat=ios) x
   write(e, '(ES14.6)') expected
   call check('shown '//path//' = '//shown//' (library: '//trim(adjustl(e))//')', &
              ios == 0 .and. abs(x - expected) <= tol * (1._R8P + 1.e-9_R8P))
   endsubroutine check_shown

   pure function escape(label) result(path)
   !< A label as a path segment: '/' written '\/'.
   character(*), intent(in)      :: label !< Label.
   character(len=:), allocatable :: path  !< Segment.
   integer                       :: i     !< Counter.

   path = ''
   do i = 1, len(label)
      if (label(i:i) == '/') then
         path = path//'\/'
      else
         path = path//label(i:i)
      endif
   enddo
   endfunction escape
endprogram test_gui_panels
