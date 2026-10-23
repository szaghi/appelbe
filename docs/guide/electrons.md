---
title: Non-Maxwellian electrons
---

# Non-Maxwellian electrons

The paper assumes a Maxwellian electron $f_0$ (its Eq. 4). appelbe lifts that assumption: `init` accepts any isotropic
$f_0(u)$, and Eq. (13) then gives the $f_1$, the transport coefficients and the α closure that go with it. The first use
is the ECE / Thomson-scattering (TS) temperature discrepancy studied by L. Senni et al. (ICFDT 2026, the INDACO code).
TS reads $f_0$ itself, while ECE absorption reads its derivative, so a small distortion of $f_0$ can be a large distortion
of what ECE sees.

## The operator for a general f₀

Shkarofsky's $C_{ee1}$ (Eq. A2) and $C_{e\alpha1}$ (Eq. A5) are written for any $f_0$. The paper substitutes the
Maxwellian only in its Eqs. (A8)–(A13); the general coefficients are

$$
\begin{aligned}
g_1 &= \frac{k_e}{3u}\,(I_2 + J_{-1}) + \dots, \qquad
g_2 = \frac{k_e}{3u^2}\,(3I_0 - I_2 + 2J_{-1}) + \dots,\\
g_3 &= -\frac{k_i}{u^3} + 8\pi k_e f_0 + \frac{k_e}{3u^3}\,(-3I_0 + I_2 - 2J_{-1}) + \dots,\\
g_4 &= 4\pi k_e\left(\frac{f_0''}{5u^4} - \frac{f_0'}{5u^5}\right),\qquad
g_5 = 4\pi k_e\,\frac{f_0'}{3u^3},\qquad
g_6 = 4\pi k_e\left(\frac{u f_0''}{5} + \frac{2 f_0'}{15}\right),
\end{aligned}
$$

where the dots are the fast-ion terms, which are unchanged. $I_0$, $I_2$, $J_{-1}$ are moments of $f_0$, computed by
quadrature on the grid. The drives are $g_7^E = -\tfrac12 f_0'$ for the electric field,
$g_7^T = -u(\tfrac32 f_0 + \tfrac12 u f_0')$ for the temperature gradient, and the fast-ion source of Eq. (A5) with
$f_0'$ and $f_0''$. For a Maxwellian these reduce term by term to the paper's forms.

| Distribution | Entity | Parameters |
|---|---|---|
| Maxwellian (closed forms, the default) | *no `electrons` argument* | — |
| Maxwellian at temperature T, through the general path | `electron_maxwellian` | `[T/T_e]` |
| Bipolar distortion of Senni et al. (Eq. 21) | `electron_bipolar` | `[A, u_0, w]`, momenta in $\sqrt{m_eT_e}$ |
| Any table, e.g. from INDACO | `electron_table`, `electron_table_params(x, f)`, `read_table` | $x = u_L = p/\sqrt{m_eT_e}$, f |

$f_0$ may have any normalisation (it is normalised to unit density on the grid). It must be smooth, because $f_0'$ and
$f_0''$ come from five-point differences of the function, and it must vanish at `u_max`. `electron_table` interpolates
$\ln f$ with a C² cubic spline, with zero slope at the origin, and continues it linearly beyond the last row.

Units: appelbe's $u = v/v_{Te}$ with $v_{Te} = \sqrt{2T_e/m_e}$. The slides use $u_L = p/\sqrt{m_eT_e} = \sqrt2\,u$
(non-relativistic). Every temperature below is in units of the reference $T_e$ that defines $u$.

## What the diagnostics read

`appelbe_eedf` reduces $f_0$ to the temperatures the diagnostics would report.

| Readout | Entity | Definition |
|---|---|---|
| TS spectrum | `ts_spectrum` | $S(w) = 2\pi\int_w^\infty f_0\,u\,du$, the projection of $f_0$ on the scattering vector (non-relativistic, incoherent) |
| TS temperature | `ts_temperature(op, w_max)` | least squares of $\ln S = c - w^2/T$ on $w \le w_{\max}$ |
| Energy moment | `kinetic_temperature` | $\tfrac23\langle u^2\rangle$ |
| ECE (optically thick) | `slope_temperature` | $T(u) = -2u f_0/f_0'$, the local log-slope at the resonant energy |

The ECE readout assumes an optically thick plasma and a narrow resonance, so that each channel samples a narrow band of
electron energies; it is not a forward model of a real ECE channel. It is degenerate near $u = 0$. A distortion that
reaches the origin (large $w$, small $u_0$) gives $f_0'(0) \ne 0$, and then $-2uf_0/f_0' \to 0$ whatever the distribution.
The scans therefore report it on $1 \le u_L \le 4$, that is for energies from $T_e/2$ to $8T_e$.

## The reference case

Senni et al. take $A = 0.1$, $u_0 = 2$, $w = 0.25$. The driver `appelbe_electrons` uses this f₀ as the background for
3.45 MeV α particles at $T_e = 10$ keV with $n_\alpha/n_e = 10^{-3}$, on 801 nodes.

<figure class="ap-figure">
  <img src="/figures/electrons_profile.svg" alt="Bipolar distortion: deviation of f0, of its derivative and of the slope temperature" />
  <figcaption>The reference distortion. f₀ changes by 6%, its slope by 21%, and the local slope temperature by
  −11% to +25%. The 0.6% offset at small and large u is the density renormalisation.</figcaption>
</figure>

| Quantity | Slides | appelbe |
|---|---|---|
| peak $\delta f/f$ | 6.1% | 6.70% (6.07% $= Ae^{-1/2}$ without the renormalisation) |
| peak $\delta f'/f'$ | 21.3% | 20.8% (non-relativistic base; the slides use Maxwell–Jüttner) |
| TS temperature | < 1% | +0.70% (fit on $w \le 2$), +0.08% ($w \le 3$); $T_{\text{kin}}$ +0.62% |
| ECE slope temperature | 17–20% | 0.894 to 1.253 |

## Scans: what moves, and what does not

`appelbe_electrons` varies one parameter at a time around the reference: $A \in [-0.3, 0.3]$, $u_0 \in [0.5, 4]$,
$w \in [0.1, 1]$. It writes `results/electrons_scan_{A,u0,w}.dat`.

<figure class="ap-figure">
  <img src="/figures/electrons_readouts.svg" alt="TS and ECE readouts versus the width of the distortion" />
  <figcaption>The readouts against the width w (A = 0.1, u₀ = 2). TS stays within 3% of T_e; the ECE slope temperature
  spans 0.80–2.0 for a narrow feature.</figcaption>
</figure>

The relative changes of the transport coefficients depend on the baseline. Against the Maxwellian at $T_e$, part of the
change is only a temperature shift: a broad distortion raises $T_{\text{kin}}$ by up to 3%, and in normalised units
$\sigma \propto T^{3/2}$. The baseline that isolates the effect of the shape is the Maxwellian of **equal energy**,
$T = T_{\text{kin}}$ (dashed lines below).

<figure class="ap-figure">
  <img src="/figures/electrons_transport.svg" alt="Change of transport coefficients and alpha closure versus the width" />
  <figcaption>Relative change at ωτ = 0. Solid lines are against the Maxwellian at T_e, dashed lines against the
  Maxwellian at T_kin. σ is almost entirely a temperature effect; κ is a genuine shape effect.</figcaption>
</figure>

Largest changes over the three scans at ωτ = 0, against the equal-energy Maxwellian:

| Quantity | Largest change | Where |
|---|---|---|
| σ | 1.0% | $A = -0.3$ |
| κ | −6.7% | $w = 0.85$ (−4.6% at $u_0 = 1.5$, −4.2% at $A = 0.3$) |
| $j^\nu$ | −2.9% | $u_0 = 0.5$ (+2.3% at $w = 0.65$) |
| $\zeta^\nu$ | −1.2% | $u_0 = 0.5$ |

Against the Maxwellian at $T_e$ the largest values are σ 4.6% and κ −5.5%. At ωτ = 1 every change is below 1.5%. The
changes are linear in $A$.

The conclusion for the ECE/TS question: a distortion that moves the ECE readout by tens of per cent moves TS by at most a
few per cent. Among the transport coefficients it moves κ by a few per cent and σ and the α closure by about one per
cent. In this model the distortion is a diagnostic effect much more than a transport one. κ is the exception: it
samples the energies where the feature sits.

## Assumptions and limits

- **f₀ is prescribed, not solved for.** A non-Maxwellian $f_0$ is not a steady state of the electron–electron
  collisions: it relaxes on $\tau_{ee}$ unless a source maintains it (α heating, RF, ...). That source is not modelled.
- **Onsager reciprocity is lost.** $\tau = \mu - \tfrac32\sigma$ holds to $10^{-7}$ about the Maxwellian, which is the
  collisional equilibrium. With the bipolar $f_0$ it fails at first order in $A$: −1.8% at $A = 0.1$, $w = 0.5$ (in
  `test_electrons`). The thermoelectric tensor from the temperature-gradient current and the one from the
  electric-drive heat flow are then no longer the same; `beta()` returns $\mu/\sigma - 5/2$.
- **The ∇T drive assumes a self-similar f₀**, $f_0 = n/v_T^3\,\varphi(v/v_T)$, so that the distortion moves with
  $T_e$. A feature fixed in absolute energy gives a different drive. The density-gradient drive $-uf_0$ and the
  electric drive $-\tfrac12f_0'$ no longer combine into $\mathbf E + \nabla P_e/(en_e)$; `response` returns the pure
  electric-field response.
- **Non-relativistic.** At 10 keV the relativistic corrections are of order $T_e/m_ec^2 \approx 2\%$; this accounts for
  the slides' 21.3% against 20.8%.
- **No forward model** of an ECE channel (optical depth, finite resonance width, harmonics, angle). The TS readout is
  the non-relativistic incoherent spectrum.

## Verification

`test_electrons` (30 checks):

- The general path with a Maxwellian converges to the closed forms at third order: $2\times10^{-6}$ at 401 nodes.
- In the Lorentz gas, $f_1 = -u^3g_7/k_i$ is local. Then $\sigma \propto \int u^5 f_0$ and $K \propto \int u^9 f_0$
  for any $f_0$, and the bipolar ratios match these to $10^{-6}$. A Maxwellian at $1.1\,T_e$ gives $1.1^{3/2}$.
- The bipolar $f_0$ matches its analytic form: the peak of $f_0/f_M - 1$ equals $Ae^{-1/2}$, and the finite-difference
  $f_0'$ matches the analytic derivative to $10^{-10}$.
- Tables of a Maxwellian and of the bipolar $f_0$ reproduce the functions they sample, to $10^{-6}$ in the responses.
- Every readout of a Maxwellian is 1.
- The reference case and the loss of reciprocity are regression values.
