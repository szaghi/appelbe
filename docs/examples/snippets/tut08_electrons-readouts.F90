t   = slope_temperature(bip)                                                 ! ECE, optically thick
win = sqrt(2._R8P) * bip%grid%u >= 1._R8P .and. sqrt(2._R8P) * bip%grid%u <= 4._R8P
print '(A,2F8.4)', 'TS fit (w <= 2, w <= 3)      : ', ts_temperature(bip, 2._R8P), ts_temperature(bip, 3._R8P)
print '(A,F8.4)',  'energy moment (2/3)<u^2>     : ', kinetic_temperature(bip)
print '(A,2F8.4)', 'ECE slope temperature, range : ', minval(t, mask=win), maxval(t, mask=win)
