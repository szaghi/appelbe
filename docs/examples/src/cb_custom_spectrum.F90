!< Cookbook: a fast-ion population with your own speed distribution.
module cb_custom_shape
!< A user-defined fast-ion speed distribution: a shell u_0 +/- w with cosine edges.
use appelbe, only : R8P, pi

implicit none
private
public :: cosine_shell

contains
   pure function cosine_shell(u, p) result(f)
   !< F(u) ~ cos^2(pi (u - u_0) / (2 w)) on |u - u_0| < w, 0 elsewhere; any normalisation.
   real(R8P), intent(in) :: u    !< Normalised speed.
   real(R8P), intent(in) :: p(:) !< [u_0, w].
   real(R8P)             :: f    !< F(u).

   f = 0._R8P
   if (abs(u - p(1)) < p(2)) f = cos(0.5_R8P * pi * (u - p(1)) / p(2))**2
   endfunction cosine_shell
endmodule cb_custom_shape

program cb_custom_spectrum
!< Cookbook: a fast-ion population with your own speed distribution.
!run cb_custom_spectrum ./cb_custom_spectrum
use appelbe
use cb_custom_shape, only : cosine_shell

implicit none
type(kinetic_params)   :: par !< Physical parameters.
type(kinetic_operator) :: op  !< Kinetic operator.
type(kinetic_response) :: r   !< Response.

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
par%u_a = 0.5_R8P                                  ! a reference speed > 0 enables the fast ions
call op%init(par=par, n_nodes=801_I4P, distribution=cosine_shell, shape_params=[0.5_R8P, 0.1_R8P])
r = op%response(omega_tau=0._R8P)
print '(A,F8.4,A,F8.4)', 'u_flux = ', op%u_flux, ',  u_energy = ', op%u_energy
print '(A,F8.4,A,F8.4)', 'j_nu   = ', real(r%j_nu), ',  zeta_nu  = ', real(r%zeta_nu)
endprogram cb_custom_spectrum
