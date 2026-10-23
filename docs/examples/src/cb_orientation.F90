!< Cookbook: the closure for any orientation of the fast-ion flux to B (Eq. 27; not in the paper, see the guide).
program cb_orientation
!< Cookbook: the closure for any orientation of the fast-ion flux to B (Eq. 27; not in the paper, see the guide).
!run cb_orientation ./cb_orientation
use appelbe

implicit none
type(kinetic_params)   :: par              !< Physical parameters.
type(kinetic_operator) :: op               !< Kinetic operator.
type(kinetic_response) :: r0, r            !< Responses at omega tau = 0 (parallel) and at omega tau.
real(R8P)              :: b(3), s(3)       !< Unit field direction, unit fast-ion flux direction.
real(R8P)              :: s_par(3), s_perp(3), s_wedge(3), j(3) !< Eq. (27) basis, j0_ea / (Z_a e n_a <v_a>).

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%u_a = 0.5_R8P
call op%init(par=par)
!region orientation
b = [0._R8P, 0._R8P, 1._R8P]
s = [1._R8P, 0._R8P, 1._R8P] / sqrt(2._R8P)        ! flux at 45 degrees to B
r0 = op%response(omega_tau=0._R8P)                 ! along b the electrons are unmagnetised
r  = op%response(omega_tau=1._R8P)
s_par   = dot_product(b, s) * b                    ! (b.s) b
s_perp  = cross(b, cross(s, b))                    ! b x (s x b)
s_wedge = cross(b, s)                              ! b x s
j = real(r0%j_nu) * s_par + real(r%j_nu) * s_perp + aimag(r%j_nu) * s_wedge
print '(A,3F9.4)', 'j0_ea / (Z_a e n_a <v_a>) = ', j
!endregion orientation
contains
   pure function cross(a, c) result(d)
   real(R8P), intent(in) :: a(3), c(3) !< Vectors.
   real(R8P)             :: d(3)       !< a x c.

   d = [a(2) * c(3) - a(3) * c(2), a(3) * c(1) - a(1) * c(3), a(1) * c(2) - a(2) * c(1)]
   endfunction cross
endprogram cb_orientation
