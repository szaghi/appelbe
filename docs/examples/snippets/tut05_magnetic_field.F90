!< Tutorial 5: dimensional estimates of Sec. V: collision time, Coulomb logarithm, field advection and generation.
program tut05_magnetic_field
!< Tutorial 5: dimensional estimates of Sec. V: collision time, Coulomb logarithm, field advection and generation.
use appelbe

implicit none
type(kinetic_params)   :: par                    !< Physical parameters.
type(kinetic_operator) :: op                     !< Kinetic operator.
type(kinetic_response) :: r                      !< Response.
real(R8P)              :: te, n_e, lnl, tau, coef !< T_e [J], n_e [m^-3], ln(Lambda), tau_ei [s], Eq. (43) coefficient.
real(R8P)              :: flux, j0, rate         !< Alpha flux [m^-2 s^-1], j0_ea [A m^-2], dB/dt [T/s].
complex(R8P)           :: u                      !< Advection velocity (perp, wedge) [m/s].

te  = 5._R8P * keV_J                       ! hotspot: 5 keV
n_e = 1.e5_R8P / (2.5_R8P * 1.6605e-27_R8P) ! 1e5 kg/m^3 of DT, n_e = n_i
lnl = coulomb_log_ei_nrl(n_e, te)
tau = tau_ei(te, n_e, 1._R8P, lnl)
print '(A,F6.2,A,ES10.3,A)', 'ln(Lambda_ei) = ', lnl, ',  tau_ei = ', tau, ' s'
par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, te)
call op%init(par=par)
r = op%response(omega_tau=0._R8P)                     ! unmagnetised
u = advection_velocity(par%z_a, 1.e-3_R8P, 1.e7_R8P, r%j_nu)   ! n_a/n_e = 1e-3, <v_a> = 1e7 m/s (Eq. 40)
print '(A,2ES11.3,A)', 'advection velocity (perp, wedge) = ', u, ' m/s'
flux = 1.e34_R8P                                       ! alpha flux n_a <v_a>
j0   = par%z_a * e_charge * flux * real(r%j_nu)        ! j0_ea (Eq. C1)
coef = resistive_coefficient(te, 1._R8P, lnl, real(r%resistivity()))
rate = field_generation_rate(coef, abs(j0) / 1.e-5_R8P, j0, te, 1._R8P * keV_J / 1.e-6_R8P)
print '(A,ES10.3,A)', 'j0_ea = ', j0, ' A/m^2'
print '(A,ES10.3,A)', 'dB/dt (Eq. 43, 10 um, 1 keV/um) = ', rate, ' T/s'
endprogram tut05_magnetic_field
