!< Uniform speed grid u_j = (j-1) h on [0, u_max] with the Appendix B discretisation (Eqs. B11-B19).
module appelbe_velocity_grid
!< Uniform speed grid u_j = (j-1) h on [0, u_max] with the Appendix B discretisation (Eqs. B11-B19).
!<
!< Rows of the discretised operator are assembled on the full grid (nodes 1..n). Stencils are only valid for
!< interior rows 2..n-1: node 1 carries the boundary condition f(1) = f(2) (Eq. B14), node n carries f(n) = 0 (Eq. B15).
use penf, only : I4P, R8P

implicit none
private
public :: velocity_grid

type :: velocity_grid
   !< Uniform speed grid (speeds normalised by v_Te).
   integer(I4P)           :: n = 0_I4P   !< Number of nodes (odd, Eq. B11-B13).
   real(R8P)              :: h = 0._R8P  !< Grid spacing (Eq. B12).
   real(R8P), allocatable :: u(:)        !< Node speeds u_j = (j-1) h.
   contains
      procedure, pass(self) :: init                  !< Build the grid.
      procedure, pass(self) :: lower_weights         !< Weights of int_0^{u_j} (Eq. B18).
      procedure, pass(self) :: upper_weights         !< Weights of int_{u_j}^{u_max} (Eq. B19).
      procedure, pass(self) :: add_first_derivative  !< Add c * d/du stencil to a row (Eq. B17).
      procedure, pass(self) :: add_second_derivative !< Add c * d2/du2 stencil to a row (Eq. B16).
endtype velocity_grid

contains
   subroutine init(self, n, u_max)
   !< Build the grid.
   class(velocity_grid), intent(inout) :: self  !< The grid.
   integer(I4P),         intent(in)    :: n     !< Number of nodes, odd and >= 7.
   real(R8P),            intent(in)    :: u_max !< Largest normalised speed.
   integer(I4P)                        :: j     !< Counter.
   integer(I4P)                        :: ierr  !< Allocation status.
   character(len=256)                  :: emsg  !< Allocation message.

   if (n < 7_I4P .or. mod(n, 2_I4P) == 0_I4P) error stop 'velocity_grid%init: n must be odd and >= 7'
   self%n = n
   self%h = u_max / real(n - 1_I4P, R8P)
   if (allocated(self%u)) deallocate(self%u)
   allocate(self%u(n), stat=ierr, errmsg=emsg)
   if (ierr /= 0_I4P) error stop 'velocity_grid%init: '//trim(emsg)
   self%u = [(real(j - 1_I4P, R8P) * self%h, j=1_I4P, n)]
   endsubroutine init

   pure function lower_weights(self, j) result(w)
   !< Quadrature weights w such that int_0^{u_j} g du = sum(w * g) (Eq. B18).
   !<
   !< Odd j: Simpson on nodes 1..j. Even j: trapezoid on [1, 2] plus Simpson on 2..j.
   class(velocity_grid), intent(in) :: self      !< The grid.
   integer(I4P),         intent(in) :: j         !< Upper node.
   real(R8P)                        :: w(self%n) !< Weights.

   w = 0._R8P
   if (j <= 1_I4P) return
   if (mod(j, 2_I4P) == 1_I4P) then
      call add_simpson(w, 1_I4P, j, self%h)
   else
      call add_trapezoid(w, 1_I4P, 2_I4P, self%h)
      call add_simpson(w, 2_I4P, j, self%h)
   endif
   endfunction lower_weights

   pure function upper_weights(self, j) result(w)
   !< Quadrature weights w such that int_{u_j}^{u_max} g du = sum(w * g) (Eq. B19, with n odd).
   !<
   !< Odd j: Simpson on nodes j..n. Even j: Simpson on j..n-1 plus trapezoid on [n-1, n].
   class(velocity_grid), intent(in) :: self      !< The grid.
   integer(I4P),         intent(in) :: j         !< Lower node.
   real(R8P)                        :: w(self%n) !< Weights.

   w = 0._R8P
   if (j >= self%n) return
   if (mod(j, 2_I4P) == 1_I4P) then
      call add_simpson(w, j, self%n, self%h)
   else
      call add_simpson(w, j, self%n - 1_I4P, self%h)
      call add_trapezoid(w, self%n - 1_I4P, self%n, self%h)
   endif
   endfunction upper_weights

   pure subroutine add_first_derivative(self, j, c, row)
   !< Add c * df/du at node j to an operator row: 5-point centred stencil, 3-point next to the boundaries (Eq. B17).
   class(velocity_grid), intent(in)    :: self   !< The grid.
   integer(I4P),         intent(in)    :: j      !< Row node, 2 <= j <= n-1.
   real(R8P),            intent(in)    :: c      !< Coefficient.
   real(R8P),            intent(inout) :: row(:) !< Operator row on the full grid.

   if (j > 2_I4P .and. j < self%n - 1_I4P) then
      row(j-2:j+2) = row(j-2:j+2) + c * [1._R8P, -8._R8P, 0._R8P, 8._R8P, -1._R8P] / (12._R8P * self%h)
   else
      row(j-1:j+1) = row(j-1:j+1) + c * [-1._R8P, 0._R8P, 1._R8P] / (2._R8P * self%h)
   endif
   endsubroutine add_first_derivative

   pure subroutine add_second_derivative(self, j, c, row)
   !< Add c * d2f/du2 at node j to an operator row: 5-point centred stencil, 3-point next to the boundaries (Eq. B16).
   class(velocity_grid), intent(in)    :: self   !< The grid.
   integer(I4P),         intent(in)    :: j      !< Row node, 2 <= j <= n-1.
   real(R8P),            intent(in)    :: c      !< Coefficient.
   real(R8P),            intent(inout) :: row(:) !< Operator row on the full grid.

   if (j > 2_I4P .and. j < self%n - 1_I4P) then
      row(j-2:j+2) = row(j-2:j+2) + c * [-1._R8P, 16._R8P, -30._R8P, 16._R8P, -1._R8P] / (12._R8P * self%h**2)
   else
      row(j-1:j+1) = row(j-1:j+1) + c * [1._R8P, -2._R8P, 1._R8P] / self%h**2
   endif
   endsubroutine add_second_derivative

   ! private helpers
   pure subroutine add_simpson(w, i0, i1, h)
   !< Accumulate composite-Simpson weights on nodes i0..i1 (i1 - i0 must be even; no-op if i1 <= i0).
   real(R8P),    intent(inout) :: w(:) !< Weights.
   integer(I4P), intent(in)    :: i0   !< First node.
   integer(I4P), intent(in)    :: i1   !< Last node.
   real(R8P),    intent(in)    :: h    !< Grid spacing.
   integer(I4P)                :: i    !< Counter.

   if (i1 <= i0) return
   w(i0) = w(i0) + h / 3._R8P
   w(i1) = w(i1) + h / 3._R8P
   do i = i0 + 1_I4P, i1 - 1_I4P
      w(i) = w(i) + merge(4._R8P, 2._R8P, mod(i - i0, 2_I4P) == 1_I4P) * h / 3._R8P
   enddo
   endsubroutine add_simpson

   pure subroutine add_trapezoid(w, i0, i1, h)
   !< Accumulate trapezoid weights on the single interval [i0, i1 = i0 + 1].
   real(R8P),    intent(inout) :: w(:) !< Weights.
   integer(I4P), intent(in)    :: i0   !< First node.
   integer(I4P), intent(in)    :: i1   !< Last node.
   real(R8P),    intent(in)    :: h    !< Grid spacing.

   w(i0) = w(i0) + 0.5_R8P * h
   w(i1) = w(i1) + 0.5_R8P * h
   endsubroutine add_trapezoid
endmodule appelbe_velocity_grid
