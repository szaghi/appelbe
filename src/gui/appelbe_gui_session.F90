!< The GUI's session file: every input, as text, so that a result can be reproduced and sent to someone (no FIGURE).
module appelbe_gui_session
!< The GUI's session file: every input, as text, so that a result can be reproduced and sent to someone (no FIGURE).
!<
!< A session is the gui_inputs: `key = value` lines, '#' comments, reals with 17 significant digits (ES24.16), so that
!< loading a session gives the very inputs saved, bit for bit, and so the same results. A tabulated f0 is written into
!< the session (its rows after `table =`), not only its path: the session works on another machine. Keys not present
!< keep their defaults (an older session still loads); an unknown key or a value that cannot be read is an error, and
!< then nothing changes.
use penf,              only : I4P, R8P
use appelbe_gui_model, only : gui_inputs, F0_KINDS, SPECIES_NAMES, input_error

implicit none
private
public :: save_session, load_session, SESSION_MAGIC

character(len=*), parameter :: SESSION_MAGIC = '# appelbe-gui session' !< First line of a session file.

contains
   subroutine save_session(inp, path, version, stat, errmsg)
   !< Write the inputs to path.
   type(gui_inputs),              intent(in)  :: inp     !< Inputs.
   character(*),                  intent(in)  :: path    !< File.
   character(*),                  intent(in)  :: version !< The GUI's version, recorded.
   integer(I4P),                  intent(out) :: stat    !< 0 on success.
   character(len=:), allocatable, intent(out) :: errmsg  !< Why not.
   integer(I4P)                               :: unit, i !< Unit, row.
   character(len=256)                         :: emsg    !< Message.

   errmsg = ''
   open(newunit=unit, file=path, status='replace', action='write', iostat=stat, iomsg=emsg)
   if (stat /= 0_I4P) then
      stat = 1_I4P ; errmsg = 'cannot write '//trim(path)//': '//trim(emsg) ; return
   endif
   write(unit, '(A)') SESSION_MAGIC//', version '//version
   write(unit, '(A)') '# electron f0: f0_kind = 1 Maxwellian (t_ratio = T/T_e), 2 bipolar (A u_0 w), 3 table (u_L f0)'
   write(unit, '(A,I0,A)') 'f0_kind    = ', inp%f0_kind, '  # '//trim(F0_KINDS(inp%f0_kind))
   call put('t_ratio', [inp%t_ratio])
   call put('bipolar', inp%bipolar)
   write(unit, '(A)') '# plasma, fast ions (species = 1 alpha, 2 proton, 3 carbon-12, 4 custom), grid, Hall parameter'
   call put('te_kev', [inp%te_kev])
   call put('z_i', [inp%z_i])
   write(unit, '(A,I0,A)') 'species    = ', inp%species, '  # '//trim(SPECIES_NAMES(inp%species))
   call put('z_a', [inp%z_a])
   call put('mass_amu', [inp%mass_amu])
   call put('e_mev', [inp%e_mev])
   call put('n_ratio', [inp%n_ratio])
   write(unit, '(A,I0)') 'n_nodes    = ', inp%n_nodes
   call put('u_max', [inp%u_max])
   call put('omega_tau', [inp%omega_tau])
   write(unit, '(A)') '# scan of the bipolar parameter scan_param (1 A, 2 u_0, 3 w): from scan_min to scan_max, scan_n values'
   write(unit, '(A,I0)') 'scan_param = ', inp%scan_param
   call put('scan_min', inp%scan_min)
   call put('scan_max', inp%scan_max)
   write(unit, '(A,3(1X,I0))') 'scan_n     =', inp%scan_n
   if (allocated(inp%table_x)) then
      write(unit, '(A)') 'table_path = '//trim(inp%table_path)
      write(unit, '(A,I0,A)') 'table      = ', size(inp%table_x), '  # rows follow: u_L f0'
      do i = 1_I4P, size(inp%table_x, kind=I4P)
         write(unit, '(2ES25.16E3)') inp%table_x(i), inp%table_f(i)
      enddo
   endif
   close(unit)

   contains
      subroutine put(key, values)
      !< key = values, 17 significant digits.
      character(*), intent(in) :: key       !< Key.
      real(R8P),    intent(in) :: values(:) !< Values.

      write(unit, '(A,A,*(ES25.16E3))') key//repeat(' ', max(0, 10 - len(key))), ' =', values
      endsubroutine put
   endsubroutine save_session

   subroutine load_session(path, inp, stat, errmsg)
   !< Read a session into inp; on any failure inp is left as it was and errmsg says why (the line).
   character(*),                  intent(in)    :: path    !< File.
   type(gui_inputs),              intent(inout) :: inp     !< Inputs.
   integer(I4P),                  intent(out)   :: stat    !< 0 on success.
   character(len=:), allocatable, intent(out)   :: errmsg  !< Why not.
   type(gui_inputs)                             :: new     !< The inputs read (defaults for missing keys).
   integer(I4P)                                 :: unit, ios, line_no, n, i, k !< Unit, status, line, rows, counters.
   character(len=4096)                          :: line    !< A line.
   character(len=:), allocatable                :: key, value !< Its parts.
   character(len=256)                           :: emsg    !< Message.

   errmsg = ''
   open(newunit=unit, file=path, status='old', action='read', iostat=stat, iomsg=emsg)
   if (stat /= 0_I4P) then
      stat = 1_I4P ; errmsg = 'cannot read '//trim(path)//': '//trim(emsg) ; return
   endif
   read(unit, '(A)', iostat=ios) line
   if (ios /= 0 .or. index(line, SESSION_MAGIC) /= 1) then
      close(unit)
      stat = 1_I4P ; errmsg = trim(path)//' is not an appelbe-gui session (its first line is not "'//SESSION_MAGIC//'")'
      return
   endif
   line_no = 1_I4P
   ios = 0
   do
      read(unit, '(A)', iostat=k) line
      if (k /= 0) exit
      line_no = line_no + 1_I4P
      i = index(line, '#')
      if (i > 0) line(i:) = ''
      if (len_trim(line) == 0) cycle
      i = index(line, '=')
      if (i == 0) then
         call fail('no "key = value"') ; return
      endif
      key = trim(adjustl(line(:i-1)))
      value = trim(adjustl(line(i+1:)))
      select case (key)
      case ('f0_kind')    ; read(value, *, iostat=ios) new%f0_kind
      case ('t_ratio')    ; read(value, *, iostat=ios) new%t_ratio
      case ('bipolar')    ; read(value, *, iostat=ios) new%bipolar
      case ('te_kev')     ; read(value, *, iostat=ios) new%te_kev
      case ('z_i')        ; read(value, *, iostat=ios) new%z_i
      case ('species')    ; read(value, *, iostat=ios) new%species
      case ('z_a')        ; read(value, *, iostat=ios) new%z_a
      case ('mass_amu')   ; read(value, *, iostat=ios) new%mass_amu
      case ('e_mev')      ; read(value, *, iostat=ios) new%e_mev
      case ('n_ratio')    ; read(value, *, iostat=ios) new%n_ratio
      case ('n_nodes')    ; read(value, *, iostat=ios) new%n_nodes
      case ('u_max')      ; read(value, *, iostat=ios) new%u_max
      case ('omega_tau')  ; read(value, *, iostat=ios) new%omega_tau
      case ('scan_param') ; read(value, *, iostat=ios) new%scan_param
      case ('scan_min')   ; read(value, *, iostat=ios) new%scan_min
      case ('scan_max')   ; read(value, *, iostat=ios) new%scan_max
      case ('scan_n')     ; read(value, *, iostat=ios) new%scan_n
      case ('table_path') ; new%table_path = value
      case ('table')
         read(value, *, iostat=ios) n
         if (ios == 0 .and. n < 1) ios = 1
         if (ios == 0) then
            allocate(new%table_x(n), new%table_f(n))
            do i = 1_I4P, n
               read(unit, *, iostat=ios) new%table_x(i), new%table_f(i)
               line_no = line_no + 1_I4P
               if (ios /= 0) exit
            enddo
         endif
      case default
         call fail('unknown key "'//key//'"') ; return
      endselect
      if (ios /= 0) then
         call fail('cannot read the value of "'//key//'"') ; return
      endif
   enddo
   close(unit)
   if (new%f0_kind < 1 .or. new%f0_kind > size(F0_KINDS)) then
      call fail('f0_kind must be 1, 2 or 3', closed=.true.) ; return
   elseif (new%species < 1 .or. new%species > size(SPECIES_NAMES)) then
      call fail('species must be 1 to 4', closed=.true.) ; return
   elseif (new%scan_param < 1 .or. new%scan_param > 3) then
      call fail('scan_param must be 1, 2 or 3', closed=.true.) ; return
   elseif (new%f0_kind == 3 .and. .not. allocated(new%table_x)) then
      call fail('f0_kind = 3 (table) needs the table rows', closed=.true.) ; return
   endif
   errmsg = input_error(new)
   if (len(errmsg) > 0) then
      call fail(errmsg, closed=.true.) ; return
   endif
   inp = new
   stat = 0_I4P

   contains
      subroutine fail(why, closed)
      !< The failure, with the line.
      character(*), intent(in)           :: why    !< Reason.
      logical,      intent(in), optional :: closed !< The unit is closed already.
      character(len=16)                  :: num    !< Line number.

      if (.not. present(closed)) close(unit)
      write(num, '(I0)') line_no
      stat = 1_I4P
      if (present(closed)) then
         errmsg = trim(path)//': '//why
      else
         errmsg = trim(path)//', line '//trim(num)//': '//why
      endif
      endsubroutine fail
   endsubroutine load_session
endmodule appelbe_gui_session
