# Robust fixed-step reset sim for the final heart (steep-notch log spiral). Nose on y=e moving -X.
import numpy as np, sys
N = 2880
r0, rmax, tip, psi_n, a_n = 3.0, 18.0, 162.0, 55.0, 14.0
ks = np.tan(np.radians(psi_n)); r1 = r0*np.exp(ks*np.radians(a_n))
k1 = np.log(rmax/r1)/np.radians(tip - a_n); k2 = np.log(rmax/r1)/np.radians(360 - tip - a_n)
a = np.linspace(0, 2*np.pi, N, endpoint=False); b = np.degrees(a); c = 360 - b
r = np.where(b <= a_n, r0*np.exp(ks*np.radians(b)),
    np.where(c <= a_n, r0*np.exp(ks*np.radians(c)),
    np.where(b <= tip, r1*np.exp(k1*np.radians(b - a_n)), r1*np.exp(k2*np.radians(c - a_n)))))
def run(start, mu, nose_r=0.6, e=0.0):
    phi = np.arctan(mu); th = np.radians(start); x = 21.0
    while x > 2.0:
        xn = x - 0.02
        for _ in range(4000):
            px = r*np.cos(a+th); py = r*np.sin(a+th)
            d2 = (px-xn)**2 + (py-e)**2; i = np.argmin(d2); d = np.sqrt(d2[i])
            if d >= nose_r: break
            c_ = np.array([px[i], py[i]]); f = c_ - np.array([xn, e]); f /= np.linalg.norm(f)
            radial = -c_/np.linalg.norm(c_)
            if np.arccos(np.clip(f @ radial, -1, 1)) <= phi:
                return np.degrees(th) % 360, True, xn
            tq = c_[0]*f[1] - c_[1]*f[0]
            th += np.sign(tq)*np.radians(0.04)
        x = xn
    return np.degrees(th) % 360, False, x
mu = float(sys.argv[1]); step = float(sys.argv[2]) if len(sys.argv) > 2 else 3.0
res = []
for s in np.arange(0, 360, step):
    f, st, xn = run(s, mu)
    rel = ((f + 180) % 360) - 180
    res.append((s, round(rel, 2), st, round(xn, 2)))
seated = [t for t in res if abs(t[1]) < 4]
bad = [t for t in res if abs(t[1]) >= 4]
rels = [t[1] for t in seated]
print(f"mu={mu}: seated {len(seated)}/{len(res)}  zero spread {min(rels):.2f}..{max(rels):.2f} deg; nose stop x {min(t[3] for t in seated):.2f}..{max(t[3] for t in seated):.2f}")
print("  bad:", bad[:12])
