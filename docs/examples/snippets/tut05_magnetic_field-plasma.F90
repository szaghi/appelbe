te  = 5._R8P * keV_J                       ! hotspot: 5 keV
n_e = 1.e5_R8P / (2.5_R8P * amu)          ! 1e5 kg/m^3 of DT (2.5 amu per ion), n_e = n_i
lnl = coulomb_log_ei_nrl(n_e, te)
tau = tau_ei(te, n_e, 1._R8P, lnl)
print '(A,F6.2,A,ES10.3,A)', 'ln(Lambda_ei) = ', lnl, ',  tau_ei = ', tau, ' s'
