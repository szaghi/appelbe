!< The GUI's exports: plain tables in the format of the driver's results tables, written where the user chose (no FIGURE).
module appelbe_gui_export
!< The GUI's exports: plain tables in the format of the driver's results tables, written where the user chose (no FIGURE).
!<
!< One '#' header line, then rows, as appelbe_electrons writes them: the f0 profile and the f1 profiles with the
!< library's headers and writer (write_table), so that the GUI's export of the driver's reference case is byte for
!< byte the driver's electrons_profile.dat and electrons_f1.dat; a scan with scan_header and write_scan_row
!< (electrons_scan_{A,u0,w}.dat). The readouts and the omega tau sweep have no driver file: their headers name the
!< columns. Every writer returns stat /= 0 and the reason instead of stopping.
use penf,                   only : I4P, R8P
use appelbe_electron_study, only : profile_header, f1_header, readouts_header, scan_header, write_table, write_scan_row, &
                                   n_readouts
use appelbe_gui_model,      only : f0_view, solve_job, scan_job, N_CURVES, SCAN_PARAMETERS

implicit none
private
public :: export_profile, export_f1, export_readouts, export_sweep, export_scan, sweep_header

contains
   subroutine export_profile(path, view, stat, errmsg)
   !< The f0 profile against the Maxwellian at T_e (electron_profile; the driver's electrons_profile.dat).
   character(*),                  intent(in)  :: path   !< File.
   type(f0_view),                 intent(in)  :: view   !< The f0 view.
   integer(I4P),                  intent(out) :: stat   !< 0 on success.
   character(len=:), allocatable, intent(out) :: errmsg !< Why not.
   integer(I4P)                               :: unit   !< Unit.

   if (.not. view%valid) then
      stat = 1_I4P ; errmsg = 'nothing to export: '//view%error ; return
   endif
   call open_table(path, profile_header, unit, stat, errmsg)
   if (stat /= 0_I4P) return
   call write_table(unit, view%prof)
   close(unit)
   endsubroutine export_profile

   subroutine export_f1(path, job, stat, errmsg)
   !< The f1 profiles of a solve (electron_f1; the driver's electrons_f1.dat when omega tau = 1).
   character(*),                  intent(in)  :: path   !< File.
   type(solve_job),               intent(in)  :: job    !< A finished solve.
   integer(I4P),                  intent(out) :: stat   !< 0 on success.
   character(len=:), allocatable, intent(out) :: errmsg !< Why not.
   integer(I4P)                               :: unit   !< Unit.

   if (.not. allocated(job%f1)) then
      stat = 1_I4P ; errmsg = 'nothing to export: Solve first' ; return
   endif
   call open_table(path, at_omega_tau(f1_header, job%inp%omega_tau), unit, stat, errmsg)
   if (stat /= 0_I4P) return
   call write_table(unit, job%f1)
   close(unit)
   endsubroutine export_f1

   subroutine export_readouts(path, job, stat, errmsg)
   !< The 17 readouts of a solve, one row (readouts_header; the driver prints them for a table).
   character(*),                  intent(in)  :: path   !< File.
   type(solve_job),               intent(in)  :: job    !< A finished solve.
   integer(I4P),                  intent(out) :: stat   !< 0 on success.
   character(len=:), allocatable, intent(out) :: errmsg !< Why not.
   integer(I4P)                               :: unit   !< Unit.

   if (job%done == 0_I4P) then
      stat = 1_I4P ; errmsg = 'nothing to export: Solve first' ; return
   endif
   call open_table(path, at_omega_tau(readouts_header, job%inp%omega_tau), unit, stat, errmsg)
   if (stat /= 0_I4P) return
   write(unit, '(*(ES15.6))') job%readouts(1:n_readouts)
   close(unit)
   endsubroutine export_readouts

   pure function sweep_header() result(h)
   !< Columns of the omega tau sweep: omega tau, then for f0, the Maxwellian at T_e and the one at T_kin, perp and
   !< wedge of sigma, beta, kappa, j_nu, zeta_nu.
   character(len=:), allocatable :: h       !< Header.
   character(len=*), parameter   :: q(5) = [character(len=7) :: 'sigma', 'beta', 'kappa', 'j_nu', 'zeta_nu'] !< Names.
   character(len=*), parameter   :: c(3) = [character(len=6) :: '', '(M)', '(Mkin)'] !< Curves.
   integer                       :: i, k    !< Counters.

   h = 'omega_tau'
   do k = 1, N_CURVES
      do i = 1, 5
         h = h//' '//trim(q(i))//'_perp'//trim(c(k))//' '//trim(q(i))//'_wedge'//trim(c(k))
      enddo
   enddo
   endfunction sweep_header

   subroutine export_sweep(path, job, stat, errmsg)
   !< The omega tau sweep of a solve: every response of the three curves (sweep_header).
   character(*),                  intent(in)  :: path   !< File.
   type(solve_job),               intent(in)  :: job    !< A finished solve.
   integer(I4P),                  intent(out) :: stat   !< 0 on success.
   character(len=:), allocatable, intent(out) :: errmsg !< Why not.
   integer(I4P)                               :: unit, k, c !< Unit, counters.
   complex(R8P)                               :: q(5)   !< One curve's quantities.

   if (.not. allocated(job%r) .or. job%done < job%steps()) then
      stat = 1_I4P ; errmsg = 'nothing to export: Solve first' ; return
   endif
   call open_table(path, sweep_header(), unit, stat, errmsg)
   if (stat /= 0_I4P) return
   do k = 1_I4P, size(job%wt, kind=I4P)
      write(unit, '(ES15.6)', advance='no') job%wt(k)
      do c = 1_I4P, N_CURVES
         associate(r => job%r(k, c))
            q = [r%sigma, r%beta(), r%kappa(), r%j_nu, r%zeta_nu]
         endassociate
         write(unit, '(10ES15.6)', advance='no') q
      enddo
      write(unit, '(A)') ''
   enddo
   close(unit)
   endsubroutine export_sweep

   subroutine export_scan(path, scan, stat, errmsg)
   !< A scan, one row per value (scan_header, write_scan_row: the driver's electrons_scan_*.dat).
   character(*),                  intent(in)  :: path   !< File.
   type(scan_job),                intent(in)  :: scan   !< A finished scan.
   integer(I4P),                  intent(out) :: stat   !< 0 on success.
   character(len=:), allocatable, intent(out) :: errmsg !< Why not.
   integer(I4P)                               :: unit, i !< Unit, row.

   if (.not. allocated(scan%p) .or. .not. scan%finished() .or. scan%failed) then
      stat = 1_I4P ; errmsg = 'nothing to export: run a scan first' ; return
   endif
   call open_table(path, at_omega_tau(scan_header(trim(SCAN_PARAMETERS(scan%inp%scan_param))), scan%inp%omega_tau), &
                   unit, stat, errmsg)
   if (stat /= 0_I4P) return
   do i = 1_I4P, size(scan%p, kind=I4P)
      call write_scan_row(unit, scan%p(i), scan%o(i, :), scan%max_dev(i), scan%monotone(i))
   enddo
   close(unit)
   endsubroutine export_scan

   ! private
   subroutine open_table(path, header, unit, stat, errmsg)
   !< Create (or replace) path and write the '#' header line.
   character(*),                  intent(in)  :: path   !< File.
   character(*),                  intent(in)  :: header !< Columns.
   integer(I4P),                  intent(out) :: unit   !< Unit.
   integer(I4P),                  intent(out) :: stat   !< 0 on success.
   character(len=:), allocatable, intent(out) :: errmsg !< Why not.
   character(len=256)                         :: emsg   !< Message.

   errmsg = ''
   open(newunit=unit, file=path, status='replace', action='write', iostat=stat, iomsg=emsg)
   if (stat /= 0_I4P) then
      stat = 1_I4P ; errmsg = 'cannot write '//trim(path)//': '//trim(emsg) ; return
   endif
   write(unit, '(A)') '# '//header
   endsubroutine open_table

   pure function at_omega_tau(header, wt) result(h)
   !< The library's header, which names the second Hall parameter '[wt=1' (the driver's), with the one solved for.
   character(*), intent(in)      :: header !< Header with '[wt=1]' or '[wt=1, ...]'.
   real(R8P),    intent(in)      :: wt     !< The Hall parameter of the solve.
   character(len=:), allocatable :: h      !< Header.
   integer                       :: i      !< Position.

   h = header
   if (wt == 1._R8P) return
   i = index(h, '[wt=1')
   if (i > 0) h = h(:i-1)//'[wt='//real_text(wt)//h(i+5:)
   endfunction at_omega_tau

   pure function real_text(x) result(t)
   !< A real as short text.
   real(R8P), intent(in)         :: x !< Value.
   character(len=:), allocatable :: t !< Text.
   character(len=32)             :: b !< Buffer.

   write(b, '(G0.6)') x
   t = trim(adjustl(b))
   endfunction real_text
endmodule appelbe_gui_export
