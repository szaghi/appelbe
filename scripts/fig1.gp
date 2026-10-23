# Fig. 1: electron f1 driven by 3.45 MeV alphas at T_e = 2 keV, each curve normalised by its maximum.
# Lines: kinetic solver; points: the paper's Fig. 1 (extracted from its vector graphics).
set terminal pngcairo size 800,600 font ",11"
set output 'results/fig1.png'
set xlabel 'v/v_{Te}'
set ylabel 'Electron dist. func.'
set xrange [0:3]
set yrange [-1.3:1.1]
set key bottom right
plot 'results/fig1.dat' u 1:2 w l dt 3 lc rgb 'black'      t 'f_0', \
     ''                 u 1:3 w l lw 2 lc rgb 'blue'       t 'f_1 ({/Symbol w}{/Symbol t} = 0)', \
     ''                 u 1:4 w l lw 2 lc rgb 'red'        t 'f_{1{/Symbol \^}} ({/Symbol w}{/Symbol t} = 10)', \
     ''                 u 1:5 w l lw 2 lc rgb 'dark-green' t 'f_{1{/Symbol \331}} ({/Symbol w}{/Symbol t} = 10)', \
     'report/data/paper_fig1_f1_wt0.dat'       every 6 u 1:2 w p pt 6 ps 0.6 lc rgb 'blue'       t 'paper', \
     'report/data/paper_fig1_f1perp_wt10.dat'  every 6 u 1:2 w p pt 6 ps 0.6 lc rgb 'red'        notitle, \
     'report/data/paper_fig1_f1wedge_wt10.dat' every 6 u 1:2 w p pt 6 ps 0.6 lc rgb 'dark-green' notitle
