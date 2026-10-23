r  = op%response(omega_tau=1._R8P)                       ! (G + i wt) f1 = g7, the default
rp = op%response(omega_tau=1._R8P, method=method_paper)  ! (GG + W^2) f1 = ..., Appendix B
print '(/,A,ES9.2)', 'complex vs paper solver, |delta j_nu| = ', abs(r%j_nu - rp%j_nu)
