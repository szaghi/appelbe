!< I/O helpers: plain ASCII tables under results/ for the drivers, and a reader of two-column tables (tabulated f0).
module appelbe_io
!< I/O helpers: plain ASCII tables under results/ for the drivers, and a reader of two-column tables (tabulated f0).
use penf, only : I4P, R8P

implicit none
private
public :: results_dir, open_results, read_table

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

   subroutine read_table(file_name, x, y)
   !< Read the first two columns of a plain table (lines starting with '#' and blank lines skipped), e.g. u_L and f0.
   character(*),           intent(in)  :: file_name !< Path of the table.
   real(R8P), allocatable, intent(out) :: x(:), y(:) !< First and second column.
   real(R8P)                           :: a, b      !< Values of one line.
   integer(I4P)                        :: unit, ierr, pass !< Unit, status, pass (1 counts, 2 reads).
   integer(I4P)                        :: n         !< Rows.
   character(len=1024)                 :: line      !< One line.
   character(len=256)                  :: emsg      !< Message.

   open(newunit=unit, file=file_name, status='old', action='read', iostat=ierr, iomsg=emsg)
   if (ierr /= 0_I4P) error stop 'read_table: '//trim(emsg)
   do pass = 1_I4P, 2_I4P
      n = 0_I4P
      rewind(unit)
      do
         read(unit, '(A)', iostat=ierr) line
         if (ierr /= 0_I4P) exit
         line = adjustl(line)
         if (len_trim(line) == 0 .or. line(1:1) == '#') cycle
         read(line, *, iostat=ierr) a, b
         if (ierr /= 0_I4P) error stop 'read_table: cannot read two numbers from '//trim(file_name)
         n = n + 1_I4P
         if (pass == 2_I4P) then
            x(n) = a ; y(n) = b
         endif
      enddo
      if (pass == 1_I4P) allocate(x(n), y(n))
   enddo
   close(unit)
   endsubroutine read_table
endmodule appelbe_io
