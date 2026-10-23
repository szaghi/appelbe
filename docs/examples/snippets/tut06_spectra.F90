!< Tutorial 6: fast ions with an energy spread (footnote 30): a Gaussian spectrum and the slowing-down distribution.
program tut06_spectra
!< Tutorial 6: fast ions with an energy spread (footnote 30): a Gaussian spectrum and the slowing-down distribution.
use appelbe

implicit none
type(kinetic_params)   :: par       !< Physical parameters.
type(kinetic_operator) :: broad, mono !< Operators: spread population, monoenergetic one at the mean energy.
type(kinetic_response) :: rb, rm    !< Responses.
real(R8P)              :: u_c       !< Critical speed of the slowing-down distribution.

par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha
par%u_a = 0.5_R8P                                      ! reference speed (a node is aligned with it)
call broad%init(par=par, n_nodes=801_I4P, distribution=energy_gaussian, shape_params=[0.5_R8P, 0.4_R8P])
par%u_a = broad%u_energy                               ! the speed of the mean energy
call mono%init(par=par, n_nodes=801_I4P)
rb = broad%response(omega_tau=0._R8P)
rm = mono%response(omega_tau=0._R8P)
print '(A,F7.4,A,F7.4)', 'Gaussian, sigma_E/E = 0.4:  u_energy = ', broad%u_energy, ',  u_flux = ', broad%u_flux
print '(A,F8.4,A,F8.4)', '   j_nu broad = ', real(rb%j_nu), ',  monoenergetic = ', real(rm%j_nu)
u_c = (0.75_R8P * sqrt_pi * m_e / m_DT)**(1._R8P / 3._R8P)     ! classical critical speed in DT
par%u_a = 1._R8P                                               ! birth speed, on a node
call broad%init(par=par, n_nodes=801_I4P, u_max=6._R8P, distribution=slowing_down, shape_params=[1._R8P, u_c])
par%u_a = broad%u_energy
call mono%init(par=par, n_nodes=801_I4P)
rb = broad%response(omega_tau=0._R8P)
rm = mono%response(omega_tau=0._R8P)
print '(/,A,F7.4)', 'slowing-down, born at v_Te:  u_energy = ', broad%u_energy
print '(A,F8.4,A,F8.4)', '   zeta_nu broad = ', real(rb%zeta_nu), ',  monoenergetic = ', real(rm%zeta_nu)
endprogram tut06_spectra
