!< GUI test, headless: the solves run as FIGURE tasks (worker threads) equal the same solves on the main thread.
program test_gui_task
!< GUI test, headless: the solves run as FIGURE tasks (worker threads) equal the same solves on the main thread.
!<
!< Phase 2 of issue #2: the library has no mutable module state (docs/guide/gui.md, "Threads"), so a solve on a worker
!< thread must give the result of the direct call bit for bit, even with two tasks and the main thread computing at
!< once. The reference is solve_job%step run to the end on the main thread, and, for the readouts and one response,
!< the library's own procedures called directly (electron_readouts, kinetic_operator%response).
use, intrinsic :: iso_fortran_env, only : int32, int64, real64
use penf,                          only : I4P, R8P
use figure,                        only : app_object, FIG_OK, task_object
use appelbe,                       only : kinetic_operator, kinetic_response, electron_bipolar, electron_readouts, &
                                          n_readouts
use appelbe_gui_model,             only : gui_inputs, solve_job, physical_params, CURVE_F0, N_CURVES
use appelbe_gui_tasks,             only : solve_work
use gui_assert,                    only : check, check_summary

implicit none
type(app_object)         :: app              !< Application, headless.
type(gui_inputs)         :: inp(2)           !< Two input sets.
type(solve_job)          :: ref(2), got(2)   !< References (main thread), results (tasks).
type(task_object)        :: t(2)             !< Tasks.
class(*), allocatable    :: data             !< A task's result.
type(kinetic_operator)   :: ob, om           !< Direct library calls.
type(kinetic_response)   :: rm(2), rb        !< Their responses.
real(R8P)                :: o(n_readouts)    !< Their readouts.
integer(int32)           :: stat, k          !< Status, counter.
integer(int64)           :: c0, c, rate      !< Clock.

call app%init_headless(800_int32, 600_int32)
inp(1)%n_nodes = 401_I4P                     ! the reference case on 401 nodes (bit identity does not depend on n)
inp(2)%n_nodes = 401_I4P
inp(2)%bipolar = [0.2_R8P, 1.5_R8P, 0.5_R8P]
inp(2)%omega_tau = 3._R8P

! two tasks at once, while the main thread computes the references
do k = 1, 2
   call got(k)%setup(inp(k))
   call t(k)%start(solve_work, got(k), stat=stat)
   call check('task started', stat == FIG_OK)
enddo
do k = 1, 2
   call ref(k)%setup(inp(k))
   do while (.not. ref(k)%finished())
      call ref(k)%step()
   enddo
   call check('main-thread reference finished without failure', .not. ref(k)%failed)
enddo
call system_clock(c0, rate)
do while ((.not. t(1)%done()) .or. (.not. t(2)%done()))
   if (.not. app%next_frame()) exit
   call system_clock(c)
   if (c - c0 > 600_int64 * rate) exit ! 10 minutes of wall time: the debug build is slow
enddo
do k = 1, 2
   call t(k)%result(data, stat=stat)
   call check('task result taken', stat == FIG_OK)
   select type (data)
   type is (solve_job)
      got(k) = data
   endselect
   call check('task finished every step', got(k)%done == got(k)%steps() .and. .not. got(k)%failed)
   call check('task = main thread: readouts bit for bit', all(got(k)%readouts == ref(k)%readouts))
   call check('task = main thread: f1 bit for bit', all(got(k)%f1 == ref(k)%f1))
   call check('task = main thread: responses bit for bit', same_responses(got(k), ref(k)))
enddo

! the references against the library called directly: readouts and the f0 response at the last Hall parameter
call ob%init(par=physical_params(inp(2)), n_nodes=401_I4P, electrons=electron_bipolar, electron_params=inp(2)%bipolar)
call om%init(par=physical_params(inp(2)), n_nodes=401_I4P)
rm(1) = om%response(omega_tau=0._R8P) ; rm(2) = om%response(omega_tau=3._R8P)
call electron_readouts(ob, rm, [0._R8P, 3._R8P], o)
call check('task = library: readouts bit for bit', all(got(2)%readouts == o))
rb = ob%response(omega_tau=got(2)%wt(size(got(2)%wt)))
k = size(got(2)%wt)
call check('task = library: the last response bit for bit', got(2)%r(k, CURVE_F0)%sigma == rb%sigma .and. &
           got(2)%r(k, CURVE_F0)%j_nu == rb%j_nu .and. got(2)%r(k, CURVE_F0)%zeta_nu == rb%zeta_nu)

! a cancel: the task stops at its next step, its data consistent
call got(1)%setup(inp(1))
call t(1)%start(solve_work, got(1), stat=stat)
call t(1)%cancel()
do while (.not. t(1)%done())
   if (.not. app%next_frame()) exit
enddo
call t(1)%result(data, stat=stat)
select type (data)
type is (solve_job)
   call check('a cancelled task stops before the end', stat == FIG_OK .and. data%done < data%steps())
endselect

! a rejected input inside a task: failed with the library's message, no stop
inp(1)%n_nodes = 400_I4P
call got(1)%setup(inp(1))
call t(1)%start(solve_work, got(1), stat=stat)
do while (.not. t(1)%done())
   if (.not. app%next_frame()) exit
enddo
call t(1)%result(data, stat=stat)
select type (data)
type is (solve_job)
   call check('a rejected input in a task: failed, with the message', data%failed .and. index(data%error, 'odd') > 0)
endselect

call app%destroy()
call check_summary()

contains
   pure function same_responses(a, b) result(same)
   !< Every response of every curve and Hall parameter equal bit for bit.
   type(solve_job), intent(in) :: a, b  !< Jobs.
   logical                     :: same  !< Equal.
   integer                     :: i, c  !< Counters.

   same = size(a%r, 1) == size(b%r, 1)
   if (.not. same) return
   do c = 1, N_CURVES
      do i = 1, size(a%r, 1)
         same = same .and. a%r(i, c)%sigma == b%r(i, c)%sigma .and. a%r(i, c)%mu == b%r(i, c)%mu .and.   &
                a%r(i, c)%tau == b%r(i, c)%tau .and. a%r(i, c)%thermal_diffusion == b%r(i, c)%thermal_diffusion .and. &
                a%r(i, c)%j_nu == b%r(i, c)%j_nu .and. a%r(i, c)%zeta_nu == b%r(i, c)%zeta_nu
      enddo
   enddo
   endfunction same_responses
endprogram test_gui_task
