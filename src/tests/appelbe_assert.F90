!< Minimal assertion helpers for the test programs.
module appelbe_assert
!< Minimal assertion helpers for the test programs.
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P

implicit none
private
public :: assert_close, assert_summary

integer(I4P) :: n_checks   = 0_I4P !< Checks performed.
integer(I4P) :: n_failures = 0_I4P !< Checks failed.

contains
   subroutine assert_close(label, value, expected, rel_tol, abs_tol)
   !< Check |value - expected| <= max(rel_tol |expected|, abs_tol) and print the outcome.
   character(*), intent(in)           :: label    !< What is checked.
   real(R8P),    intent(in)           :: value    !< Computed value.
   real(R8P),    intent(in)           :: expected !< Reference value.
   real(R8P),    intent(in)           :: rel_tol  !< Relative tolerance.
   real(R8P),    intent(in), optional :: abs_tol  !< Absolute tolerance floor.
   real(R8P)                          :: tol      !< Effective tolerance.
   logical                            :: ok       !< Outcome.

   tol = rel_tol * abs(expected)
   if (present(abs_tol)) tol = max(tol, abs_tol)
   ok = abs(value - expected) <= tol
   n_checks = n_checks + 1_I4P
   if (.not. ok) n_failures = n_failures + 1_I4P
   write(output_unit, '(A,1X,A,3(A,ES13.6))') merge('PASS', 'FAIL', ok), label, '  got ', value, '  expected ', expected, &
                                              '  tol ', tol
   endsubroutine assert_close

   subroutine assert_summary()
   !< Print the summary and stop with an error if any check failed.
   write(output_unit, '(I0,A,I0,A)') n_checks - n_failures, ' / ', n_checks, ' checks passed'
   if (n_failures > 0_I4P) error stop 'tests failed'
   endsubroutine assert_summary
endmodule appelbe_assert
