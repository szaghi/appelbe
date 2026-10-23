!< Cookbook: from the normalised closure to SI fields: j0_ea [A m^-2] and zeta_ea [W m^-2] (Eqs. C1-C4).
program cb_si_units
!< Cookbook: from the normalised closure to SI fields: j0_ea [A m^-2] and zeta_ea [W m^-2] (Eqs. C1-C4).
use appelbe

implicit none
type(kinetic_params)   :: par            !< Physical parameters.
type(kinetic_operator) :: op             !< Kinetic operator.
type(kinetic_response) :: r              !< Response.
real(R8P)              :: te, flux       !< T_e [J], alpha flux n_a <v_a> [m^-2 s^-1].
complex(R8P)           :: j0, zeta       !< Fields (perp, wedge).

te   = 5._R8P * keV_J
flux = 1.e34_R8P
par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, te)
call op%init(par=par)
r = op%response(omega_tau=0.5_R8P)
j0   = par%z_a * e_charge * flux * r%j_nu        ! (C1)-(C2)
zeta = flux * te * r%zeta_nu                     ! (C3)-(C4), T_e in joules
print '(A,2ES11.3)', 'j0_ea   (perp, wedge) [A m^-2] = ', j0
print '(A,2ES11.3)', 'zeta_ea (perp, wedge) [W m^-2] = ', zeta
endprogram cb_si_units
