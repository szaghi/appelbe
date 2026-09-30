!< Conventional transport coefficients (no fast ions) from the kinetic solver.
program test_conventional
!< Conventional transport coefficients (no fast ions) from the kinetic solver.
!<
!< - Lorentz gas (Z_i -> infinity, e-e collisions negligible): exact alpha = 3 pi/32, beta = 3/2, kappa = 128/(3 pi).
!< - Z_i = 1: alpha_par = 0.506 m_e n_e / tau_ei (Eq. 42, Epperlein & Haines).
!< - Onsager relation tau = mu - (3/2) sigma (Eq. 22 in Epperlein-Haines units), unmagnetised and magnetised.
!< - Grid convergence of alpha_par (401 vs 801 nodes).
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_assert,                only : assert_close, assert_summary
use appelbe_constants,             only : pi
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response

implicit none
type(kinetic_params)   :: par       !< Physical parameters.
type(kinetic_operator) :: op        !< Kinetic operator.
type(kinetic_response) :: r         !< Response.
real(R8P)              :: alpha_401 !< alpha_par on the default grid.
real(R8P)              :: omega_tau !< Hall parameter.
integer(I4P)           :: k         !< Counter.
real(R8P), parameter   :: onsager_omega_tau(3) = [0._R8P, 1._R8P, 10._R8P] !< Hall parameters of the Onsager check.

! Lorentz gas
par%z_i = 1.e8_R8P
call op%init(par=par)
r = op%response(omega_tau=0._R8P)
call assert_close('Lorentz alpha', real(r%resistivity(), R8P), 3._R8P * pi / 32._R8P,    rel_tol=1.e-3_R8P)
call assert_close('Lorentz beta ', real(r%beta(),        R8P), 1.5_R8P,                   rel_tol=1.e-3_R8P)
call assert_close('Lorentz kappa', real(r%kappa(),       R8P), 128._R8P / (3._R8P * pi), rel_tol=1.e-3_R8P)

! Z_i = 1
par%z_i = 1._R8P
call op%init(par=par)
r = op%response(omega_tau=0._R8P)
alpha_401 = real(r%resistivity(), R8P)
call assert_close('Z=1 alpha_par (Eq. 42)', alpha_401, 0.506_R8P, rel_tol=1.e-3_R8P)
write(output_unit, '(A,F8.4,A,F8.4)') 'INFO Z=1 beta_par  = ', real(r%beta(), R8P), '   kappa_par = ', real(r%kappa(), R8P)

! Onsager symmetry
do k = 1_I4P, 3_I4P
   omega_tau = onsager_omega_tau(k)
   r = op%response(omega_tau=omega_tau)
   call assert_close('Onsager Re(tau), omega_tau = '//trim(str(omega_tau)), real(r%tau, R8P), &
                     real(r%mu - 1.5_R8P * r%sigma, R8P), rel_tol=1.e-3_R8P, abs_tol=1.e-6_R8P)
   call assert_close('Onsager Im(tau), omega_tau = '//trim(str(omega_tau)), aimag(r%tau), &
                     aimag(r%mu - 1.5_R8P * r%sigma), rel_tol=1.e-3_R8P, abs_tol=1.e-6_R8P)
enddo

! grid convergence
call op%init(par=par, n_nodes=801_I4P)
r = op%response(omega_tau=0._R8P)
call assert_close('alpha_par 401 vs 801 nodes', alpha_401, real(r%resistivity(), R8P), rel_tol=1.e-4_R8P)

call assert_summary()

contains
   function str(x) result(s)
   !< Short real-to-string conversion for labels.
   real(R8P), intent(in) :: x !< Value.
   character(len=16)     :: s !< String.

   write(s, '(G0.3)') x
   endfunction str
endprogram test_conventional
