!< Fig. 6 (Sec. VI): energy conductivity mu_par and thermal diffusion K_par versus n_a/n_e for an isotropic alpha population.
program appelbe_fig6
!< Fig. 6 (Sec. VI): energy conductivity mu_par and thermal diffusion K_par versus n_a/n_e for an isotropic alpha population.
!<
!< Monoenergetic 3.45 MeV alphas with F1 = 0: the isotropic F0 enters the operator of Eq. (13) (the g1-g3 terms) and
!< modifies the conventional coefficients. Values are normalised by those without alphas. Kinetic solver only: the
!< algebraic fits do not cover this effect. Convention: n_i = n_e / Z_i is held fixed as n_a varies (Sec. III).
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_constants,             only : m_e, m_alpha, keV_J, MeV_J
use appelbe_io,                    only : open_results
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_plasma,                only : speed_ratio

implicit none
type(kinetic_params)    :: par                                   !< Physical parameters.
type(kinetic_operator)  :: op                                    !< Kinetic operator.
type(kinetic_response)  :: r                                     !< Kinetic response.
real(R8P)               :: mu0, k0                               !< Reference coefficients without alphas.
real(R8P)               :: ratios(6)                             !< (K/K0, mu/mu0) for each temperature.
real(R8P)               :: n_ratio                               !< n_a / n_e.
integer(I4P)            :: k, i, unit                            !< Counters, output unit.
integer(I4P), parameter :: n_n = 31_I4P                          !< Number of density ratios.
real(R8P),    parameter :: e_alpha = 3.45_R8P * MeV_J            !< Alpha energy [J].
real(R8P),    parameter :: te_keV(3) = [1._R8P, 5._R8P, 10._R8P] !< Electron temperatures [keV].

par%z_i        = 1._R8P
par%z_a        = 2._R8P
par%mass_ratio = m_e / m_alpha
! without alphas the normalised coefficients do not depend on T_e
call op%init(par=par)
r   = op%response(omega_tau=0._R8P)
mu0 = real(r%mu, R8P)
k0  = real(r%thermal_diffusion, R8P)

unit = open_results('fig6.dat', 'na/ne K/K0(1keV) mu/mu0(1keV) K/K0(5keV) mu/mu0(5keV) K/K0(10keV) mu/mu0(10keV)')
do i = 1_I4P, n_n
   n_ratio = 10._R8P**(-4._R8P + 3._R8P * real(i - 1_I4P, R8P) / real(n_n - 1_I4P, R8P))
   do k = 1_I4P, size(te_keV, kind=I4P)
      par%u_a     = speed_ratio(e_alpha, m_alpha, te_keV(k) * keV_J)
      par%n_ratio = n_ratio
      call op%init(par=par)
      r = op%response(omega_tau=0._R8P)
      ratios(2*k-1) = real(r%thermal_diffusion, R8P) / k0
      ratios(2*k)   = real(r%mu, R8P) / mu0
   enddo
   write(unit, '(7ES15.6)') n_ratio, ratios
enddo
close(unit)
write(output_unit, '(A)') 'Fig. 6 written to results/fig6.dat'
endprogram appelbe_fig6
