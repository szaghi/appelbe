# Fig. 3: collisionally induced current and heat flow versus log10(omega tau), alphas in DT.
# Lines: kinetic solver (Eq. 13); points: Appendix C fits. Solid/filled = perp, dashed/open = wedge.
set terminal pngcairo size 800,1000 font ",11"
set output 'results/fig3.png'
set multiplot layout 2,1
set xlabel 'log_{10} {/Symbol w}{/Symbol t}'
set xrange [-3:3]
set key top left
files = 'fig3_v1.000.dat fig3_v0.330.dat fig3_v0.100.dat'
labels = '1 0.33 0.1'
set ylabel "j^0_{e{/Symbol a}} / j^0_{/Symbol a}"
plot for [i=1:3] 'results/'.word(files,i) u 1:2 w l lw 2 lc i t 'v_{/Symbol a}/v_{Te} = '.word(labels,i), \
     for [i=1:3] 'results/'.word(files,i) u 1:3 w l lw 2 dt 2 lc i notitle, \
     for [i=1:3] 'results/'.word(files,i) every 4 u 1:6 w p pt 7 ps 0.6 lc i notitle, \
     for [i=1:3] 'results/'.word(files,i) every 4 u 1:7 w p pt 6 ps 0.6 lc i notitle
set ylabel "{/Symbol z}_{e{/Symbol a}} / (T_e n_{/Symbol a} <v_{/Symbol a}>)"
set key top right
plot for [i=1:3] 'results/'.word(files,i) u 1:4 w l lw 2 lc i t 'v_{/Symbol a}/v_{Te} = '.word(labels,i), \
     for [i=1:3] 'results/'.word(files,i) u 1:5 w l lw 2 dt 2 lc i notitle, \
     for [i=1:3] 'results/'.word(files,i) every 4 u 1:8 w p pt 7 ps 0.6 lc i notitle, \
     for [i=1:3] 'results/'.word(files,i) every 4 u 1:9 w p pt 6 ps 0.6 lc i notitle
unset multiplot
