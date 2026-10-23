!< Tutorial 2: the current and heat flow induced by a drifting fast-ion population, unmagnetised.
program tut02_fast_ions
!< Tutorial 2: the current and heat flow induced by a drifting fast-ion population, unmagnetised.
use appelbe

implicit none
type(kinetic_params)   :: par !< Physical parameters.
type(kinetic_operator) :: op  !< Kinetic operator.
type(kinetic_response) :: r   !< Response.
integer(I4P)           :: k   !< Counter.
real(R8P)              :: v   !< v_a / v_Te.

par%z_i        = 1._R8P            ! DT, average ion
par%z_a        = 2._R8P            ! alpha particles
par%mass_ratio = m_e / m_alpha
par%u_a        = 0.5_R8P           ! v_a / v_Te
call op%init(par=par)              ! a node is placed exactly on u_a
r = op%response(omega_tau=0._R8P)
print '(A,F8.4)', 'j0_ea / j0_a                 = ', real(r%j_nu)
print '(A,F8.4)', 'zeta_ea / (n_a <v_a> T_e)    = ', real(r%zeta_nu)
print '(/,A)', '  v_a/v_Te   j_nu (alpha)   zeta_nu (alpha)'
do k = 0, 4
   v = 0.1_R8P * 10._R8P**(0.25_R8P * k)
   par%u_a = v
   call op%init(par=par)
   r = op%response(omega_tau=0._R8P)
   print '(F10.3,2F15.4)', v, real(r%j_nu), real(r%zeta_nu)
enddo
print '(/,A)', 'v_a/v_Te = 0.1:   species   Z_a   j_nu     1 - Z_a/Z_i (Eq. 32)'
call species('proton', 1._R8P, m_proton)
call species('alpha',  2._R8P, m_alpha)
call species('carbon', 6._R8P, m_carbon12)
contains
   subroutine species(name, z_a, mass)
   character(*), intent(in) :: name !< Label.
   real(R8P),    intent(in) :: z_a  !< Charge state.
   real(R8P),    intent(in) :: mass !< Mass [kg].

   par%z_a = z_a ; par%mass_ratio = m_e / mass ; par%u_a = 0.1_R8P
   call op%init(par=par)
   r = op%response(omega_tau=0._R8P)
   print '(A18,F6.0,F9.4,F12.1)', name, z_a, real(r%j_nu), 1._R8P - z_a / par%z_i
   endsubroutine species
endprogram tut02_fast_ions
