!< Output helpers for the reproduction drivers: plain ASCII tables under results/.
module appelbe_io
!< Output helpers for the reproduction drivers: plain ASCII tables under results/.
use penf, only : I4P

implicit none
private
public :: results_dir, open_results

character(len=*), parameter :: results_dir = 'results' !< Output directory, relative to the working directory.

contains
   function open_results(file_name, header) result(unit)
   !< Create results/ if needed, open results/<file_name> for writing and write the '#' header line.
   character(*), intent(in) :: file_name !< File name inside results/.
   character(*), intent(in) :: header    !< Column description (without the leading '#').
   integer(I4P)             :: unit      !< Opened unit.
   integer(I4P)             :: ierr      !< Status.
   character(len=256)       :: emsg      !< Message.

   call execute_command_line('mkdir -p '//results_dir, exitstat=ierr)
   if (ierr /= 0_I4P) error stop 'open_results: cannot create '//results_dir
   open(newunit=unit, file=results_dir//'/'//trim(file_name), status='replace', action='write', iostat=ierr, iomsg=emsg)
   if (ierr /= 0_I4P) error stop 'open_results: '//trim(emsg)
   write(unit, '(A)') '# '//header
   endfunction open_results
endmodule appelbe_io
