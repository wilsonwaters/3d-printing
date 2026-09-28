# Fixed-step quasi-static reset sim for the final heart (steep 55° notch blended into log-spiral flanks).
# Usage: python heart_reset_sim.py <mu> <start_deg> <stop_deg> <step_deg>   (needs numpy)
import numpy as np, sys
N = 2880
r0, rmax, tip, psi_n, a1, ab = 3.0, 18.0, 168.0, 55.0, 10.0, 6.0
ks = np.tan(np.radians(psi_n)); R = np.pi/180
def kmain(span): return (np.log(rmax/r0) - ks*(a1 + ab/2)*R)/((span - a1 - ab/2)*R)
k1, k2 = kmain(tip), kmain(360 - tip)
def lnr(b, km):
    return np.where(b <= a1, ks*b*R, np.where(b <= a1 + ab,
        ks*a1*R + ks*(b - a1)*R - (ks - km)*((b - a1)*R)**2/(2*ab*R),
        ks*(a1 + ab/2)*R + km*(ab/2)*R + km*(b - a1 - ab)*R))
a = np.linspace(0, 2*np.pi, N, endpoint=False); b = np.degrees(a); c = 360 - b
r = np.where(b <= tip, r0*np.exp(lnr(b, k1)), r0*np.exp(lnr(c, k2)))
def inside(xn, e, th):
    ang = np.arctan2(e, xn) - th
    return np.hypot(xn, e) < np.interp(ang % (2*np.pi), a, r, period=2*np.pi)
def run(start, mu, nose_r=0.6, e=0.0, dx=0.04, dth=0.08):
    """Returns (final notch angle, stalled_on_single_contact, seated_in_two_contact, nose x)."""
    phi = np.arctan(mu); th = np.radians(start); x = 20.5
    while x > 2.5:
        xn = x - dx
        flips, last = 0, 0
        for _ in range(3000):
            if inside(xn, e, th):
                return np.degrees(th) % 360, False, True, xn     # would tunnel: treat as blocked
            px = r*np.cos(a+th); py = r*np.sin(a+th)
            d2 = (px-xn)**2 + (py-e)**2; i = np.argmin(d2); d = np.sqrt(d2[i])
            if d >= nose_r: break
            cc = np.array([px[i], py[i]]); f = cc - np.array([xn, e]); f /= np.linalg.norm(f)
            if np.arccos(np.clip(f @ (-cc/np.linalg.norm(cc)), -1, 1)) <= phi:
                return np.degrees(th) % 360, True, False, xn
            sgn = np.sign(cc[0]*f[1] - cc[1]*f[0])
            if last and sgn != last: flips += 1
            last = sgn
            if flips >= 4:                                        # pinned between two flanks
                return np.degrees(th) % 360, False, True, xn
            th += sgn*np.radians(dth)
        x = xn
    return np.degrees(th) % 360, False, False, x
mu = float(sys.argv[1]); lo, hi, st = float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
out = []
for s in np.arange(lo, hi, st):
    f, stall, seated, xn = run(s, mu)
    out.append((round(float(s), 1), round(((f + 180) % 360) - 180, 2), bool(stall), bool(seated), round(float(xn), 2)))
print(mu, out, flush=True)
