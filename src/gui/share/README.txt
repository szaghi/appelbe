appelbe-gui @VERSION@ (@PLATFORM@)
==============================================================================

A desktop program for non-Maxwellian electron distributions: choose an electron
f0 (a Maxwellian, the bipolar distortion, or a table from a file) and see what
Thomson scattering and ECE read from it, and how it changes electron transport
and the closure for fusion alphas (Appelbe et al., Phys. Plasmas 26, 102704,
2019). It needs nothing else installed.

@START@

The program
-----------
- Inputs (left): the f0, the plasma, the fast ions, the grid. Every change
  redraws the f0 panels at once.
- Electron f0, Diagnostics: f0 against the Maxwellians, the TS and ECE
  temperatures, the distortion, the TS spectrum.
- Transport: press Solve (a few seconds; Cancel stops it): the changes of the
  transport coefficients and of the alpha closure, against omega tau.
- Scans: vary A, u_0 or w of the bipolar f0, one solve per value.
- File: open an f0 table, open or save a session, export the results as .dat
  tables, save a plot as PNG.

A table is a text file with two columns, u_L = p / sqrt(m_e T_e) and f0, from
u_L = 0 upwards; lines starting with # are comments. examples/ holds one:
File > Open f0 table... > examples/f0_two_temperature.dat.

To send a result: File > Save session... writes every input (a table's rows
included) to a .ses file; whoever opens it (File > Open session...) gets the
same inputs and so the same numbers.

If the window does not open (an old graphics driver without OpenGL 3), run
"appelbe-gui --remote 8080" from a terminal and open the address it prints in a
web browser. "appelbe-gui --self-test" checks the program without a window.

Licence and sources
-------------------
appelbe is free software under the GNU General Public License v3
(licenses/appelbe/LICENSE.gpl3.md); its source code is at
https://github.com/szaghi/appelbe, the version of this program under the tag
v@VERSION@, and on request from the authors. It contains FIGURE (MIT) and the
libraries FIGURE builds in (Dear ImGui, ImPlot, cimgui, cimplot, miniz: MIT;
SDL3: zlib; IBM Plex fonts: OFL-1.1; Lucide icons: ISC; and the others listed
in licenses/figure/THIRD_PARTY.md), each licence under licenses/.
