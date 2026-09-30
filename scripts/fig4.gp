# Fig. 4: heat flow per unit alpha flux in an unmagnetised DT plasma, 3.45 MeV alphas (Eq. 33).
# Lines: kinetic closure; points: Appendix C fits.
set terminal pngcairo size 800,600 font ",11"
set output 'results/fig4.png'
set xlabel 'T_e (keV)'
set ylabel 'Normalized heat flows (W s)'
set xrange [1.5:15]
set key top left
plot 'results/fig4.dat' u 1:2 w l lw 2 lc rgb 'blue'      t "j^0_{e{/Symbol a}} heat flow", \
     ''                 u 1:3 w l lw 2 lc rgb 'dark-green' t "{/Symbol z}_{e{/Symbol a}} heat flow", \
     ''                 u 1:4 w l lw 2 dt 2 lc rgb 'red'   t 'sum', \
     ''                 every 4 u 1:5 w p pt 6 lc rgb 'blue'       t 'algebraic fits', \
     ''                 every 4 u 1:6 w p pt 6 lc rgb 'dark-green' notitle, \
     ''                 every 4 u 1:7 w p pt 6 lc rgb 'red'        notitle
