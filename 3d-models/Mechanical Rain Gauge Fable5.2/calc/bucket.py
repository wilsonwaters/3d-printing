"""Tipping-bucket calibration model.

The bucket is a flat see-saw resting at tilt angle T on a stop screw.  Its own weight (centre of mass above the
knife edge) holds it there; rain collects in the raised compartment and tips it when the water's moment about
the pivot exceeds the holding moment.  This script takes the bucket's real mass and centre of mass from the
exported STL and solves for the water volume at the tipping point.

usage: bucket.py [name=value ...]     e.g.  bucket.py bk_mast_t=5.5      (needs OPENSCAD in the environment)
"""
import math, os, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(__file__)); import stl_tools
RHO = 1.27e-3      # g/mm3, PETG printed solid (100 % infill)
P = dict(bk_L=48, bk_W=36, bk_floor=1.6, bk_mast_t=6.0, bk_mast_h=48, bk_end_h=4, bk_end_peak=26, knife_r=0.3)
here = os.path.dirname(os.path.abspath(__file__)); scad = os.path.join(here, '..', 'mechanical-rain-gauge.scad')

def clip(poly, h):            # keep the part of a polygon below the water level z <= h
    out = []
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        ina, inb = a[1] <= h, b[1] <= h
        if ina: out.append(a)
        if ina != inb:
            t = (h - a[1]) / (b[1] - a[1]); out.append((a[0] + t * (b[0] - a[0]), h))
    return out
def area_cx(poly):
    A = Cx = 0
    for i in range(len(poly)):
        x0, y0 = poly[i]; x1, y1 = poly[(i + 1) % len(poly)]
        c = x0 * y1 - x1 * y0; A += c; Cx += (x0 + x1) * c
    A /= 2
    return abs(A), (Cx / (6 * A) if abs(A) > 1e-12 else 0)
def rot(p, th):               # tilt right side down by th about the pivot (origin)
    c, s = math.cos(th), math.sin(th); return (p[0] * c + p[1] * s, -p[0] * s + p[1] * c)

def bucket_mass(over):
    out = os.path.join(tempfile.gettempdir(), 'bucket_cal.stl'); cmd = [os.environ.get('OPENSCAD', 'openscad'), '-o', out, '-D', 'part="bucket"']
    for k, v in over.items(): cmd += ['-D', f'{k}={v}']
    subprocess.run(cmd + [scad], capture_output=True, check=True)
    V, C = stl_tools.vol_centroid(stl_tools.load(out))
    return V * RHO, C[2] - P['knife_r'], C[0]          # mass g, centre of mass height above the pivot, sideways offset

def tip_volume(M, c, tilt_deg, p=P):
    th = math.radians(tilt_deg); hold = M * c * math.sin(th)                 # g.mm
    z0 = p['bk_floor'] - p['knife_r']; L = p['bk_L']; t2 = p['bk_mast_t'] / 2
    top = lambda x: z0 + p['bk_end_h'] + (p['bk_end_peak'] - p['bk_end_h']) * (1 - abs(x) / L)   # end-wall crest
    pocket = [(-t2, z0), (-t2, top(-t2)), (-L, top(-L)), (-L, z0)]          # raised (left) compartment, bucket frame
    wp = [rot(q, th) for q in pocket]
    lo = min(q[1] for q in wp); spill = rot((-L, z0), th)[1]                  # water runs off the floor end here
    def state(h):
        A, cx = area_cx(clip(wp, h)); return A * p['bk_W'] * 1e-3, cx        # ml, x of centroid
    f = lambda h: -state(h)[0] * state(h)[1] - hold
    a, b = lo + 1e-6, spill
    if f(b) < 0: return None, state(b)[0]
    for _ in range(60):
        mid = (a + b) / 2
        a, b = (mid, b) if f(mid) < 0 else (a, mid)
    return state(b)[0], state(spill)[0]

if __name__ == "__main__":
    over = dict(a.split('=') for a in sys.argv[1:]); 
    for k, v in over.items():
        if k in P: P[k] = float(v)
    M, c, dx = bucket_mass(over)
    print(f"bucket {M:.2f} g, centre of mass {c:.2f} mm above the pivot (sideways {dx:+.3f} mm), holding moment M*c = {M*c:.0f} g.mm")
    prev = None
    for tilt in (17, 18, 18.5, 19, 19.5, 20, 20.5, 21, 21.5, 22, 23):
        V, Vs = tip_volume(M, c, tilt)
        print(f"  tilt {tilt:5.1f} deg: tips at {V:6.2f} ml = {V/20:.3f} mm of rain on 200 cm2   (compartment holds {Vs:.1f} ml before spilling)")
    lo, hi = 10.0, 30.0
    for _ in range(50):
        mid = (lo + hi) / 2; V, _ = tip_volume(M, c, mid)
        lo, hi = (mid, hi) if (V is not None and V < 10.0) else (lo, mid)
    print(f"  10.00 ml per tip needs a tilt of {lo:.2f} deg")
    # Energy check for the drive: the water gives up potential energy as it runs from the raised pocket to the
    # pouring edge; the register needs only the work of turning the pin wheel 18 degrees against its drag.
    th = math.radians(lo); z0 = P['bk_floor'] - P['knife_r']
    z_start = rot((-P['bk_L'] / 3, z0 + 3), th)[1]            # rough centroid of the charge before the tip
    z_exit = rot((-P["bk_L"], z0), -th)[1]                    # pouring edge after the tip (that side now down)
    e_water = 10e-3 * 9.81 * (z_start - z_exit)               # mJ  (kg * m/s2 * mm)
    drag = 0.05; eff = 0.5                                    # N.mm at the wheel (rotor imbalance, journals, gears); ramp efficiency
    e_need = drag * math.radians(18) / eff                    # mJ
    print(f"  drive: the water releases about {e_water:.1f} mJ per tip; stepping the wheel takes about {e_need:.3f} mJ ({e_water/e_need:.0f} times less)")
