!< Tutorial 3: a magnetised plasma: the (perp, wedge) components as one complex number, and the paper's solver.
program tut03_magnetised
!< Tutorial 3: a magnetised plasma: the (perp, wedge) components as one complex number, and the paper's solver.
use appelbe

implicit none
type(kinetic_params)   :: par    !< Physical parameters.
type(kinetic_operator) :: op     !< Kinetic operator.
type(kinetic_response) :: r, rp  !< Responses: complex solver, paper's solver.
integer(I4P)           :: i      !< Counter.
real(R8P)              :: x      !< log10(omega tau).

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%u_a = 0.5_R8P
call op%init(par=par)
print '(A)', '  log10(wt)     j_perp    j_wedge   zeta_perp  zeta_wedge'
do i = 0, 6
   x = -3._R8P + real(i, R8P)
   r = op%response(omega_tau=10._R8P**x)
   print '(F11.1,4F11.4)', x, r%j_nu, r%zeta_nu        ! complex: (perp, wedge) = (real, imag)
enddo
r  = op%response(omega_tau=1._R8P)                       ! (G + i wt) f1 = g7, the default
rp = op%response(omega_tau=1._R8P, method=method_paper)  ! (GG + W^2) f1 = ..., Appendix B
print '(/,A,ES9.2)', 'complex vs paper solver, |delta j_nu| = ', abs(r%j_nu - rp%j_nu)
endprogram tut03_magnetised
