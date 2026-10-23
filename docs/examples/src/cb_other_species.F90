!< Cookbook: a fast-ion species the fits do not cover: 200 MeV C6+ in DT (Sec. V B).
program cb_other_species
!< Cookbook: a fast-ion species the fits do not cover: 200 MeV C6+ in DT (Sec. V B).
!run cb_other_species ./cb_other_species
use appelbe

implicit none
type(kinetic_params)   :: par  !< Physical parameters.
type(kinetic_operator) :: op   !< Kinetic operator.
type(kinetic_response) :: r    !< Response.
integer(I4P)           :: k    !< Counter.
real(R8P), parameter   :: t_keV(4) = [1._R8P, 2._R8P, 5._R8P, 10._R8P] !< Temperatures.

par%z_i = 1._R8P ; par%z_a = 6._R8P ; par%mass_ratio = m_e / m_carbon12
print '(A)', '  T_e [keV]   v_a/v_Te   j0_ea/j0_a'
do k = 1, size(t_keV)
   par%u_a = speed_ratio(200._R8P * MeV_J, m_carbon12, t_keV(k) * keV_J)
   call op%init(par=par, u_max=max(7._R8P, 2.5_R8P * par%u_a))     ! room for f1 beyond a fast beam
   r = op%response(omega_tau=0._R8P)
   print '(F10.1,F11.3,F13.3)', t_keV(k), par%u_a, real(r%j_nu)
enddo
endprogram cb_other_species
