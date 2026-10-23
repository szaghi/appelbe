!< Set-up of the paper's own calculations, inferred from its figures (not stated in the paper).
module appelbe_paper
!< Set-up of the paper's own calculations, inferred from its figures (not stated in the paper).
!<
!< - Velocity grid: u in [0, 5] with N = 199 nodes (h = 5/198 = 0.02525), no node at u_a. The data points of the paper's
!<   Fig. 1 are spaced by 0.0253; the depth of the negative lobe of its f1_perp, an O(h) artefact of the unaligned grid,
!<   pins h to 0.02525-0.0253. The same grid, with no further adjustment, removes the residuals of Fig. 2 (all three
!<   species, 5-7x), Fig. 3 (v_a/v_Te = 1, 1/3, 0.2) and Fig. 5 (1 keV, 6x). u_max = 10 with N = 397 is equivalent.
!< - The fast-ion runs keep an isotropic F0 with n_a/n_e = 1e-3 in the operator (the hotspot value of Sec. V A). On the
!<   paper's grid Fig. 2 then matches for protons, alphas and carbon at once (carbon RMS 0.0014; 0.04 at 0.8e-3 or
!<   1.2e-3, 0.21 at 0).
!< - Fig. 2 was computed at 25 temperatures equally spaced from 1 to 100 (in units of the temperature at v_a = v_Te), i.e.
!<   v_a/v_Te = 1/sqrt(1 + 99 (k-1)/24), joined by straight lines: there is no sample between v_a/v_Te = 0.44 and 1.
!< - The speeds labelled 0.33 in Fig. 3 and in Tables I-IV are 1/3.
!< - Fig. 5 uses the Epperlein-Haines fitted thermoelectric tensor (Phys. Fluids 29, 1029 (1986), Table III); it is
!<   evaluated in scripts/report_numbers.py, since the kinetic solver gives the exact one.
use penf,            only : I4P, R8P
use appelbe_kinetic, only : kinetic_operator, kinetic_params

implicit none
private
public :: paper_n_ratio, paper_n_nodes, paper_u_max, paper_fig2_samples, paper_fig3_speeds
public :: paper_fig2_speed, init_paper

real(R8P),    parameter :: paper_n_ratio      = 1.e-3_R8P !< n_a/n_e of the isotropic F0 in the paper's fast-ion runs.
integer(I4P), parameter :: paper_n_nodes      = 199_I4P   !< Nodes of the paper's speed grid.
real(R8P),    parameter :: paper_u_max        = 5._R8P    !< Extent of the paper's speed grid.
integer(I4P), parameter :: paper_fig2_samples = 25_I4P    !< Number of samples of the paper's Fig. 2.
real(R8P),    parameter :: paper_fig3_speeds(4) = [1._R8P, 1._R8P / 3._R8P, 0.2_R8P, 0.05_R8P] !< Fig. 3 legend.

contains
   pure function paper_fig2_speed(k) result(v)
   !< v_a/v_Te of the k-th sample (1..25) of the paper's Fig. 2, equally spaced in temperature.
   integer(I4P), intent(in) :: k !< Sample index.
   real(R8P)                :: v !< v_a / v_Te.

   v = 1._R8P / sqrt(1._R8P + 99._R8P * real(k - 1_I4P, R8P) / real(paper_fig2_samples - 1_I4P, R8P))
   endfunction paper_fig2_speed

   subroutine init_paper(op, par)
   !< Initialise an operator on the paper's grid (emulation of its discretisation, including its O(h) error).
   type(kinetic_operator), intent(inout) :: op  !< Operator.
   type(kinetic_params),   intent(in)    :: par !< Physical parameters.

   call op%init(par=par, n_nodes=paper_n_nodes, u_max=paper_u_max, align=.false.)
   endsubroutine init_paper
endmodule appelbe_paper
