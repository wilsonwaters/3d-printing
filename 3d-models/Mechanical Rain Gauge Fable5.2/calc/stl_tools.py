"""Small STL helpers (no dependencies): connected bodies, volume, centroid.  usage: stl_tools.py file.stl"""
import struct, sys
def load(path):
    b=open(path,'rb').read()
    if b[:5]==b'solid' and b'facet' in b[:400]:
        import re
        v=[float(x) for x in re.findall(rb'vertex\s+(\S+)\s+(\S+)\s+(\S+)',b) for x in x]
        pts=[tuple(v[i:i+3]) for i in range(0,len(v),3)]
        return [pts[i:i+3] for i in range(0,len(pts),3)]
    n=struct.unpack('<I',b[80:84])[0]; tris=[]
    for i in range(n):
        o=84+i*50; f=struct.unpack('<12f',b[o:o+48]); tris.append([f[3:6],f[6:9],f[9:12]])
    return tris
def vol_centroid(tris):
    V=0; C=[0,0,0]
    for a,b,c in tris:
        v=(a[0]*(b[1]*c[2]-b[2]*c[1])-a[1]*(b[0]*c[2]-b[2]*c[0])+a[2]*(b[0]*c[1]-b[1]*c[0]))/6
        V+=v
        for k in range(3): C[k]+=v*(a[k]+b[k]+c[k])/4
    return V,[c/V for c in C]
def bodies(tris):
    key=lambda p:(round(p[0],4),round(p[1],4),round(p[2],4))
    parent={}
    def find(x):
        while parent[x]!=x: parent[x]=parent[parent[x]]; x=parent[x]
        return x
    for t in tris:
        ks=[key(p) for p in t]
        for k in ks: parent.setdefault(k,k)
        r=find(ks[0])
        for k in ks[1:]: parent[find(k)]=r
    groups={}
    for t in tris: groups.setdefault(find(key(t[0])),[]).append(t)
    return list(groups.values())
if __name__=="__main__":
    tris=load(sys.argv[1]); V,C=vol_centroid(tris)
    print(f"volume {V:.1f} mm3  centroid {C[0]:.3f} {C[1]:.3f} {C[2]:.3f}")
    for g in bodies(tris):
        xs=[p[0] for t in g for p in t]; ys=[p[1] for t in g for p in t]; zs=[p[2] for t in g for p in t]
        v,_=vol_centroid(g)
        if len(sys.argv)>2: break
        print(f"  body: {len(g)} tris vol {v:.2f} bbox x[{min(xs):.2f},{max(xs):.2f}] y[{min(ys):.2f},{max(ys):.2f}] z[{min(zs):.2f},{max(zs):.2f}]")
