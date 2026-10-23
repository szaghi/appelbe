par%z_i = 1._R8P ; par%z_a = 6._R8P ; par%mass_ratio = m_e / m_carbon12
par%n_ratio = paper_n_ratio                            ! the paper keeps F0 with n_a/n_e = 1e-3
print '(A)', '  v_a/v_Te   converged   paper grid'
do k = 1, 3                                            ! the first three samples of the paper's Fig. 2
   par%u_a = paper_fig2_speed(k)
   call op%init(par=par)                               ! converged: 401 nodes, one on u_a
   r = op%response(omega_tau=0._R8P)
   write(*, '(F10.4,F12.4)', advance='no') par%u_a, real(r%j_nu)
   call init_paper(op, par)                            ! the paper's grid: 199 nodes on [0, 5], none on u_a
   r = op%response(omega_tau=0._R8P)
   print '(F13.4)', real(r%j_nu)
enddo
