!< Physical constants (SI, CODATA 2018) used throughout the reproduction.
module appelbe_constants
!< Physical constants (SI, CODATA 2018) used throughout the reproduction.
use penf, only : R8P

implicit none
private
public :: pi, sqrt_pi
public :: e_charge, m_e, eps0, amu, keV_J, MeV_J
public :: m_proton, m_alpha, m_carbon12, m_DT

real(R8P), parameter :: pi         = acos(-1._R8P)          !< Pi.
real(R8P), parameter :: sqrt_pi    = sqrt(pi)               !< sqrt(pi).
real(R8P), parameter :: e_charge   = 1.602176634e-19_R8P    !< Elementary charge [C].
real(R8P), parameter :: m_e        = 9.1093837015e-31_R8P   !< Electron mass [kg].
real(R8P), parameter :: eps0       = 8.8541878128e-12_R8P   !< Vacuum permittivity [F/m].
real(R8P), parameter :: amu        = 1.66053906660e-27_R8P  !< Atomic mass unit [kg].
real(R8P), parameter :: keV_J      = 1.e3_R8P * e_charge    !< 1 keV [J].
real(R8P), parameter :: MeV_J      = 1.e6_R8P * e_charge    !< 1 MeV [J].
real(R8P), parameter :: m_proton   = 1.67262192369e-27_R8P  !< Proton mass [kg].
real(R8P), parameter :: m_alpha    = 6.6446573357e-27_R8P   !< Alpha-particle mass [kg].
real(R8P), parameter :: m_carbon12 = 12._R8P * amu - 6._R8P * m_e !< Fully ionised C-12 nucleus mass [kg].
real(R8P), parameter :: m_DT       = 0.5_R8P * (2.013553212745_R8P + 3.01550071621_R8P) * amu !< Mean D-T ion mass [kg].
endmodule appelbe_constants
