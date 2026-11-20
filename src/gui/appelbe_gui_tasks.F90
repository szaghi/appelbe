!< The GUI's work on FIGURE's worker threads (tasks): the solves of the transport panel, step by step.
module appelbe_gui_tasks
!< The GUI's work on FIGURE's worker threads (tasks): the solves of the transport panel, step by step.
!<
!< A task runs work(h, data) on another thread, on its own copy of data (FIGURE copies it at t%start): a solve_job of
!< appelbe_gui_model, whose steps are library calls. The work reports its progress after each step and returns at the
!< first step after a cancel; it never draws (FIGURE's threading rule) and touches no variable of the main thread.
!< The library and the model have no module variable and are built with -frecursive (docs/guide/gui.md, "Threads").
use, intrinsic :: iso_fortran_env, only : real64
use figure,                        only : task_handle_object
use appelbe_gui_model,             only : solve_job

implicit none
private
public :: solve_work

contains
   recursive subroutine solve_work(h, data)
   !< Run the steps of a solve_job, reporting the progress; stop at a cancel (the job keeps what was done).
   type(task_handle_object), intent(inout) :: h    !< The task's handle.
   class(*),                 intent(inout) :: data !< A solve_job.
   character(len=48)                       :: msg  !< Progress message.

   select type (data)
   type is (solve_job)
      do while (.not. data%finished())
         if (h%cancelled()) exit
         call data%step()
         write(msg, '(A,I0,A,I0)') 'solve ', data%done, ' of ', data%steps()
         call h%report(real(data%done, real64) / real(data%steps(), real64), trim(msg))
      enddo
   class default
      call h%fail('solve_work: the data is not a solve_job')
   endselect
   endsubroutine solve_work
endmodule appelbe_gui_tasks
