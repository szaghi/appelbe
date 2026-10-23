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
