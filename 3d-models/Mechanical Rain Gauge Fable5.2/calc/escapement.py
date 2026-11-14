# Pin-wheel + driving anchor kinematics. P (anchor pivot) at origin, wheel centre W=(d,0).
import math,sys
def build(Rp=21.0,N=10,rpin=2.0,c=0.6,hb=4.5,h=7.0,o=5.5,g=1.5,tipw=1.0,hb1=3.5,g1=0.5):
    """Pallet polygons in polar form about the anchor pivot. Pallet 2 (at -psi) has blade hb / lead g;
    pallet 1 (at +psi, locking face outside) has a shorter blade hb1 / lead g1 so its tip clears the wheel sleeve."""
    half=math.radians(126/2); psi=math.pi/2-half   # 27 deg
    d=Rp/math.sin(psi); Lt=d*math.cos(psi)
    w=2*Rp*math.sin(math.radians(18))-2*rpin-c      # full tooth width
    def prof(s,b):
        if s<b: return tipw
        if s<b+h: return tipw+(w-tipw)*(s-b)/h
        return w
    def samples(b):
        L=b+h+o; return [i/2 for i in range(int(round(2*L))+1)]
    rb2=Lt-w/2; phi_tip2=-psi+g/Lt
    ss=samples(hb)
    p2=[(rb2,phi_tip2-s/Lt) for s in ss]+[(rb2+prof(s,hb),phi_tip2-s/Lt) for s in reversed(ss)]
    rb1=Lt+w/2; phi_tip1=psi-g1/Lt
    ss=samples(hb1)
    p1=[(rb1,phi_tip1+s/Lt) for s in ss]+[(rb1-prof(s,hb1),phi_tip1+s/Lt) for s in reversed(ss)]
    return dict(d=d,Lt=Lt,w=w,p1=p1,p2=p2,Rp=Rp,N=N,rpin=rpin,psi=psi)
def cart(poly,th): return [(r*math.cos(a+th),r*math.sin(a+th)) for r,a in poly]
def dist_poly(pt,poly):  # signed: negative inside
    x,y=pt; best=1e9; inside=False; n=len(poly)
    for i in range(n):
        x0,y0=poly[i];x1,y1=poly[(i+1)%n]
        dx,dy=x1-x0,y1-y0; L2=dx*dx+dy*dy
        t=max(0,min(1,((x-x0)*dx+(y-y0)*dy)/L2)) if L2>0 else 0
        best=min(best,math.hypot(x-x0-t*dx,y-y0-t*dy))
        if (y0>y)!=(y1>y) and x<(x1-x0)*(y-y0)/(y1-y0)+x0: inside=not inside
    return -best if inside else best
def clear(G,th,om):  # min clearance pins vs pallets
    P1=cart(G['p1'],th);P2=cart(G['p2'],th); m=1e9
    for i in range(G['N']):
        a=om+2*math.pi*i/G['N']; pt=(G['d']+G['Rp']*math.cos(a),G['Rp']*math.sin(a))
        if pt[0]>G['d']: continue
        m=min(m,dist_poly(pt,P1)-G['rpin'],dist_poly(pt,P2)-G['rpin'])
    return m
def play(G,th,om,lim=math.radians(30)):
    st=math.radians(0.05); f=0
    while f<lim and clear(G,th,om+f+st)>=0: f+=st
    b=0
    while b<lim and clear(G,th,om-b-st)>=0: b+=st
    return math.degrees(f),math.degrees(b)
def cycle(G,th0=21.0,strokes=2):
    """Swing the anchor -th0 -> +th0 -> -th0 ... and let the pallets push the wheel. Returns per-stroke stats and a pose table."""
    om=math.radians(117+18); th=math.radians(-th0); st=math.radians(0.05)
    assert clear(G,th,om)>=0,("start penetrates",clear(G,th,om))
    # settle into the middle of the play
    f,b=play(G,th,om); om+=math.radians((f-b)/2)
    out=[]; table=[]
    for sidx in range(strokes):
        sgn=1 if sidx%2==0 else -1; om0=om; push=None; done=None; k=0; maxback=0
        while sgn*th<math.radians(th0)-1e-9:
            th+=sgn*st; k+=1
            if clear(G,th,om)<0:
                if push is None: push=sgn*math.degrees(th)
                moved=0
                while clear(G,th,om)<0:
                    om+=math.radians(0.02); moved+=0.02
                    if moved>25: return dict(jam=(sidx,math.degrees(th)))
            if k%20==0:
                f,b=play(G,th,om); maxback=max(maxback,b)
                table.append((sidx,round(math.degrees(th),2),round(math.degrees(om-math.radians(135))+min(0.4,f/2),3)))
            if done is None and math.degrees(om-om0)>17.0: done=sgn*math.degrees(th)
        f,b=play(G,th,om)
        out.append(dict(stroke=sidx,adv=round(math.degrees(om-om0),2),push_start=round(push,2),done=round(done,2),end_play=(round(f,2),round(b,2)),max_back_window=round(maxback,1)))
    return dict(strokes=out,total=round(math.degrees(om)-135,2),table=table)
if __name__=="__main__":
    import json
    G=build()
    print({k:round(v,3) for k,v in G.items() if isinstance(v,float)})
    for th0 in (18.5,20,21.5):
        r=cycle(G,th0)
        print("theta0",th0,json.dumps(r.get('strokes',r)), "total",r.get('total'))
    r=cycle(G,21.5,strokes=4)
    print("4 strokes total advance (expect 72):",r['total'])
    import itertools
    for th0 in (20,21.5):
        for name,poly,sg in (("pallet1",G["p1"],-1),("pallet2",G["p2"],1)):
            m=min(math.hypot(x-G["d"],y) for x,y in cart(poly,math.radians(sg*th0)))
            print(f"{name} closest approach to wheel centre at tilt {th0}: {m:.2f} mm")
    r=cycle(G,21)
    print("// pose table [stroke, anchor_deg, wheel_advance_deg]")
    print("esc_table = [" + ", ".join("[%d,%g,%g]"%t for t in r['table'] if abs(t[1])%3<0.06 or abs(abs(t[1])-21)<0.06) + "];")
