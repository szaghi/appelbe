---
title: Using the GUI
---

# Using appelbe-gui

appelbe-gui takes an electron distribution f₀ (a Maxwellian, the bipolar distortion of the ICFDT slides, or a table
from INDACO) and shows what Thomson scattering (TS) and ECE read from it, and how it changes electron transport and the
current and heat flow that fusion alphas induce. Every number comes from the appelbe library, the code behind the
driver `appelbe_electrons` and the report; the program adds no physics of its own.

This page is also the program's **Help** window. To install the program, see [Install the GUI](gui-install).

![The Electron f0 panel: a bipolar distortion against the Maxwellians at T_e and at T_kin](/gui/f0.png)

## The window

The window has six panels. **Inputs** is on the left; the others are tabs on the right, and any panel can be dragged
out, docked elsewhere or put side by side.

| Panel | What it shows | When it updates |
|---|---|---|
| Inputs | f₀, the plasma, the fast ions, the speed grid | — |
| Electron f0 | f₀ and the two Maxwellians it is compared with, log scale | at once |
| Diagnostics | the TS and ECE temperatures, the size of the distortion, the TS spectrum | at once |
| Transport | the change of σ, β, κ and of the alpha current and heat flow | on **Solve** |
| Scans | one parameter of the bipolar f₀ varied over a range | on **Run scan** |
| Help | this page | — |

Units: speeds are u_L = p / sqrt(m_e T_e) (the slides' units; the library's u = v / v_Te is u_L / sqrt(2)); every
temperature is in units of the T_e you set; σ, κ and the transport coefficients are in Epperlein–Haines units; changes
are relative, in %.

## Compare a distorted f₀ with a Maxwellian

1. In **Inputs**, keep *Bipolar distortion* and set **A**, **u_0** and **w**: f₀ = f_M [1 + A x exp(−x²/2)] with
   x = (u_L − u_0) / w. Type a value and press Enter (or click elsewhere).
2. **Electron f0** redraws at once: f₀, the Maxwellian at T_e, and the Maxwellian of the **same energy** (T = T_kin,
   the temperature of f₀'s mean energy).
3. **Diagnostics** shows the two TS temperatures (a Gaussian fitted to the TS spectrum on w ≤ 2 and on w ≤ 3), T_kin,
   and the range of the ECE slope temperature on 1 ≤ u_L ≤ 4; then the peaks of δf/f and δf′/f′ against both
   Maxwellians.

![The Diagnostics panel: the TS and ECE temperatures, the distortion against both Maxwellians, the ECE slope temperature and the TS spectrum with its fits](/gui/diagnostics.png)

Why two Maxwellians: a distortion usually changes the energy of the electrons a little. Against the Maxwellian at T_e
every quantity then also moves because the temperature moved (σ grows as T^3/2). Against the Maxwellian of the same
energy only the **shape** of f₀ is left. Read the *vs T_kin* columns for the effect of the shape.

## Load an INDACO table

1. **File → Open f0 table...** (or *Table (file)* in Inputs, then **Open table...**).
2. Choose a text file with two columns: **u_L** and **f0**, from u_L = 0 upwards, increasing; lines starting with `#`
   are comments, blank lines are skipped. f₀ may have any normalisation (it is normalised to unit density).
3. The table is interpolated with a smooth spline of ln f₀ (zero slope at u_L = 0) and continued as a straight line in
   ln f₀ beyond its last row.

The example `examples/f0_two_temperature.dat` (in the program's folder) is a Maxwellian with 5% of electrons at
1.5 T_e.

**f₀ must vanish at the end of the grid.** The grid ends at u_max = 7 (u_L ≈ 9.9) by default; f₀ there must be below
10⁻¹² of its peak. A table with a hot tail fails with *electron distribution does not vanish at u_max*: raise
**u_max** in Inputs until the message goes (a tail at a few T_e needs u_max of 8 to 10), and raise **nodes** with
it to keep the resolution.

## Transport and the alpha closure

1. Open **Transport** and press **Solve**. The solve runs in the background (a few seconds at 801 nodes): the bar
   shows its progress, **Cancel** stops it, and the window stays usable.
2. The first table gives the change of σ, κ, j_ν (the alpha-induced current) and ζ_ν (the alpha-induced heat flow), in
   %: signed at ωτ = 0; of the modulus at the **omega tau** set above the table (1 by default); and, in the last row,
   against the Maxwellian of the same energy at ωτ = 0.
3. Below, choose a **quantity** (σ, β, κ, j_ν, ζ_ν) and its component (**perp**: along the drive; **wedge**: along
   b × drive) to plot it against ωτ for f₀ and for both Maxwellians, with the change of its modulus.
4. **f1 for a unit drive** shows the first-order distribution that each drive (the electric field, the temperature
   gradient, the alpha flux) produces, for f₀ and for the Maxwellian.

![The Transport panel after Solve: the changes against the Maxwellians, j_ν against ωτ, and the change of its modulus](/gui/transport.png)

If you change an input after a solve, the panel says so (*the inputs changed since this solve*): press **Solve**
again. A cancelled solve leaves the previous one on screen.

The fast ions are 3.45 MeV alphas by default, at n_α/n_e = 10⁻³ (the value the paper's own runs used). Other species
are in **Inputs → species** (*custom* takes any charge, mass and energy). The speed of the fast ions relative to the
electrons, v_a/v_Te, is shown under them.

## Run a scan

1. Open **Scans** and choose the parameter of the bipolar f₀: **A**, **u_0** or **w**. The others keep their values
   in Inputs.
2. Set the range (**from**, **to**) and the number of **values**; the defaults are those of `appelbe_electrons`.
3. Press **Run scan**: one solve per value, in the background, with its progress.
4. Choose what to **show** against the parameter: a temperature, the ECE–TS distance, whether f₀ decreases
   monotonically (ECE reads no temperature where it does not), or a change of a transport coefficient.

![The Scans panel: a scan of the width w, the change of κ against the Maxwellian of the same energy](/gui/scans.png)

## Save, export, send

- **File → Export**: the f₀ profile, the f1 profiles, the readouts, the ωτ sweep or the scan, as `.dat` tables (a
  `#` header line naming the columns, then the rows): gnuplot, Python, or a spreadsheet read them. With the default
  inputs they are the files of `appelbe_electrons` exactly.
- **File → Save a plot as PNG**: any plot on screen (bring its tab to the front first).
- **File → Save session...** writes every input to a `.ses` text file, the rows of a table included. Whoever opens it
  (**File → Open session...**, or `appelbe-gui case.ses`) gets the same inputs, and so the same numbers, on any
  machine. To ask a question about a result, send the session.

## When something goes wrong

Inputs the computation cannot take are reported in red under Inputs, and the program keeps running:

| Message | Meaning, and what to do |
|---|---|
| *electron distribution negative somewhere* | f₀ < 0 somewhere: the bipolar f₀ with \|A\| above about 1.6, or a table with a negative value |
| *electron distribution does not vanish at u_max* | raise **u_max** (and **nodes**) |
| *n_nodes must be odd and >= 7* | the grid needs an odd number of nodes |
| *u_a under-resolved* | the fast ions are slower than four cells of the grid: raise **nodes** |
| *u_a beyond the grid* | the fast ions are faster than u_max (a cold plasma, an energetic beam): raise **u_max** |
| *read_table: cannot read two numbers from ..., line N* | line N of the table is not two numbers |

If the program misbehaves, run it from a terminal with `--self-test`: it checks every panel, a solve, a scan and a
picture without opening a window, and names what fails. If the window stays black (an old graphics driver), run
`appelbe-gui --remote 8080` and open the address it prints in a web browser.

## What the model assumes

- **f₀ is prescribed, not solved for.** A distorted f₀ is not a steady state of electron–electron collisions: something
  (alpha heating, RF) must maintain it, and that source is not modelled.
- **Non-relativistic.** The collision operator and u_L = p / sqrt(m_e T_e) are non-relativistic; the slides compare
  with a Maxwell–Jüttner base.
- **The temperature-gradient drive assumes f₀ keeps its shape as T_e varies** (a feature that moves with T_e).
- **Onsager reciprocity holds only for the Maxwellian**: with a distorted f₀ the two thermoelectric coefficients
  differ at first order in the distortion (−1.8% at A = 0.1, w = 0.5).
- **The ECE readout is the local slope temperature** −2u f₀ / f₀′: an optically thick plasma and a narrow resonance,
  not a model of a real ECE channel.

The physics, the equations and the validation are in the online documentation, *Non-Maxwellian electrons*.
