!< Footnote 30: a fast-ion population with an energy spread against the monoenergetic one at the same mean energy.
program appelbe_footnote30
!< Footnote 30: a fast-ion population with an energy spread against the monoenergetic one at the same mean energy.
!<
!< The paper states (footnote 30, no data shown) that j0_ea and zeta_ea of a broad energy distribution agree to about 1%
!< with those of a monoenergetic one whose v_a comes from the mean energy, at the same drift velocity. Alphas in DT; F1 has
!< the shape of F0. Since j_nu and zeta_nu are per unit fast-ion flux, equal drift velocities are built in: the comparison
!< is j_nu(broad) against j_nu(monoenergetic at u_energy). Spectra: Gaussian and flat in energy (logistic edges 0.1 E_0 wide) of several
!< widths, and the classical slowing-down distribution (u_c^3 = 3 sqrt(pi)/4 m_e/m_DT for DT), which is not "a broad
!< range of energies" around a mean but the physical one for fusion alphas.
use, intrinsic :: iso_fortran_env, only : output_unit
use penf,                          only : I4P, R8P
use appelbe_constants,             only : sqrt_pi, m_e, m_alpha, m_DT
use appelbe_distributions,         only : energy_gaussian, energy_flat, slowing_down
use appelbe_io,                    only : open_results
use appelbe_kinetic,               only : kinetic_params, kinetic_operator, kinetic_response
use appelbe_paper,                 only : paper_n_ratio

implicit none
type(kinetic_params)    :: par                                    !< Physical parameters.
type(kinetic_operator)  :: op, mono                               !< Operators of the broad and monoenergetic populations.
type(kinetic_response)  :: rb, rm                                 !< Broad and monoenergetic responses.
real(R8P)               :: u_energy, u_flux                       !< Mean-energy and flux speeds of the broad population.
integer(I4P)            :: i, k, l, unit                          !< Counters, output unit.
integer(I4P), parameter :: n_nodes = 801_I4P                      !< Speed nodes (1601 changes j, zeta by < 1e-5).
real(R8P),    parameter :: u_max = 6._R8P                         !< Grid extent.
real(R8P),    parameter :: u_0(3) = [0.25_R8P, 0.5_R8P, 1._R8P]   !< Spectrum centre (birth speed for slowing-down).
real(R8P),    parameter :: omega_tau(3) = [0._R8P, 1._R8P, 10._R8P] !< Hall parameters.
integer(I4P), parameter :: n_spectra = 5_I4P                      !< Number of spectra.
character(len=16)       :: label(n_spectra) = [character(16) :: 'gauss_0.2', 'gauss_0.4', 'flat_0.3', 'flat_0.6', &
                                                                'slowing_down'] !< Spectrum labels.
real(R8P)               :: p(3)                                   !< Spectrum parameters.

par%z_i        = 1._R8P
par%z_a        = 2._R8P
par%mass_ratio = m_e / m_alpha
par%n_ratio    = paper_n_ratio
unit = open_results('footnote30.dat', 'spectrum u_0 u_energy u_flux omega_tau Re_j_broad Im_j_broad Re_j_mono Im_j_mono '// &
                    'Re_zeta_broad Im_zeta_broad Re_zeta_mono Im_zeta_mono')
do k = 1_I4P, size(u_0, kind=I4P)
   do l = 1_I4P, n_spectra
      par%u_a = u_0(k)
      select case (l)
      case (1_I4P, 2_I4P)
         p = [u_0(k), 0.2_R8P * real(l, R8P), 0._R8P]
         call op%init(par=par, n_nodes=n_nodes, u_max=u_max, distribution=energy_gaussian, shape_params=p)
      case (3_I4P, 4_I4P)
         p = [u_0(k), 0.3_R8P * real(l - 2_I4P, R8P), 0.1_R8P]  ! logistic edges 0.1 E_0 wide, resolved by the grid
         call op%init(par=par, n_nodes=n_nodes, u_max=u_max, distribution=energy_flat, shape_params=p)
      case default
         p = [u_0(k), (0.75_R8P * sqrt_pi * m_e / m_DT)**(1._R8P / 3._R8P), 0._R8P]
         call op%init(par=par, n_nodes=n_nodes, u_max=u_max, distribution=slowing_down, shape_params=p)
      endselect
      u_energy = op%u_energy
      u_flux   = op%u_flux
      par%u_a = u_energy
      call mono%init(par=par, n_nodes=n_nodes, u_max=u_max)
      do i = 1_I4P, size(omega_tau, kind=I4P)
         rb = op%response(omega_tau=omega_tau(i))
         rm = mono%response(omega_tau=omega_tau(i))
         write(unit, '(A,12ES15.6)') trim(label(l))//' ', u_0(k), u_energy, u_flux, omega_tau(i), rb%j_nu, rm%j_nu, &
                                     rb%zeta_nu, rm%zeta_nu
      enddo
   enddo
enddo
close(unit)
write(output_unit, '(A)') 'Footnote 30 written to results/footnote30.dat'
endprogram appelbe_footnote30
