# Non-Maxwellian electron f0 (appelbe_electrons): the reference profile and the three one-parameter scans.
set terminal pngcairo size 800,600 font ",11"
set grid

# reference case A = 0.1, u_0 = 2, w = 0.25: what TS (f) and ECE (df/du) see, against u_L = p / sqrt(m_e T_e)
set output 'results/electrons_profile.png'
set xrange [0:5]
set xlabel 'u_L = p / (m_e T_e)^{1/2}'
set ylabel 'relative deviation from the Maxwellian'
set key top right
plot 'results/electrons_profile.dat' u 2:6 w l lw 2 lc rgb 'blue'  t 'f_0/f_M - 1 (TS)', \
     ''                              u 2:7 w l lw 2 lc rgb 'red'   t "f_0'/f_M' - 1 (ECE absorption)", \
     ''                              u 2:($8-1) w l lw 2 dt 2 lc rgb 'black' t 'T_{slope}/T_e - 1'

# scans: TS and ECE readouts (left), change of transport and alpha closure at omega tau = 0 (right)
do for [s in 'A u0 w'] {
   set output sprintf('results/electrons_scan_%s.png', s)
   set multiplot layout 1,2
   unset xrange
   set xlabel (s eq 'u0' ? 'u_0' : s)
   set ylabel 'T / T_e'
   set key top left
   plot sprintf('results/electrons_scan_%s.dat', s) u 1:2 w lp pt 7 ps 0.6 lc rgb 'blue' t 'T_{TS} (w <= 2)', \
        ''                                         u 1:3 w lp pt 6 ps 0.6 lc rgb 'blue' t 'T_{TS} (w <= 3)', \
        ''                                         u 1:5 w lp pt 7 ps 0.6 lc rgb 'red'  t 'T_{slope} min', \
        ''                                         u 1:6 w lp pt 6 ps 0.6 lc rgb 'red'  t 'T_{slope} max'
   # solid: against the Maxwellian at T_e; dashed: against the Maxwellian of equal energy (T = T_kin)
   set ylabel 'relative change, omega tau = 0'
   plot sprintf('results/electrons_scan_%s.dat', s) u 1:9  w lp pt 7 ps 0.6 lc 1 t '{/Symbol s}', \
        ''                                         u 1:10 w lp pt 7 ps 0.6 lc 2 t '{/Symbol k}', \
        ''                                         u 1:11 w lp pt 7 ps 0.6 lc 3 t 'j_{/Symbol n}', \
        ''                                         u 1:12 w lp pt 7 ps 0.6 lc 4 t '{/Symbol z}_{/Symbol n}', \
        ''                                         u 1:17 w l dt 2 lw 2 lc 1 notitle, \
        ''                                         u 1:18 w l dt 2 lw 2 lc 2 notitle, \
        ''                                         u 1:19 w l dt 2 lw 2 lc 3 notitle, \
        ''                                         u 1:20 w l dt 2 lw 2 lc 4 notitle
   unset multiplot
}
