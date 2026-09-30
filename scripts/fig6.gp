# Fig. 6: mu_par (dashed) and K_par (solid) versus n_a/n_e for isotropic 3.45 MeV alphas, normalised to n_a = 0.
set terminal pngcairo size 800,600 font ",11"
set output 'results/fig6.png'
set logscale x
set format x '10^{%L}'
set xrange [1e-4:1e-1]
set yrange [0.8:1.0]
set xlabel 'n_{/Symbol a} / n_e'
set ylabel 'Normalized coefficients'
set key bottom left
plot 'results/fig6.dat' u 1:2 w l lw 2 lc rgb 'blue'  t 'T_e = 1 keV', \
     ''                 u 1:3 w l lw 2 dt 2 lc rgb 'blue'  notitle, \
     ''                 u 1:4 w l lw 2 lc rgb 'red'   t 'T_e = 5 keV', \
     ''                 u 1:5 w l lw 2 dt 2 lc rgb 'red'   notitle, \
     ''                 u 1:6 w l lw 2 lc rgb 'black' t 'T_e = 10 keV', \
     ''                 u 1:7 w l lw 2 dt 2 lc rgb 'black' notitle
