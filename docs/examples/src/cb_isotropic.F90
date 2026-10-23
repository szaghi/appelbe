!< Cookbook: how an isotropic fast-ion population changes the conventional coefficients (Sec. VI, Fig. 6).
program cb_isotropic
!< Cookbook: how an isotropic fast-ion population changes the conventional coefficients (Sec. VI, Fig. 6).
!run cb_isotropic ./cb_isotropic
use appelbe

implicit none
type(kinetic_params)   :: par      !< Physical parameters.
type(kinetic_operator) :: op       !< Kinetic operator.
type(kinetic_response) :: r0, r    !< Without and with the alphas.
integer(I4P)           :: k        !< Counter.

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
call op%init(par=par)
r0 = op%response(omega_tau=0._R8P)
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, 5._R8P * keV_J)
print '(A)', '     n_a/n_e   mu/mu0    K/K0'
do k = 4, 1, -1
   par%n_ratio = 10._R8P**(-k)                     ! only F0 enters the operator: no flux needed
   call op%init(par=par)
   r = op%response(omega_tau=0._R8P)
   print '(ES12.1,2F9.4)', par%n_ratio, real(r%mu) / real(r0%mu), real(r%thermal_diffusion) / real(r0%thermal_diffusion)
enddo
endprogram cb_isotropic
