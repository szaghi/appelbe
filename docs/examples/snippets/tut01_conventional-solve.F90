use appelbe

implicit none
type(kinetic_params)   :: par !< Physical parameters: thermal ions of charge Z_i, no fast ions (u_a = 0).
type(kinetic_operator) :: op  !< The discretised collision operator G of Eq. (13).
type(kinetic_response) :: r   !< Transport coefficients at one Hall parameter.

par%z_i = 1._R8P               ! a hydrogen-like plasma (D, T or DT)
call op%init(par=par)          ! 401 nodes on [0, 7 v_Te], the default grid
r = op%response(omega_tau=0._R8P)
