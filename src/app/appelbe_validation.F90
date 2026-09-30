!< Verification of the kinetic solver against exact and published transport coefficients (no fast ions).
program appelbe_validation
!< Verification of the kinetic solver against exact and published transport coefficients (no fast ions).
!<
!< Writes results/validation.dat, one quantity per row: key, computed value, reference value (0 when none).
!< - Lorentz gas (Z_i -> infinity): alpha = 3 pi/32, beta = 3/2, kappa = 128/(3 pi) (exact).
!< - Z_i = 1: Epperlein & Haines (1986) alpha_par = 0.5061, beta_par = 0.7029, kappa_par = 3.2031; Eq. (42) 0.506.
!< - Onsager relation tau = mu - (3/2) sigma (Eq. 22): largest relative violation over omega tau = 0..1e3.
!< - Grid convergence of alpha_par, beta_par, kappa_par (401 vs 1601 nodes).
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_constants,             only : pi
use appelbe_io,                    only : open_results
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response

implicit none
type(kinetic_params)    :: par       !< Physical parameters.
type(kinetic_operator)  :: op        !< Kinetic operator.
type(kinetic_response)  :: r, r_fine !< Responses.
real(R8P)               :: onsager   !< Largest Onsager violation.
integer(I4P)            :: i, unit   !< Counter, output unit.
real(R8P),    parameter :: omega_tau(6) = [0._R8P, 1.e-1_R8P, 1._R8P, 1.e1_R8P, 1.e2_R8P, 1.e3_R8P] !< Hall parameters.

unit = open_results('validation.dat', 'key value reference')

par%z_i = 1.e8_R8P
call op%init(par=par)
r = op%response(omega_tau=0._R8P)
call row('lorentz_alpha', real(r%resistivity(), R8P), 3._R8P * pi / 32._R8P)
call row('lorentz_beta',  real(r%beta(), R8P),        1.5_R8P)
call row('lorentz_kappa', real(r%kappa(), R8P),       128._R8P / (3._R8P * pi))

par%z_i = 1._R8P
call op%init(par=par)
r = op%response(omega_tau=0._R8P)
call row('z1_alpha_par',      real(r%resistivity(), R8P), 0.5061_R8P)
call row('z1_beta_par',       real(r%beta(), R8P),        0.7029_R8P)
call row('z1_kappa_par',      real(r%kappa(), R8P),       3.2031_R8P)
call row('z1_alpha_par_eq42', real(r%resistivity(), R8P), 0.506_R8P)

onsager = 0._R8P
do i = 1_I4P, size(omega_tau, kind=I4P)
   r = op%response(omega_tau=omega_tau(i))
   onsager = max(onsager, abs(r%tau - (r%mu - 1.5_R8P * r%sigma)) / abs(r%tau))
enddo
call row('onsager_max_rel_violation', onsager, 0._R8P)

r = op%response(omega_tau=0._R8P)
call op%init(par=par, n_nodes=1601_I4P)
r_fine = op%response(omega_tau=0._R8P)
call row('conv_alpha_par_401_vs_1601', abs(r%resistivity() - r_fine%resistivity()) / abs(r_fine%resistivity()), 0._R8P)
call row('conv_beta_par_401_vs_1601',  abs(r%beta() - r_fine%beta()) / abs(r_fine%beta()),                      0._R8P)
call row('conv_kappa_par_401_vs_1601', abs(r%kappa() - r_fine%kappa()) / abs(r_fine%kappa()),                   0._R8P)
close(unit)
write(output_unit, '(A)') 'Validation written to results/validation.dat'

contains
   subroutine row(key, value, reference)
   !< Write one validation row to the file and to stdout.
   character(*), intent(in) :: key       !< Quantity name.
   real(R8P),    intent(in) :: value     !< Computed value.
   real(R8P),    intent(in) :: reference !< Reference value (0 if none).

   write(unit, '(A,2ES17.8)') key, value, reference
   write(output_unit, '(A30,2ES17.8)') key, value, reference
   endsubroutine row
endprogram appelbe_validation
