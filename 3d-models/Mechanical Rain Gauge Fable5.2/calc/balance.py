"""Anchor balance: the anchor (pallets + arm) must not bias the bucket, so its counterweight is sized until
the centre of mass sits on the pivot axis.  usage: balance.py [cw_r cw_a0 cw_a1]   (needs OPENSCAD)"""
import os, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(__file__)); import stl_tools
here=os.path.dirname(os.path.abspath(__file__)); scad=os.path.join(here,'..','mechanical-rain-gauge.scad')
osc=os.environ.get('OPENSCAD','openscad'); RHO=1.27e-3
def measure(over=()):
    out=os.path.join(tempfile.gettempdir(),'anchor_bal.stl'); cmd=[osc,'-o',out,'-D','part="anchor"']
    for k,v in over: cmd+=['-D',f'{k}={v}']
    subprocess.run(cmd+[scad],capture_output=True,check=True)
    V,C=stl_tools.vol_centroid(stl_tools.load(out)); return V,C
if __name__=="__main__":
    a=sys.argv[1:]; over=list(zip(('cw_r','cw_a0','cw_a1'),a)) if a else []
    V,C=measure(over); px,py=0.0,float(os.environ.get('PIVOT_Z','36'))
    m=V*RHO; dx=-C[0]-px; dy=C[1]-py     # the anchor prints mirrored in x (front face down)
    print(f"anchor {m:.2f} g; centre of mass offset from pivot: x {dx:+.3f} mm, y {dy:+.3f} mm -> bias {m*dx:+.2f} g.mm sideways, {m*dy:+.2f} g.mm up")
