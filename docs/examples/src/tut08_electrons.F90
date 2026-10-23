!< Tutorial 8: a non-Maxwellian electron f0, what TS and ECE read from it, and what it does to transport.
program tut08_electrons
!< Tutorial 8: a non-Maxwellian electron f0, what TS and ECE read from it, and what it does to transport.
!run tut08 ./tut08_electrons
use appelbe

implicit none
type(kinetic_params)   :: par      !< Physical parameters.
type(kinetic_operator) :: maxw, bip !< Operators: Maxwellian and distorted electrons.
type(kinetic_response) :: rm, rb   !< Responses.
real(R8P), allocatable :: t(:)     !< Local log-slope temperature.
logical, allocatable   :: win(:)   !< ECE window 1 <= u_L <= 4.

!region bipolar
par%z_i = 1._R8P ; par%z_a = 2._R8P ; par%mass_ratio = m_e / m_alpha ; par%n_ratio = 1.e-3_R8P
par%u_a = speed_ratio(3.45_R8P * MeV_J, m_alpha, 10._R8P * keV_J)            ! 3.45 MeV alphas at T_e = 10 keV
call maxw%init(par=par, n_nodes=801_I4P)
call bip%init(par=par, n_nodes=801_I4P, electrons=electron_bipolar, electron_params=[0.1_R8P, 2._R8P, 0.25_R8P])
!endregion bipolar
!region readouts
t   = slope_temperature(bip)                                                 ! ECE, optically thick
win = sqrt(2._R8P) * bip%grid%u >= 1._R8P .and. sqrt(2._R8P) * bip%grid%u <= 4._R8P
print '(A,2F8.4)', 'TS fit (w <= 2, w <= 3)      : ', ts_temperature(bip, 2._R8P), ts_temperature(bip, 3._R8P)
print '(A,F8.4)',  'energy moment (2/3)<u^2>     : ', kinetic_temperature(bip)
print '(A,2F8.4)', 'ECE slope temperature, range : ', minval(t, mask=win), maxval(t, mask=win)
!endregion readouts
!region transport
rm = maxw%response(omega_tau=0._R8P)
rb = bip%response(omega_tau=0._R8P)
print '(/,A)', 'relative change against the Maxwellian, omega tau = 0:'
print '(A,F8.4,A,F8.4)', '   sigma ', real(rb%sigma / rm%sigma) - 1, '   kappa   ', real(rb%kappa() / rm%kappa()) - 1
print '(A,F8.4,A,F8.4)', '   j_nu  ', real(rb%j_nu / rm%j_nu) - 1,   '   zeta_nu ', real(rb%zeta_nu / rm%zeta_nu) - 1
print '(A,F8.4)', 'Onsager tau / (mu - 3/2 sigma) - 1: ', real(rb%tau / (rb%mu - 1.5_R8P * rb%sigma)) - 1
!endregion transport
endprogram tut08_electrons
