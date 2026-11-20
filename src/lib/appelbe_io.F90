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

   subroutine read_table(file_name, x, y, stat, errmsg)
   !< Read the first two columns of a plain table (lines starting with '#' and blank lines skipped), e.g. u_L and f0.
   !<
   !< A file that cannot be opened, a line without two numbers, or no line at all stop the program with the message, or,
   !< when stat is present, return stat /= 0 with the message in errmsg (x, y then unallocated).
   character(*),           intent(in)  :: file_name !< Path of the table.
   real(R8P), allocatable, intent(out) :: x(:), y(:) !< First and second column.
   integer(I4P),                  intent(out), optional :: stat   !< 0 on success; 1 on a failure.
   character(len=:), allocatable, intent(out), optional :: errmsg !< Why the read failed ('' on success).
   real(R8P)                           :: a, b      !< Values of one line.
   integer(I4P)                        :: unit, ierr, pass !< Unit, status, pass (1 counts, 2 reads).
   integer(I4P)                        :: n, line_no !< Rows, line number.
   character(len=1024)                 :: line      !< One line.
   character(len=256)                  :: emsg      !< Message.
   character(len=16)                   :: num       !< Line number as text.

   if (present(stat)) stat = 0_I4P
   if (present(errmsg)) errmsg = ''
   open(newunit=unit, file=file_name, status='old', action='read', iostat=ierr, iomsg=emsg)
   if (ierr /= 0_I4P) then
      call fail('read_table: '//trim(emsg)) ; return
   endif
   do pass = 1_I4P, 2_I4P
      n = 0_I4P
      line_no = 0_I4P
      rewind(unit)
      do
         read(unit, '(A)', iostat=ierr) line
         if (ierr /= 0_I4P) exit
         line_no = line_no + 1_I4P
         line = adjustl(line)
         if (len_trim(line) == 0 .or. line(1:1) == '#') cycle
         read(line, *, iostat=ierr) a, b
         if (ierr /= 0_I4P) then
            write(num, '(I0)') line_no
            close(unit)
            if (allocated(x)) deallocate(x, y)
            call fail('read_table: cannot read two numbers from '//trim(file_name)//', line '//trim(num)) ; return
         endif
         n = n + 1_I4P
         if (pass == 2_I4P) then
            x(n) = a ; y(n) = b
         endif
      enddo
      if (pass == 1_I4P) then
         if (n == 0_I4P) then
            close(unit)
            call fail('read_table: no data line in '//trim(file_name)) ; return
         endif
         allocate(x(n), y(n))
      endif
   enddo
   close(unit)
   contains
      subroutine fail(msg)
      !< Stop with msg, or return it through stat and errmsg.
      character(*), intent(in) :: msg !< What failed.

      if (.not. present(stat)) error stop msg
      stat = 1_I4P
      if (present(errmsg)) errmsg = msg
      endsubroutine fail
   endsubroutine read_table
endmodule appelbe_io
