#!/usr/bin/env python3
"""
Acoustic design model for the MakerX Acoustic Tile (Opus 5.0).

Predicts the two things the tile is supposed to do, from first principles, so the
geometry parameters in makerx-acoustic-tile.scad can be chosen on evidence rather
than vibes:

  1. DIFFUSION - far-field scattering of the 2D Schroeder (quadratic-residue) well
     array, via the Kirchhoff / Fraunhofer phase-grating approximation, reduced to
     a normalised diffusion coefficient in the style of ISO 17497-2.

  2. ABSORPTION - normal-incidence absorption coefficient, via a transfer-matrix
     stack per cell:  micro-perforated floor + sealed back cavity (Maa 1998),
     transformed to the panel face through the well acting as a lossy duct
     (quarter-wave transformer with Kirchhoff wall attenuation).

Both models are analytic first-order approximations, not BEM/FEM. See the
"Model limitations" section of README.md for what they do and don't capture.

Usage:
    python3 acoustic_model.py                # tables to stdout + plots to ../docs
    python3 acoustic_model.py --sweep        # neck-geometry sweep (design study)
    python3 acoustic_model.py --no-plots     # tables only
"""

from __future__ import annotations

import argparse
import cmath
import math
import os
import sys

import numpy as np

# ---------------------------------------------------------------------------
# Air properties at 20 degC, 1 atm
# ---------------------------------------------------------------------------
C_AIR = 343.0        # speed of sound, m/s
RHO = 1.204          # density, kg/m^3
ETA = 1.825e-5       # dynamic viscosity, Pa.s
GAMMA = 1.402        # ratio of specific heats
PRANDTL = 0.71       # Prandtl number

# ---------------------------------------------------------------------------
# Tile geometry - keep in sync with makerx-acoustic-tile.scad
# ---------------------------------------------------------------------------
class TileGeometry:
    """Mirror of the .scad parameter block. All lengths in mm."""

    def __init__(
        self,
        tile=250.0,
        n_prime=7,
        fin_t=1.35,
        rim_t=1.8,
        well_depth_max=48.0,
        floor_t=2.4,
        neck_dia=1.4,
        neck_count=8,
        neck_shrink=0.2,       # FDM undersizing: as-printed dia = neck_dia - neck_shrink
        pattern_offset=(4, 4),
        min_void_for_neck=4.0,  # cells with less back-volume than this get no perforations
        neck_ring_frac=0.25,    # neck ring radius as a fraction of cell width
        neck_start_angle=22.5,  # keeps necks clear of the gusset mid-lines
    ):
        self.neck_ring_frac = neck_ring_frac
        self.neck_start_angle = neck_start_angle
        self.tile = tile
        self.N = n_prime
        self.fin_t = fin_t
        self.rim_t = rim_t
        self.well_depth_max = well_depth_max
        self.floor_t = floor_t
        self.neck_dia = neck_dia
        self.neck_count = neck_count
        self.neck_shrink = neck_shrink
        self.pattern_offset = pattern_offset
        self.min_void_for_neck = min_void_for_neck

        # Derived --------------------------------------------------------
        self.cell_w = (tile - 2 * rim_t - (self.N - 1) * fin_t) / self.N
        self.pitch = self.cell_w + fin_t
        self.seq = self.qrd_2d()
        self.s_max = int(self.seq.max())
        self.unit_depth = well_depth_max / self.s_max
        self.depth = self.seq * self.unit_depth              # well depth per cell
        self.void = well_depth_max - self.depth              # back-cavity height per cell

    # -- Schroeder 2D quadratic-residue sequence ------------------------
    def qrd_2d(self) -> np.ndarray:
        """s(i,j) = ((i+m)^2 + (j+n)^2) mod N  -- cyclically shifted 2D QRD."""
        m, n = self.pattern_offset
        N = self.N
        i = np.arange(N)
        a = ((i[:, None] + m) ** 2) % N
        b = ((i[None, :] + n) ** 2) % N
        return (a + b) % N

    # -- Cell centre coordinates (mm, tile centred on origin) -----------
    def cell_centres(self):
        N = self.N
        first = -self.tile / 2 + self.rim_t + self.cell_w / 2
        coords = first + np.arange(N) * self.pitch
        return coords

    # -- Band-limit summary --------------------------------------------
    def band_limits(self):
        d_max_m = self.well_depth_max / 1000.0
        w_m = self.cell_w / 1000.0
        return {
            # Lowest frequency at which the depth spread produces >= pi of
            # phase difference between deepest and shallowest well.
            "f_low": C_AIR / (4 * d_max_m),
            # Schroeder design frequency: the tuning the QRD sequence is optimal at.
            "f_design": self.s_max * C_AIR / (2 * self.N * d_max_m),
            # Above this, each well is wide compared to a wavelength and behaves
            # as an independent flat reflector.
            "f_high": C_AIR / (2 * w_m),
        }

    def quarter_wave_freqs(self):
        """Fundamental quarter-wave resonance of each distinct well depth."""
        out = {}
        for s in range(self.s_max + 1):
            d = s * self.unit_depth / 1000.0
            out[s] = (C_AIR / (4 * d)) if d > 0 else None
        return out

    def helmholtz_freqs(self):
        """Lumped-element Helmholtz estimate for each distinct back cavity."""
        out = {}
        d_eff = (self.neck_dia - self.neck_shrink) / 1000.0
        t = self.floor_t / 1000.0
        area = self.neck_count * math.pi * d_eff**2 / 4
        l_eff = t + 0.85 * d_eff
        for s in range(self.s_max + 1):
            v = self.well_depth_max - s * self.unit_depth
            if v < self.min_void_for_neck:
                out[s] = None
                continue
            vol = (self.cell_w / 1000.0) ** 2 * (v / 1000.0)
            out[s] = (C_AIR / (2 * math.pi)) * math.sqrt(area / (vol * l_eff))
        return out

    def counts(self):
        """How many cells carry each sequence value."""
        return {s: int((self.seq == s).sum()) for s in range(self.s_max + 1)}


# ---------------------------------------------------------------------------
# 1. ABSORPTION
# ---------------------------------------------------------------------------
def maa_perforate_impedance(f, hole_dia_m, plate_t_m, porosity):
    """
    Normalised (by rho*c) acoustic impedance of a micro-perforated plate.
    Maa, 'Potential of microperforated panel absorber', JASA 104(5), 1998.
    """
    omega = 2 * math.pi * f
    x = (hole_dia_m / 2) * np.sqrt(omega * RHO / ETA)  # shear wave number

    r = (32 * ETA * plate_t_m) / (porosity * RHO * C_AIR * hole_dia_m**2) * (
        np.sqrt(1 + x**2 / 32) + (math.sqrt(2) / 32) * x * hole_dia_m / plate_t_m
    )
    m = (omega * plate_t_m) / (porosity * C_AIR) * (
        1 + 1 / np.sqrt(9 + x**2 / 2) + 0.85 * hole_dia_m / plate_t_m
    )
    return r + 1j * m


def duct_wavenumber(f, hydraulic_radius_m):
    """
    Complex wavenumber for a wide duct including Kirchhoff viscothermal wall
    losses. Convention: p ~ exp(j(wt - kx)), so k = k' - j*alpha.

    alpha [Np/m] = (1/(a*c)) * sqrt(w*eta/(2*rho)) * (1 + (gamma-1)/sqrt(Pr))
    with a = 2*r_h (equivalent radius of the duct).
    """
    omega = 2 * math.pi * f
    k = omega / C_AIR
    a = 2 * hydraulic_radius_m
    alpha = (1.0 / (a * C_AIR)) * np.sqrt(omega * ETA / (2 * RHO)) * (
        1 + (GAMMA - 1) / math.sqrt(PRANDTL)
    )
    return k - 1j * alpha


def cell_absorption(f, geo: TileGeometry, s_value: int):
    """
    Normal-incidence absorption coefficient at the panel face for one cell.

    Impedance stack, back to front:
      sealed cavity (depth v)  ->  perforated floor  ->  well duct (depth D)
    All impedances normalised by rho*c.
    """
    f = np.asarray(f, dtype=float)
    depth_m = geo.depth[0, 0] * 0  # placeholder to keep shape logic obvious
    D = s_value * geo.unit_depth / 1000.0          # well depth, m
    v = (geo.well_depth_max - s_value * geo.unit_depth) / 1000.0  # cavity, m
    t = geo.floor_t / 1000.0
    w = geo.cell_w / 1000.0
    d_eff = (geo.neck_dia - geo.neck_shrink) / 1000.0

    k0 = 2 * math.pi * f / C_AIR

    # --- Floor: perforated plate + sealed cavity, or rigid ---------------
    perforated = (geo.well_depth_max - s_value * geo.unit_depth) >= geo.min_void_for_neck
    if perforated and v > 0:
        porosity = geo.neck_count * math.pi * d_eff**2 / 4 / (w**2)
        z_plate = maa_perforate_impedance(f, d_eff, t, porosity)
        # Rigid-backed air cavity of depth v (lossless is adequate at these depths)
        z_cav = -1j / np.tan(k0 * v)
        z_floor = z_plate + z_cav
    else:
        z_floor = np.full_like(f, np.inf, dtype=complex)

    # --- Transform through the well duct to the panel face ---------------
    if D <= 0:
        z_face = z_floor
    else:
        kc = duct_wavenumber(f, w / 4)   # square duct: r_h = w/4
        tan_kl = np.tan(kc * D)
        with np.errstate(divide="ignore", invalid="ignore"):
            z_face = np.where(
                np.isinf(z_floor.real),
                -1j / tan_kl,                                    # rigid-terminated duct
                (z_floor + 1j * tan_kl) / (1 + 1j * z_floor * tan_kl),
            )

    refl = (z_face - 1) / (z_face + 1)
    alpha = 1 - np.abs(refl) ** 2
    return np.clip(np.nan_to_num(alpha, nan=0.0), 0.0, 1.0)


def panel_absorption(freqs, geo: TileGeometry):
    """Area-weighted normal-incidence absorption of the whole tile face."""
    freqs = np.asarray(freqs, dtype=float)
    total_area = geo.tile**2
    cell_area = geo.cell_w**2
    counts = geo.counts()

    accum = np.zeros_like(freqs)
    for s, n_cells in counts.items():
        if n_cells == 0:
            continue
        accum += n_cells * cell_area * cell_absorption(freqs, geo, s)
    # Fin/rim land area is rigid: contributes zero absorption but counts in the area.
    return accum / total_area


# ---------------------------------------------------------------------------
# 2. DIFFUSION
# ---------------------------------------------------------------------------
def scattered_polar(freq, geo: TileGeometry, thetas_deg, phi_deg=0.0, incidence_deg=0.0):
    """
    Far-field scattered pressure magnitude (Kirchhoff / Fraunhofer phase grating).

    Each well is treated as a piston whose reflection coefficient carries the
    round-trip phase of its depth. Valid for wavelengths not much smaller than
    the well width; ignores inter-well coupling and fin edge scattering.
    """
    k = 2 * math.pi * freq / C_AIR * 1e-3   # rad/mm  (geometry is in mm)
    coords = geo.cell_centres()
    xs, ys = np.meshgrid(coords, coords, indexing="ij")

    # Round-trip phase in each well (rigid bottom).
    refl = np.exp(-2j * k * geo.depth)

    th = np.radians(np.asarray(thetas_deg, dtype=float))
    ph = math.radians(phi_deg)
    th_i = math.radians(incidence_deg)

    # Direction cosines: receiver minus source (grating equation)
    u = np.sin(th) * math.cos(ph) - math.sin(th_i)
    v = np.sin(th) * math.sin(ph)

    w = geo.cell_w
    # Square-piston aperture directivity
    ap = np.sinc(k * w * u / (2 * math.pi)) * np.sinc(k * w * v / (2 * math.pi))

    phase = np.exp(1j * k * (xs[None, :, :] * u[:, None, None]
                             + ys[None, :, :] * v[:, None, None]))
    p = (refl[None, :, :] * phase).sum(axis=(1, 2)) * ap * (w**2)
    return np.abs(p)


def diffusion_coefficient(freq, geo: TileGeometry, n_rx=181, incidence_deg=0.0):
    """
    Autocorrelation diffusion coefficient d, per ISO 17497-2 in form:
        d = [ (sum p_i^2)^2 - sum (p_i^2)^2 ] / [ (n-1) * sum (p_i^2)^2 ]
    evaluated on a -90..+90 deg receiver arc.
    """
    thetas = np.linspace(-90, 90, n_rx)
    p = scattered_polar(freq, geo, thetas, incidence_deg=incidence_deg)
    e = p**2                     # energy at each receiver
    num = e.sum() ** 2 - (e**2).sum()
    den = (n_rx - 1) * (e**2).sum()
    return num / den if den > 0 else 0.0


def flat_plate_reference(freq, geo: TileGeometry, n_rx=181, incidence_deg=0.0):
    """Same aperture, all well depths zero -> the flat reflector baseline."""
    flat = TileGeometry(
        tile=geo.tile, n_prime=geo.N, fin_t=geo.fin_t, rim_t=geo.rim_t,
        well_depth_max=1e-9, floor_t=geo.floor_t,
        pattern_offset=geo.pattern_offset,
    )
    return diffusion_coefficient(freq, flat, n_rx, incidence_deg)


def normalised_diffusion(freq, geo: TileGeometry, **kw):
    d = diffusion_coefficient(freq, geo, **kw)
    d0 = flat_plate_reference(freq, geo, **kw)
    return (d - d0) / (1 - d0) if d0 < 1 else 0.0


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------
THIRD_OCTAVE = [100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250,
                1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000]


def report(geo: TileGeometry):
    lim = geo.band_limits()
    print("=" * 74)
    print("MakerX Acoustic Tile Opus5.0 - acoustic prediction")
    print("=" * 74)
    print(f"Tile                 {geo.tile:.0f} x {geo.tile:.0f} mm, "
          f"N = {geo.N} ({geo.N**2} cells)")
    print(f"Cell clear width     {geo.cell_w:.3f} mm   (pitch {geo.pitch:.3f} mm)")
    print(f"Fin / rim thickness  {geo.fin_t:.2f} / {geo.rim_t:.2f} mm")
    print(f"Well depth step      {geo.unit_depth:.3f} mm  (max {geo.well_depth_max:.1f} mm)")
    print(f"Floor thickness      {geo.floor_t:.2f} mm")
    print(f"Necks per floor      {geo.neck_count} x dia {geo.neck_dia:.2f} mm "
          f"(as-printed {geo.neck_dia - geo.neck_shrink:.2f} mm)")
    aperture = geo.N**2 * geo.cell_w**2 / geo.tile**2
    print(f"Open aperture ratio  {aperture*100:.1f} %  "
          f"(fin land {100*(1-aperture):.1f} %)")
    print()

    print("--- Diffusion band limits ---------------------------------------------")
    print(f"  f_low     {lim['f_low']:7.0f} Hz   deepest well = lambda/4, "
          "phase spread reaches pi")
    print(f"  f_design  {lim['f_design']:7.0f} Hz   Schroeder design frequency "
          "(sequence optimally tuned)")
    print(f"  f_high    {lim['f_high']:7.0f} Hz   well width = lambda/2, "
          "wells stop acting as a grating")
    print()

    print("--- Per-depth cell inventory -----------------------------------------")
    qw = geo.quarter_wave_freqs()
    hh = geo.helmholtz_freqs()
    cnt = geo.counts()
    print(f"  {'s':>2} {'cells':>6} {'depth':>8} {'cavity':>8} "
          f"{'1/4-wave':>10} {'Helmholtz':>11}")
    for s in range(geo.s_max + 1):
        d = s * geo.unit_depth
        v = geo.well_depth_max - d
        qws = f"{qw[s]:.0f} Hz" if qw[s] else "-"
        hhs = f"{hh[s]:.0f} Hz" if hh[s] else "sealed"
        print(f"  {s:>2} {cnt[s]:>6} {d:>7.1f}mm {v:>7.1f}mm {qws:>10} {hhs:>11}")
    print()

    print("--- Predicted performance by third octave ----------------------------")
    print(f"  {'Hz':>6} {'alpha_n':>9} {'d_norm':>8}")
    freqs = np.array(THIRD_OCTAVE, dtype=float)
    alpha = panel_absorption(freqs, geo)
    for f, a in zip(freqs, alpha):
        dn = normalised_diffusion(f, geo) if f >= 400 else float("nan")
        dn_s = f"{dn:8.2f}" if not math.isnan(dn) else "       -"
        print(f"  {f:>6.0f} {a:>9.2f} {dn_s}")
    print()

    # Summary integrals
    band_abs = (freqs >= 315) & (freqs <= 1000)
    band_dif = (freqs >= 1600) & (freqs <= 5000)
    dn_vals = [normalised_diffusion(f, geo) for f in freqs[band_dif]]
    print(f"  Mean alpha, 315-1000 Hz : {alpha[band_abs].mean():.2f}")
    print(f"  Peak alpha              : {alpha.max():.2f} at "
          f"{freqs[int(np.argmax(alpha))]:.0f} Hz")
    print(f"  Mean d_norm, 1.6-5 kHz  : {np.mean(dn_vals):.2f}")
    print()


def modulation_check(base: TileGeometry, offsets):
    """Confirm cyclic-shift variants are acoustically equivalent (for arraying)."""
    print("--- Array modulation: cyclic-shift variants --------------------------")
    print("  Rolling the sequence origin gives a visually different tile with the")
    print("  same depth histogram, so an array breaks up periodicity without")
    print("  changing performance.")
    print(f"  {'offset':>10} {'d_norm @2k':>11} {'d_norm @3k':>11} "
          f"{'d_norm @4k':>11} {'alpha 500':>10}")
    for off in offsets:
        g = TileGeometry(
            tile=base.tile, n_prime=base.N, fin_t=base.fin_t, rim_t=base.rim_t,
            well_depth_max=base.well_depth_max, floor_t=base.floor_t,
            neck_dia=base.neck_dia, neck_count=base.neck_count,
            neck_shrink=base.neck_shrink, pattern_offset=off,
        )
        a500 = panel_absorption(np.array([500.0]), g)[0]
        print(f"  {str(off):>10} {normalised_diffusion(2000, g):>11.2f} "
              f"{normalised_diffusion(3000, g):>11.2f} "
              f"{normalised_diffusion(4000, g):>11.2f} {a500:>10.2f}")
    print()


def neck_sweep(base: TileGeometry):
    """Design study: which neck geometry maximises useful absorption?"""
    print("--- Neck geometry sweep (design study) -------------------------------")
    print("  Objective: raise mean alpha over 315-1000 Hz without sub-printable")
    print("  holes. As-printed diameter assumed 0.2 mm under nominal.")
    print(f"  {'nom dia':>8} {'count':>6} {'sigma %':>8} {'mean a':>8} "
          f"{'peak a':>8} {'peak Hz':>8}")
    freqs = np.geomspace(80, 8000, 500)
    band = (freqs >= 315) & (freqs <= 1000)
    for dia in (1.0, 1.2, 1.4, 1.6, 2.0, 2.5, 3.0):
        for cnt in (1, 4, 9, 16):
            g = TileGeometry(
                tile=base.tile, n_prime=base.N, fin_t=base.fin_t, rim_t=base.rim_t,
                well_depth_max=base.well_depth_max, floor_t=base.floor_t,
                neck_dia=dia, neck_count=cnt, neck_shrink=base.neck_shrink,
                pattern_offset=base.pattern_offset,
            )
            d_eff = (dia - base.neck_shrink) / 1000.0
            sigma = cnt * math.pi * d_eff**2 / 4 / (g.cell_w / 1000.0) ** 2
            a = panel_absorption(freqs, g)
            print(f"  {dia:>8.1f} {cnt:>6} {sigma*100:>8.2f} "
                  f"{a[band].mean():>8.3f} {a.max():>8.3f} "
                  f"{freqs[int(np.argmax(a))]:>8.0f}")
    print()


def make_plots(geo: TileGeometry, outdir: str):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.patches import Rectangle

    MX = dict(navy="#0f1c57", magenta="#cc3a9d", gold="#ffc023",
              cyan="#16acf2", white="#f2f2f2", black="#0e0f10")

    os.makedirs(outdir, exist_ok=True)
    lim = geo.band_limits()

    # ---- Figure 1: absorption + diffusion -----------------------------
    fig, ax = plt.subplots(1, 2, figsize=(13, 4.8))
    freqs = np.geomspace(80, 8000, 600)

    a = panel_absorption(freqs, geo)
    ax[0].semilogx(freqs, a, color=MX["magenta"], lw=2.2, label="Tile (predicted)")
    # Sensitivity to as-printed hole diameter
    for shrink, ls in ((0.0, ":"), (0.35, "--")):
        g2 = TileGeometry(
            tile=geo.tile, n_prime=geo.N, fin_t=geo.fin_t, rim_t=geo.rim_t,
            well_depth_max=geo.well_depth_max, floor_t=geo.floor_t,
            neck_dia=geo.neck_dia, neck_count=geo.neck_count,
            neck_shrink=shrink, pattern_offset=geo.pattern_offset,
        )
        ax[0].semilogx(freqs, panel_absorption(freqs, g2), color=MX["navy"],
                       lw=1.0, ls=ls,
                       label=f"hole dia {geo.neck_dia - shrink:.2f} mm")
    ax[0].set_xlabel("Frequency (Hz)")
    ax[0].set_ylabel(r"$\alpha$  (normal incidence)")
    ax[0].set_title("Absorption: perforated floor + sealed cavity", color=MX["navy"])
    ax[0].set_ylim(0, 1)
    ax[0].grid(alpha=0.25, which="both")
    ax[0].legend(fontsize=8, loc="upper left")

    dfreqs = np.geomspace(400, 8000, 90)
    dn = [normalised_diffusion(f, geo) for f in dfreqs]
    ax[1].semilogx(dfreqs, dn, color=MX["cyan"], lw=2.2)
    ax[1].axvspan(lim["f_low"], lim["f_high"], color=MX["gold"], alpha=0.18,
                  label="design band")
    ax[1].axvline(lim["f_design"], color=MX["navy"], ls="--", lw=1.0,
                  label=f"f_design {lim['f_design']:.0f} Hz")
    ax[1].set_xlabel("Frequency (Hz)")
    ax[1].set_ylabel(r"$d_{norm}$  vs flat plate")
    ax[1].set_title("Diffusion: 2D quadratic-residue array", color=MX["navy"])
    ax[1].set_ylim(-0.1, 1)
    ax[1].grid(alpha=0.25, which="both")
    ax[1].legend(fontsize=8, loc="lower right")

    fig.suptitle("MakerX Acoustic Tile - predicted performance", color=MX["navy"],
                 fontsize=13, fontweight="bold")
    fig.tight_layout()
    p1 = os.path.join(outdir, "acoustic-performance.png")
    fig.savefig(p1, dpi=150)
    plt.close(fig)

    # ---- Figure 2: polar scattering vs flat plate ---------------------
    fig = plt.figure(figsize=(12, 4.2))
    flat = TileGeometry(tile=geo.tile, n_prime=geo.N, fin_t=geo.fin_t,
                        rim_t=geo.rim_t, well_depth_max=1e-9,
                        floor_t=geo.floor_t, pattern_offset=geo.pattern_offset)
    thetas = np.linspace(-90, 90, 361)
    for idx, f0 in enumerate((2000, 3150, 5000)):
        axp = fig.add_subplot(1, 3, idx + 1, projection="polar")
        for g, col, lab in ((flat, MX["navy"], "flat plate"),
                            (geo, MX["magenta"], "MakerX tile")):
            p = scattered_polar(f0, g, thetas)
            db = 20 * np.log10(np.maximum(p, 1e-12) / p.max())
            db = np.maximum(db, -30) + 30
            axp.plot(np.radians(thetas), db, color=col, lw=1.6, label=lab)
        axp.set_theta_zero_location("N")
        axp.set_theta_direction(-1)
        axp.set_thetamin(-90)
        axp.set_thetamax(90)
        axp.set_rticks([10, 20, 30])
        axp.set_yticklabels([])
        axp.set_title(f"{f0} Hz", color=MX["navy"], fontsize=10)
        if idx == 0:
            axp.legend(fontsize=7, loc="lower left", bbox_to_anchor=(-0.15, -0.15))
    fig.suptitle("Scattered polar response, normal incidence "
                 "(normalised, 30 dB range)", color=MX["navy"], fontweight="bold")
    fig.tight_layout()
    p2 = os.path.join(outdir, "polar-response.png")
    fig.savefig(p2, dpi=150)
    plt.close(fig)

    # ---- Figure 3: depth map + colour banding -------------------------
    fig, axm = plt.subplots(1, 2, figsize=(11, 4.6))
    im = axm[0].imshow(geo.depth, cmap="viridis", origin="lower")
    for i in range(geo.N):
        for j in range(geo.N):
            axm[0].text(j, i, f"{int(geo.seq[i, j])}", ha="center", va="center",
                        color="white", fontsize=9, fontweight="bold")
    axm[0].set_title(f"Well depth map, N={geo.N}, offset {geo.pattern_offset}\n"
                     "(cell labels = sequence value)", color=MX["navy"], fontsize=10)
    axm[0].set_xticks(range(geo.N))
    axm[0].set_yticks(range(geo.N))
    fig.colorbar(im, ax=axm[0], label="depth (mm)")

    # Strata colour bands as a side elevation
    bands = strata_bands(geo)
    axm[1].add_patch(Rectangle((0, -2), 10, 2, color=MX["navy"]))
    for (z0, z1, name) in bands:
        axm[1].add_patch(Rectangle((0, z0), 10, z1 - z0, color=MX[name]))
        axm[1].text(10.6, (z0 + z1) / 2, f"{name}  {z0:.0f}-{z1:.0f} mm",
                    va="center", fontsize=8, color=MX["black"])
    axm[1].set_xlim(0, 22)
    axm[1].set_ylim(-3, geo.well_depth_max + geo.floor_t + 2)
    axm[1].set_ylabel("height above back plate (mm)")
    axm[1].set_title("Strata colour bands (one filament per Z band)",
                     color=MX["navy"], fontsize=10)
    axm[1].set_xticks([])
    fig.tight_layout()
    p3 = os.path.join(outdir, "depth-map.png")
    fig.savefig(p3, dpi=150)
    plt.close(fig)

    print(f"Plots written:\n  {p1}\n  {p2}\n  {p3}\n")


def strata_bands(geo: TileGeometry, back_t=1.6, layer_height=0.2):
    """
    Z bands for the default 'strata' colour mode. Mirrors band_edges() and
    band_colour_index() in makerx-acoustic-tile.scad: one band per distinct floor
    level, each boundary one layer ABOVE that floor's top surface so no floor is
    split across two filaments and no cut plane is coplanar with a floor face.

    Returns [(z0, z1, colour_name), ...] measured from the build plate.
    """
    face_z = back_t + geo.well_depth_max + geo.floor_t
    floor_top = lambda s: face_z - s * geo.unit_depth
    edges = ([0.0]
             + [floor_top(s) + layer_height for s in range(geo.s_max, 0, -1)]
             + [face_z])
    order = ["magenta", "gold", "cyan"]
    n = len(edges) - 1
    return [
        (edges[k], edges[k + 1],
         "navy" if (k == 0 or k == n - 1) else order[(k - 1) % 3])
        for k in range(n)
    ]


def _clip_y(poly, y0, y1):
    """Sutherland-Hodgman clip of a polygon to the horizontal slab y0 <= y <= y1."""
    def clip(pts, keep, ycut, lower):
        out = []
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            ina = (a[1] >= ycut) if lower else (a[1] <= ycut)
            inb = (b[1] >= ycut) if lower else (b[1] <= ycut)
            if ina:
                out.append(a)
            if ina != inb and abs(b[1] - a[1]) > 1e-12:
                t = (ycut - a[1]) / (b[1] - a[1])
                out.append((a[0] + t * (b[0] - a[0]), ycut))
        return out
    p = clip(poly, True, y0, True)
    if len(p) < 3:
        return []
    p = clip(p, True, y1, False)
    return p if len(p) >= 3 else []


def make_section_diagram(geo: TileGeometry, outdir: str,
                         back_t=1.6, layer_height=0.2, gusset_t=1.35,
                         neck_dia=None, row=None):
    """
    Labelled cross-section through one row of wells, filled with the strata
    colours so the colour scheme and the internal structure read together.
    Geometry mirrors makerx-acoustic-tile.scad exactly.
    """
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.patches import Polygon as MplPoly, Rectangle

    MX = {"navy": "#0f1c57", "magenta": "#cc3a9d", "gold": "#ffc023",
          "cyan": "#16acf2", "white": "#f2f2f2", "black": "#0e0f10"}
    neck_dia = geo.neck_dia if neck_dia is None else neck_dia
    row = geo.N // 2 if row is None else row

    face_z = back_t + geo.well_depth_max + geo.floor_t
    bands = strata_bands(geo, back_t, layer_height)
    tsize, fin_t, rim_t, w = geo.tile, geo.fin_t, geo.rim_t, geo.cell_w
    pitch = geo.pitch

    def cell_lo(k):
        return -(tsize - 2 * rim_t) / 2 + k * pitch

    # ---- Build the material silhouette as a list of polygons --------------
    polys = []
    polys.append([(-tsize / 2, 0), (tsize / 2, 0),
                  (tsize / 2, back_t), (-tsize / 2, back_t)])            # back plate
    for sx in (-1, 1):                                                    # frame
        x0 = sx * tsize / 2
        x1 = sx * (tsize / 2 - rim_t)
        polys.append([(x0, back_t), (x1, back_t), (x1, face_z), (x0, face_z)])
    for k in range(1, geo.N):                                             # fins
        x = cell_lo(k)
        polys.append([(x - fin_t, back_t), (x, back_t), (x, face_z), (x - fin_t, face_z)])

    necks = []
    for i in range(geo.N):
        s = int(geo.seq[row, i])
        x0, x1 = cell_lo(i), cell_lo(i) + w
        ft, fb = face_z - s * geo.unit_depth, face_z - s * geo.unit_depth - geo.floor_t
        polys.append([(x0, fb), (x1, fb), (x1, ft), (x0, ft)])            # floor
        # 45-degree gussets: sliver at the wall growing inward to full at the floor
        hw = w / 2
        zlow = max(fb - hw, back_t)
        if zlow < fb - 3 * layer_height:
            xm = (x0 + x1) / 2
            xin = (fb - zlow) if (fb - hw) < back_t else hw
            for sgn in (-1, 1):
                polys.append([(xm, fb), (xm + sgn * hw, fb),
                              (xm + sgn * hw, zlow), (xm + sgn * xin, zlow)])
        # Necks, drawn as gaps punched through the floor
        if (geo.well_depth_max - s * geo.unit_depth) >= geo.min_void_for_neck:
            r = geo.neck_ring_frac * w
            xm = (x0 + x1) / 2
            for kk in range(geo.neck_count):
                ang = math.radians(geo.neck_start_angle + kk * 360 / geo.neck_count)
                necks.append((xm + r * math.cos(ang), fb, ft))

    fig, ax = plt.subplots(figsize=(15, 5.4))

    # ---- Fill each polygon, band by band ---------------------------------
    for z0, z1, cname in bands:
        for p in polys:
            c = _clip_y(p, z0, z1)
            if c:
                ax.add_patch(MplPoly(c, closed=True, facecolor=MX[cname],
                                     edgecolor="none", zorder=2))
    # Necks punched through the floors
    for (xn, zb, zt) in necks:
        ax.add_patch(Rectangle((xn - neck_dia / 2, zb), neck_dia, zt - zb,
                               facecolor="white", edgecolor=MX["black"],
                               lw=0.4, zorder=3))

    # ---- Annotation -------------------------------------------------------
    for i in range(geo.N):
        s = int(geo.seq[row, i])
        xm = cell_lo(i) + w / 2
        d = s * geo.unit_depth
        ax.annotate(f"s={s}\n{d:.0f} mm", (xm, face_z + 3), ha="center",
                    va="bottom", fontsize=8, color=MX["navy"], fontweight="bold")
        v = geo.well_depth_max - d
        if v >= geo.min_void_for_neck:
            hz = geo.helmholtz_freqs()[s]
            ax.annotate(f"{hz:.0f} Hz", (xm, -3.5), ha="center", va="top",
                        fontsize=7.5, color=MX["magenta"])
        else:
            ax.annotate("sealed", (xm, -3.5), ha="center", va="top",
                        fontsize=7.5, color="#888")

    for z0, z1, cname in bands:
        ax.annotate(f"{z0:.1f}", (tsize / 2 + 4, z0), fontsize=7,
                    va="center", color="#666")
    ax.annotate("filament swap heights (mm)", (tsize / 2 + 4, face_z + 3),
                fontsize=7.5, color="#666", va="bottom")

    ax.plot([-tsize / 2, tsize / 2], [face_z, face_z], color=MX["black"],
            lw=0.6, ls=":", zorder=4)
    ax.annotate("acoustic face", (-tsize / 2, face_z + 3), fontsize=8,
                color=MX["black"], va="bottom")
    ax.annotate("back (to wall)", (-tsize / 2, -3.5), fontsize=8,
                color=MX["black"], va="top")

    ax.set_xlim(-tsize / 2 - 8, tsize / 2 + 34)
    ax.set_ylim(-16, face_z + 16)
    ax.set_aspect("equal")
    ax.axis("off")
    ax.set_title(f"Cross-section through row {row} - well depths, sealed back "
                 f"cavities, Helmholtz necks, 45$\\degree$ gussets, strata colours",
                 color=MX["navy"], fontsize=11, fontweight="bold")
    fig.tight_layout()
    p = os.path.join(outdir, "cross-section.png")
    fig.savefig(p, dpi=150)
    plt.close(fig)
    print(f"  {p}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sweep", action="store_true", help="run neck geometry sweep")
    ap.add_argument("--no-plots", action="store_true")
    ap.add_argument("--depth", type=float, default=48.0, help="max well depth, mm")
    ap.add_argument("--prime", type=int, default=7, help="QRD prime N")
    args = ap.parse_args()

    geo = TileGeometry(well_depth_max=args.depth, n_prime=args.prime)
    report(geo)
    modulation_check(geo, [(4, 4), (0, 0), (1, 3), (2, 5)])
    if args.sweep:
        neck_sweep(geo)
    if not args.no_plots:
        here = os.path.dirname(os.path.abspath(__file__))
        outdir = os.path.join(here, "..", "docs")
        make_plots(geo, outdir)
        make_section_diagram(geo, outdir)


if __name__ == "__main__":
    main()
