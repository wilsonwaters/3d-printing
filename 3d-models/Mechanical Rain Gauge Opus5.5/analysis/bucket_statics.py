"""Tipping-bucket statics for the Opus 5.5 mechanical rain gauge.

How much water tips the bucket? The bucket is a see-saw with a central divider; each
compartment has a flat floor `vb` below the axle and an open outer end. It rests tilted by
`theta0` on a stop screw with the filling compartment raised. It tips when the moment of the
water wedge (pooled against the divider) beats the restoring moment of the empty bucket, whose
centre of gravity is above the axle. The 3 mm axle ROLLS on a flat seat, so moments are taken
about the rolling contact, r_ax below the axle centre. Optional pivot friction adds to the
restoring moment.

This is the model the .scad's tip_volume_ml() reproduces analytically (the .scad asserts the
result is within ±5 % of area x 0.5 mm).

Usage:  python bucket_statics.py            (needs numpy + shapely)
"""
import numpy as np
from shapely.geometry import Polygon, box
from shapely import affinity

RHO_PETG, RHO_WATER, G = 1.27e-3, 1.0e-3, 9.81e-3     # g/mm^3, g/mm^3, N per gram

P = dict(L=34, W=44, vb=-8, Hd=30, td=1.8, tw=1.8, side_h=6, hub_g=1.5, ballast_g=6,
         ballast_w=9, r_ax=1.5)


def mass_cg(p):
    L, W, vb, Hd, td, tw = (p[k] for k in ("L", "W", "vb", "Hd", "td", "tw"))
    floor = (L - td/2)*tw*W*RHO_PETG, vb - tw/2
    side = Polygon([(td/2, vb - tw), (L, vb - tw), (L, vb + p["side_h"]), (td/2, Hd)])
    sides = 2*side.area*tw*RHO_PETG, side.centroid.y
    divider = (Hd - (vb - tw))*td*W*RHO_PETG, (Hd + vb - tw)/2
    # ballast block with a 45° underside, top 3 mm above the divider
    top, bw = Hd + 3, p["ballast_w"]
    ch = (bw - td)/2
    hr = (p["ballast_g"]/(RHO_PETG*W) - (bw + td)/2*ch)/bw
    bal = Polygon([(-bw/2, top), (bw/2, top), (bw/2, top - hr), (td/2, top - hr - ch),
                   (-td/2, top - hr - ch), (-bw/2, top - hr)])
    parts = [(2*floor[0], floor[1]), (2*sides[0], sides[1]), divider, (p["hub_g"], 0.0),
             (p["ballast_g"], bal.centroid.y)]
    M = sum(m for m, _ in parts)
    return M, sum(m*v for m, v in parts)/M


def water_arm(p, vol, theta):
    """Water volume `vol` (mm^3) in the raised compartment → (moment arm about contact, spills?)."""
    cav = Polygon([(p["td"]/2, p["vb"]), (p["L"], p["vb"]), (p["L"], 200), (p["td"]/2, 200)])
    piv = (0, -p["r_ax"])
    c = affinity.rotate(cav, theta, origin=piv)
    lo, hi = c.bounds[1], c.bounds[1] + 80
    for _ in range(50):
        mid = (lo + hi)/2
        if c.intersection(box(-400, -400, 400, mid)).area < vol/p["W"]:
            lo = mid
        else:
            hi = mid
    wet = c.intersection(box(-400, -400, 400, hi))
    lip = affinity.rotate(Polygon([(p["L"], p["vb"]), (p["L"] - .01, p["vb"]), (p["L"], p["vb"] - .01)]),
                          theta, origin=piv).exterior.coords[0][1]
    return wet.centroid.x - piv[0], hi > lip - 1.0


def tip_volume(p, theta0, friction_Nmm=0.0):
    M, V = mass_cg(p)
    restore = M*G*(V + p["r_ax"])*np.sin(np.radians(theta0)) + friction_Nmm
    for vol in np.arange(1000, 40001, 50):
        arm, spill = water_arm(p, vol, theta0)
        if (vol*RHO_WATER)*G*arm > restore:
            return vol/1000, spill, restore
    return None


if __name__ == "__main__":
    M, V = mass_cg(P)
    print(f"empty bucket {M:.1f} g, CG {V:.2f} mm above the axle")
    print("rest angle → tip volume (target 10.0 mL = 0.5 mm on 200 cm²)")
    for th in (22, 24, 26, 28, 30, 32, 34):
        v, spill, rest = tip_volume(P, th)
        print(f"  {th:2d}°: {v:5.2f} mL   restoring {rest:.3f} N·mm   {'SPILLS' if spill else ''}")
    print("pivot friction at 28° (rolling seat ≈ 0.02 N·mm, 3 mm pin in a hole ≈ 0.15 N·mm):")
    for f in (0.0, 0.02, 0.05, 0.15):
        print(f"  {f:.2f} N·mm → {tip_volume(P, 28, f)[0]:.2f} mL")
