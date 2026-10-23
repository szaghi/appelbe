# Figures of the documentation site: this work against the paper, as SVG in docs/public/figures/.
# Needs results/ (fobis rule --ex figures) and report/generated/ (python3 scripts/report_numbers.py).
# Run from the repository root: gnuplot scripts/docs_figures.gp
set terminal svg size 720,440 dynamic enhanced font 'Helvetica,13' background rgb 'white'
set border lw 1.2
set grid lc rgb '#dddddd'
set key spacing 1.2
paper = "pt 6 ps 0.7"
R = 'results/'
D = 'report/data/'
G = 'report/generated/'

# Fig. 1: f1 at 2 keV
set output 'docs/public/figures/fig1.svg'
set xlabel 'v/v_{Te}' ; set ylabel 'electron distribution (normalised)'
set xrange [0:3] ; set yrange [-1.3:1.1] ; set key bottom right
plot R.'fig1.dat' u 1:2 w l dt 3 lc rgb 'black' t 'f_0', \
     R.'fig1.dat' u 1:3 w l lw 2 lc rgb '#1f4fd8' t 'f_1, {/Symbol w}{/Symbol t} = 0', \
     R.'fig1.dat' u 1:4 w l lw 2 lc rgb '#d81f1f' t 'f_{1}^{perp}, {/Symbol w}{/Symbol t} = 10', \
     R.'fig1.dat' u 1:5 w l lw 2 lc rgb '#1f8a3a' t 'f_{1}^{wedge}, {/Symbol w}{/Symbol t} = 10', \
     R.'fig1_paper.dat' u 1:4 w l lw 2 dt 2 lc rgb '#d81f1f' t 'f_{1}^{perp}, paper grid', \
     D.'paper_fig1_f1_wt0.dat' every 6 u 1:2 w p @paper lc rgb '#1f4fd8' t 'paper', \
     D.'paper_fig1_f1perp_wt10.dat' every 4 u 1:2 w p @paper lc rgb '#d81f1f' notitle, \
     D.'paper_fig1_f1wedge_wt10.dat' every 6 u 1:2 w p @paper lc rgb '#1f8a3a' notitle

# Fig. 2: unmagnetised current ratio
set output 'docs/public/figures/fig2.svg'
set logscale x ; set xrange [0.1:3] ; set yrange [-7:1] ; set key bottom left
set xlabel 'v_{/Symbol a}/v_{Te}' ; set ylabel 'j^0_{e{/Symbol a}} / j^0_{/Symbol a}'
plot R.'fig2.dat' u 1:5 w l lw 2 lc rgb '#0aa5b5' t 'proton', \
     R.'fig2.dat' u 1:6 w l lw 2 lc rgb '#c41ec4' t '{/Symbol a}', \
     R.'fig2.dat' u 1:7 w l lw 2 lc rgb 'black' t 'C^{6+}', \
     R.'fig2.dat' u 1:4 w l lw 1 dt 2 lc rgb 'black' t 'C^{6+}, n_{/Symbol a}/n_e = 0', \
     D.'paper_fig2_proton.dat' every 2 u 1:2 w p @paper lc rgb '#0aa5b5' t 'paper', \
     D.'paper_fig2_alpha.dat' every 2 u 1:2 w p @paper lc rgb '#c41ec4' notitle, \
     D.'paper_fig2_carbon.dat' every 2 u 1:2 w p @paper lc rgb 'black' notitle
unset logscale x

# Fig. 3: the magnetised closure (top: current, bottom: heat flow)
set xrange [-3:3] ; set xlabel 'log_{10} {/Symbol w}{/Symbol t}'
do for [panel in "j zeta"] {
   set output sprintf('docs/public/figures/fig3_%s.svg', panel)
   if (panel eq "j") { set yrange [-1.5:1.1] ; set ylabel 'j^0_{e{/Symbol a}} / j^0_{/Symbol a}' ; set key top left ; c = 2 } \
   else { set yrange [-0.5:15] ; set ylabel '{/Symbol z}_{e{/Symbol a}} / (n_{/Symbol a} <v_{/Symbol a}> T_e)' ; set key top right ; c = 4 }
   plot R.'fig3_paper_v1.000.dat' u 1:c w l lw 2 lc rgb '#1f4fd8' t 'v_{/Symbol a}/v_{Te} = 1', \
        R.'fig3_paper_v0.333.dat' u 1:c w l lw 2 lc rgb '#d81f1f' t '1/3', \
        R.'fig3_paper_v0.200.dat' u 1:c w l lw 2 lc rgb '#0aa5b5' t '0.2', \
        R.'fig3_paper_v0.050.dat' u 1:c w l lw 2 lc rgb 'black' t '0.05', \
        R.'fig3_paper_v1.000.dat' u 1:c+1 w l lw 2 dt 2 lc rgb '#1f4fd8' notitle, \
        R.'fig3_paper_v0.333.dat' u 1:c+1 w l lw 2 dt 2 lc rgb '#d81f1f' notitle, \
        R.'fig3_paper_v0.200.dat' u 1:c+1 w l lw 2 dt 2 lc rgb '#0aa5b5' notitle, \
        R.'fig3_paper_v0.050.dat' u 1:c+1 w l lw 2 dt 2 lc rgb 'black' notitle, \
        D.sprintf('paper_fig3_%s_perp_v1.dat', panel) every 8 u 1:2 w p @paper lc rgb '#1f4fd8' t 'paper', \
        D.sprintf('paper_fig3_%s_perp_v0.33.dat', panel) every 8 u 1:2 w p @paper lc rgb '#d81f1f' notitle, \
        D.sprintf('paper_fig3_%s_wedge_v1.dat', panel) every 3 u 1:2 w p pt 8 ps 0.7 lc rgb '#1f4fd8' notitle, \
        D.sprintf('paper_fig3_%s_wedge_v0.33.dat', panel) every 3 u 1:2 w p pt 8 ps 0.7 lc rgb '#d81f1f' notitle
}

# Fig. 4: unmagnetised heat flow
set output 'docs/public/figures/fig4.svg'
set xrange [1:15] ; set yrange [-2e-14:3e-14] ; set key top left
set xlabel 'T_e [keV]' ; set ylabel 'q_e / (n_{/Symbol a} <v_{/Symbol a}>) [W s]'
plot R.'fig4.dat' u 1:2 w l lw 2 lc rgb '#1f4fd8' t 'j^0_{e{/Symbol a}} heat flow', \
     R.'fig4.dat' u 1:3 w l lw 2 lc rgb '#1f8a3a' t '{/Symbol z}_{e{/Symbol a}} heat flow', \
     R.'fig4.dat' u 1:4 w l lw 2 lc rgb '#d81f1f' t 'sum', \
     R.'fig4.dat' u 1:5 w l dt 2 lc rgb '#1f4fd8' t 'algebraic closure', \
     R.'fig4.dat' u 1:6 w l dt 2 lc rgb '#1f8a3a' notitle, \
     R.'fig4.dat' u 1:7 w l dt 2 lc rgb '#d81f1f' notitle, \
     D.'paper_fig4_q_j.dat' every 12 u 1:2 w p @paper lc rgb '#1f4fd8' t 'paper', \
     D.'paper_fig4_q_zeta.dat' every 12 u 1:2 w p @paper lc rgb '#1f8a3a' notitle, \
     D.'paper_fig4_q_sum.dat' u 1:2 w p @paper lc rgb '#d81f1f' notitle

# Fig. 5: magnetised heat flow, along the flux and along b x flux
set xrange [-3:3] ; set xlabel 'log_{10} {/Symbol w}{/Symbol t}'
do for [comp in "perp wedge"] {
   set output sprintf('docs/public/figures/fig5_%s.svg', comp)
   if (comp eq "perp") { set yrange [5e-16:9e-16] ; set key bottom right ; c = 2 ; set ylabel 'q_e^{perp} [W s keV^{-1}]' } \
   else { set yrange [-1.1e-16:2e-17] ; set key bottom right ; c = 3 ; set ylabel 'q_e^{wedge} [W s keV^{-1}]' }
   plot G.'fig5_paper_Te01keV.dat' u 1:c w l lw 2 lc rgb '#1f4fd8' t '1 keV, paper numerics', \
        G.'fig5_paper_Te15keV.dat' u 1:c w l lw 2 lc rgb '#1f8a3a' t '15 keV, paper numerics', \
        R.'fig5_Te01keV.dat' u 1:c w l lw 1.5 dt 3 lc rgb '#1f4fd8' t 'exact {/Symbol b}', \
        R.'fig5_Te15keV.dat' u 1:c w l lw 1.5 dt 3 lc rgb '#1f8a3a' notitle, \
        D.sprintf('paper_fig5_%s_Te1keV.dat', comp) every 8 u 1:2 w p @paper lc rgb '#1f4fd8' t 'paper', \
        D.sprintf('paper_fig5_%s_Te15keV.dat', comp) every 8 u 1:2 w p @paper lc rgb '#1f8a3a' notitle
}

# Fig. 6: coefficients with an isotropic alpha population
set output 'docs/public/figures/fig6.svg'
set logscale x ; set xrange [1e-4:1e-1] ; set yrange [0.8:1.0] ; set key bottom left
set xlabel 'n_{/Symbol a}/n_e' ; set ylabel 'normalised coefficient'
plot R.'fig6.dat' u 1:2 w l lw 2 lc rgb '#1f4fd8' t 'K_{||}, 1 keV', \
     R.'fig6.dat' u 1:4 w l lw 2 lc rgb '#d81f1f' t '5 keV', \
     R.'fig6.dat' u 1:6 w l lw 2 lc rgb 'black' t '10 keV', \
     R.'fig6.dat' u 1:3 w l lw 2 dt 2 lc rgb '#1f4fd8' t '{/Symbol m}_{||}', \
     R.'fig6.dat' u 1:5 w l lw 2 dt 2 lc rgb '#d81f1f' notitle, \
     R.'fig6.dat' u 1:7 w l lw 2 dt 2 lc rgb 'black' notitle, \
     D.'paper_fig6_K_1keV.dat' every 10 u 1:2 w p @paper lc rgb '#1f4fd8' t 'paper', \
     D.'paper_fig6_K_5keV.dat' every 10 u 1:2 w p @paper lc rgb '#d81f1f' notitle, \
     D.'paper_fig6_K_10keV.dat' every 10 u 1:2 w p @paper lc rgb 'black' notitle
unset logscale x

# Non-Maxwellian electrons (appelbe_electrons): the reference distortion A = 0.1, u_0 = 2, w = 0.25
set output 'docs/public/figures/electrons_profile.svg'
set xrange [0:4] ; set yrange [-0.25:0.3] ; set key top right
set xlabel 'u_L = p / (m_e T_e)^{1/2}' ; set ylabel 'relative deviation from the Maxwellian'
plot R.'electrons_profile.dat' u 2:6 w l lw 2 lc rgb '#1f4fd8' t 'f_0 / f_M - 1  (Thomson scattering)', \
     R.'electrons_profile.dat' u 2:7 w l lw 2 lc rgb '#d81f1f' t "f_0' / f_M' - 1  (ECE absorption)", \
     R.'electrons_profile.dat' u 2:($8-1) w l lw 2 dt 2 lc rgb 'black' t 'T_{slope} / T_e - 1'

# width scan (A = 0.1, u_0 = 2): readouts, and the change of transport against the equal-energy Maxwellian
set output 'docs/public/figures/electrons_readouts.svg'
set xrange [0.1:1] ; set yrange [0.7:2.1] ; set key top right
set xlabel 'w' ; set ylabel 'T / T_e'
plot R.'electrons_scan_w.dat' u 1:2 w lp pt 7 ps 0.5 lw 2 lc rgb '#1f4fd8' t 'T_{TS}, fit on w <= 2', \
     R.'electrons_scan_w.dat' u 1:4 w l lw 2 dt 2 lc rgb '#1f4fd8' t 'T_{kin} = (2/3)<u^2>', \
     R.'electrons_scan_w.dat' u 1:5 w lp pt 7 ps 0.5 lw 2 lc rgb '#d81f1f' t 'T_{slope}, min and max on 1 <= u_L <= 4', \
     R.'electrons_scan_w.dat' u 1:6 w lp pt 7 ps 0.5 lw 2 lc rgb '#d81f1f' notitle
set output 'docs/public/figures/electrons_transport.svg'
set yrange [-0.08:0.06] ; set key bottom left
set ylabel 'relative change, {/Symbol w}{/Symbol t} = 0'
plot R.'electrons_scan_w.dat' u 1:9  w l lw 2 lc rgb '#1f4fd8' t '{/Symbol s}', \
     R.'electrons_scan_w.dat' u 1:10 w l lw 2 lc rgb '#d81f1f' t '{/Symbol k}', \
     R.'electrons_scan_w.dat' u 1:11 w l lw 2 lc rgb '#1f8a3a' t 'j_{/Symbol n}', \
     R.'electrons_scan_w.dat' u 1:12 w l lw 2 lc rgb '#c41ec4' t '{/Symbol z}_{/Symbol n}', \
     R.'electrons_scan_w.dat' u 1:17 w l lw 2 dt 2 lc rgb '#1f4fd8' t 'dashed: against the Maxwellian at T_{kin}', \
     R.'electrons_scan_w.dat' u 1:18 w l lw 2 dt 2 lc rgb '#d81f1f' notitle, \
     R.'electrons_scan_w.dat' u 1:19 w l lw 2 dt 2 lc rgb '#1f8a3a' notitle, \
     R.'electrons_scan_w.dat' u 1:20 w l lw 2 dt 2 lc rgb '#c41ec4' notitle
