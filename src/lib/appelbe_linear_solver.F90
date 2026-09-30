!< Dense linear solver: Gaussian elimination with partial pivoting (Appendix B uses an LU decomposition).
module appelbe_linear_solver
!< Dense linear solver: Gaussian elimination with partial pivoting (Appendix B uses an LU decomposition).
!<
!< Deliberately self-contained (no LAPACK dependency): the systems are O(400-1600) unknowns, so simplicity wins over speed.
!< The real version serves the paper's solver (Eqs. B6-B8), the complex one the (G + i omega tau) formulation.
!< Elimination is column-oriented (contiguous access in column-major storage).
use penf, only : I4P, R8P

implicit none
private
public :: solve_dense

interface solve_dense
   !< Solve a x = b in place (a destroyed), real or complex.
   module procedure solve_dense_real, solve_dense_complex
endinterface solve_dense

contains
   pure subroutine solve_dense_real(a, b)
   !< Solve a x = b in place for every column of b; a is destroyed.
   real(R8P), intent(inout) :: a(:,:)   !< Square matrix, overwritten by the elimination.
   real(R8P), intent(inout) :: b(:,:)   !< Right-hand sides on entry, solutions on exit.
   real(R8P), allocatable   :: swap(:)  !< Row buffer.
   integer(I4P)             :: n, j, k  !< Order, counters.
   integer(I4P)             :: p        !< Pivot row.

   n = size(a, dim=1, kind=I4P)
   if (size(a, dim=2, kind=I4P) /= n .or. size(b, dim=1, kind=I4P) /= n) error stop 'solve_dense: shape mismatch'
   do k = 1_I4P, n - 1_I4P
      p = maxloc(abs(a(k:n, k)), dim=1, kind=I4P) + k - 1_I4P
      if (abs(a(p, k)) <= tiny(1._R8P)) error stop 'solve_dense: singular matrix'
      if (p /= k) then
         swap = a(k, :) ; a(k, :) = a(p, :) ; a(p, :) = swap
         swap = b(k, :) ; b(k, :) = b(p, :) ; b(p, :) = swap
      endif
      a(k+1:n, k) = a(k+1:n, k) / a(k, k) ! multipliers
      do j = k + 1_I4P, n
         a(k+1:n, j) = a(k+1:n, j) - a(k+1:n, k) * a(k, j)
      enddo
      do j = 1_I4P, size(b, dim=2, kind=I4P)
         b(k+1:n, j) = b(k+1:n, j) - a(k+1:n, k) * b(k, j)
      enddo
   enddo
   if (abs(a(n, n)) <= tiny(1._R8P)) error stop 'solve_dense: singular matrix'
   do k = n, 1_I4P, -1_I4P
      b(k, :) = b(k, :) / a(k, k)
      do j = 1_I4P, size(b, dim=2, kind=I4P)
         b(1:k-1, j) = b(1:k-1, j) - a(1:k-1, k) * b(k, j)
      enddo
   enddo
   endsubroutine solve_dense_real

   pure subroutine solve_dense_complex(a, b)
   !< Solve a x = b in place for every column of b; a is destroyed.
   complex(R8P), intent(inout) :: a(:,:)   !< Square matrix, overwritten by the elimination.
   complex(R8P), intent(inout) :: b(:,:)   !< Right-hand sides on entry, solutions on exit.
   complex(R8P), allocatable   :: swap(:)  !< Row buffer.
   integer(I4P)                :: n, j, k  !< Order, counters.
   integer(I4P)                :: p        !< Pivot row.

   n = size(a, dim=1, kind=I4P)
   if (size(a, dim=2, kind=I4P) /= n .or. size(b, dim=1, kind=I4P) /= n) error stop 'solve_dense: shape mismatch'
   do k = 1_I4P, n - 1_I4P
      p = maxloc(abs(a(k:n, k)), dim=1, kind=I4P) + k - 1_I4P
      if (abs(a(p, k)) <= tiny(1._R8P)) error stop 'solve_dense: singular matrix'
      if (p /= k) then
         swap = a(k, :) ; a(k, :) = a(p, :) ; a(p, :) = swap
         swap = b(k, :) ; b(k, :) = b(p, :) ; b(p, :) = swap
      endif
      a(k+1:n, k) = a(k+1:n, k) / a(k, k) ! multipliers
      do j = k + 1_I4P, n
         a(k+1:n, j) = a(k+1:n, j) - a(k+1:n, k) * a(k, j)
      enddo
      do j = 1_I4P, size(b, dim=2, kind=I4P)
         b(k+1:n, j) = b(k+1:n, j) - a(k+1:n, k) * b(k, j)
      enddo
   enddo
   if (abs(a(n, n)) <= tiny(1._R8P)) error stop 'solve_dense: singular matrix'
   do k = n, 1_I4P, -1_I4P
      b(k, :) = b(k, :) / a(k, k)
      do j = 1_I4P, size(b, dim=2, kind=I4P)
         b(1:k-1, j) = b(1:k-1, j) - a(1:k-1, k) * b(k, j)
      enddo
   enddo
   endsubroutine solve_dense_complex
endmodule appelbe_linear_solver
