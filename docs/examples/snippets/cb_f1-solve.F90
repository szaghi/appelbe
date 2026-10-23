rhs = reshape(op%source_fast_flux(), [op%grid%n, 1])   ! one right-hand side, on the full grid
f1  = op%solve(omega_tau=10._R8P, rhs=rhs)            ! (G + i wt) f1 = g7, f1 = f1x + i f1y
