# Fig. 5: heat flow per unit alpha flux and keV versus log10(omega tau), flux orthogonal to B (Eqs. 34-35).
# Lines: kinetic closure; points: Appendix C fits.
set terminal pngcairo size 800,1000 font ",11"
set output 'results/fig5.png'
set multiplot layout 2,1
set xlabel 'log_{10} {/Symbol w}{/Symbol t}'
set xrange [-3:3]
set ylabel 'q_{e{/Symbol \136}} (W s keV^{-1})'
set key top left
plot 'results/fig5_Te01keV.dat' u 1:2 w l lw 2 lc rgb 'blue'       t 'T_e = 1 keV', \
     'results/fig5_Te15keV.dat' u 1:2 w l lw 2 lc rgb 'dark-green' t 'T_e = 15 keV', \
     'results/fig5_Te01keV.dat' every 3 u 1:4 w p pt 6 lc rgb 'blue'       t 'algebraic fits', \
     'results/fig5_Te15keV.dat' every 3 u 1:4 w p pt 6 lc rgb 'dark-green' notitle
set ylabel 'q_{e{/Symbol \331}} (W s keV^{-1})'
set key bottom left
plot 'results/fig5_Te01keV.dat' u 1:3 w l lw 2 lc rgb 'blue'       t 'T_e = 1 keV', \
     'results/fig5_Te15keV.dat' u 1:3 w l lw 2 lc rgb 'dark-green' t 'T_e = 15 keV', \
     'results/fig5_Te01keV.dat' every 3 u 1:5 w p pt 6 lc rgb 'blue'       t 'algebraic fits', \
     'results/fig5_Te15keV.dat' every 3 u 1:5 w p pt 6 lc rgb 'dark-green' notitle
unset multiplot
