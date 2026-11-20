!< Minimal checks for the GUI tests: PASS/FAIL lines and a summary that stops with an error on a failure.
module gui_assert
!< Minimal checks for the GUI tests: PASS/FAIL lines and a summary that stops with an error on a failure.
use, intrinsic :: iso_fortran_env, only : int32, output_unit

implicit none
private
public :: check, check_summary

integer(int32) :: n_checks   = 0_int32 !< Checks performed (the test program's own: not used by the GUI, no thread).
integer(int32) :: n_failures = 0_int32 !< Checks failed.

contains
   subroutine check(label, ok)
   !< Print PASS or FAIL label.
   character(*), intent(in) :: label !< What is checked.
   logical,      intent(in) :: ok    !< Outcome.

   n_checks = n_checks + 1_int32
   if (.not. ok) n_failures = n_failures + 1_int32
   write(output_unit, '(A,1X,A)') merge('PASS', 'FAIL', ok), label
   endsubroutine check

   subroutine check_summary()
   !< Print the count; stop with an error if any check failed.
   write(output_unit, '(I0,A,I0,A)') n_checks - n_failures, ' / ', n_checks, ' checks passed'
   if (n_failures > 0_int32) error stop 'GUI tests failed'
   endsubroutine check_summary
endmodule gui_assert
