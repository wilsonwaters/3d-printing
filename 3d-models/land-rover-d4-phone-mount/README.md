# Land Rover Discovery 4 Phone Mount

A one-piece bracket that plugs into the recessed notch on the dash just left of the
instrument binnacle (right-hand-drive 2013 Discovery 4, Australian market), under the
leather hood, and carries a **LISEN W116 Qi2.2 25 W** magnetic wireless charger on a
standard **17 mm ball**. It holds the phone **5 cm higher** than a charger clipped straight
into the notch, reclined about 25° toward your eyes. It's built for corrugations and
four-wheel driving, not just bitumen.

![In the car — side view](preview-car-side.png)

- One piece, **ASA**, ~90 g, no supports, no holes in the trim.
- A wedge fills the notch. Its sloped bottom sits on the whole ledge, its top follows the
  hood's underside with an EPDM strip pressing up into it, and two small patches of 3M VHB
  hold its back face, which is dished 2 mm to sit on the trim.
- A 25 mm-deep upright rises from the line of the hood lip, then bends back over the hood.
  A "head" near its top has a flat face square to the ball stalk, which ends in a printed
  17 mm ball. The W116 head clamps straight onto the ball, with no vent clip in between to
  rattle.
- Snap-in groove all the way down the sloping front of the wedge, right under the
  charger's USB-C port.
- A rip-cord groove across the back means it comes off again without damage.
- Strength is checked by the model itself (see [Off-road strength](#off-road-strength)).

![From the driver's seat](preview-car-driver.png)

## How it sits in the car

The notch's back face, where the tape goes, **leans back about 45°** (its top toward the
windscreen). The model is drawn square to that face: its "up" runs up the face and "out"
is square to it, and every angle and height in the file and in this README is measured
that way unless it says "in the car". So in the car:

| | Measured from the back face | In the car |
|---|---|---|
| Lower part of the upright | straight up the face | leans back ~45° |
| Upper part of the upright | leans back 15° (`upright_lean`) | leans back ~60° |
| Ball stalk | 20° below square-out (`neck_angle = −20`) | ~25° above level, so the phone reclines toward your eyes |

`trim_rake = 45` in the file only turns the drawings and reports these angles. It doesn't
change the part.

## Measurements

Most of these are now **measured or set from your test fits**. `hood_t`, `notch_w` and
the cluster-side return are still **estimates from photos**. Change them at the top of
`d4-phone-mount-v1.scad`, or send them to Claude and it'll re-export:

![What to measure](measure-guide.svg)

| Parameter | What it is | Default |
|---|---|---|
| `notch_h` | Floor ledge up to the underside of the leather hood, measured at the back of the notch | **65 mm** (measured) |
| `hood_over` | How far the hood's front lip sticks out past the back face | **40 mm** (measured) |
| `hood_slope` | The hood's underside closes in toward you: it meets the back face at 90° minus this. The wedge's top follows it | **15°** (test fit) |
| `back_sag` | How far the back face bulges toward you: a ruler held up-and-down rocks on it with this gap at each end. The wedge's back is dished to match. 0 = flat | **2 mm** (test fits: 4 was too deep, flat not quite enough) |
| `hood_t` | Thickness of the hood's lip, underside to top of the leather. The build uses it to check the leaning part clears the lip | 20 mm, **estimate** |
| `floor_depth` | How far the ledge runs out from the back face | **30 mm** (measured, approx) |
| `floor_drop` | How far the ledge falls away 30 mm out, measured square to the back face | **18 mm** (test fit: the bottom's angle opened about 20° from the first guess of 6) |
| `notch_w` | Width across the mouth of the notch | 40 mm |
| `vent_return` | Vent-side wall: `[how far it steps in by the back face, how deep that angled part runs]` | **`[0, 0]`**, square (test fit) |
| `cluster_return` | Cluster-side wall, same meaning (`[0, 0]` = square corner) | `[2, 2]` |

Where you want the charger (set from your test fits):

| Parameter | What it is | Default |
|---|---|---|
| `upright_front` | Back face of the notch → the driver-side face of the upright, tape included. The upright grows toward the dash from here | 65 mm (where it test-fitted) |
| `up_d` | How deep the upright is, front to back | 25 mm |
| `block_bottom_d` | How much of the ledge the wedge's bottom sits on (see [why not 10 mm](#why-the-bottom-uses-the-whole-ledge)) | 30 mm (all of it) |
| `rise` | Top of the notch (the hood's underside where it meets the back face) → centre of the ball, up the face: how much higher than a charger clipped straight into the notch ("5 cm up") | 50 mm |
| `knee_above_hood` | Where the upright starts to bend back, above the top of the notch | 24 mm |
| `upright_lean` | Above the bend, the upright leans back toward the windscreen by this much (plus the face's 45° in the car) | 15° |
| `neck_angle` | Ball stalk angle to square-out from the back face. Add 45° for the angle above level in the car | −20° (≈ 25° up in the car) |
| `beam_side` | Which side of the notch the upright rides on, seen from the driver's seat | `"left"` (vent side, clear of the gauges) |

> **Where the charger ends up:** clipped straight into the notch, the charger's ball
> would sit about level with the top of the notch (where the clip hooks in, right under
> the hood). The bracket lifts it **50 mm above that**, measured up the back face. The ball
> is about 81 mm out from the back face, and the stalk points about 25° above level in the
> car, so with the ball joint centred the phone reclines toward your eyes. The joint does
> the fine aiming from there. If you want it higher, raise `rise`.
>
> **The upright and the hood lip:** the upright's back reaches the line of the hood's
> front lip (`hood_over` = 40 mm), because your earlier print showed room behind it. The
> hood's underside slopes down toward you, so the lip sits well below the bend, which
> starts 24 mm above the top of the notch. The lip thickness (`hood_t`) is still a guess;
> the build checks the leaning part clears the lip's corner with that guess, and the side
> template shows it for real.

**If the wedge rocks on the ledge:** `floor_drop` sets the slope of the wedge's bottom. If
in doubt, go 1 mm too steep rather than too shallow: the wedge then lands on the ledge's
front edge (the good spot) and the EPDM takes up the difference.

### Test prints first (about 20 minutes)

![The two templates](preview-gauge.png)

1. **`part="gauge"`**: two 2.4 mm templates on one plate.
   - *Side template*: stand it in the notch, back edge on the back face and the sloped
     bottom edge on the ledge. The bottom should sit flat on the ledge, not rock on its
     back corner; if it rocks, `floor_drop` is off. The top edge should run about 2 mm under
     the hood's underside all the way out, which is the EPDM gap; if the gap closes up at
     one end, `hood_slope` is off. The little V on the top edge, at the back of the
     upright, should line up with the hood's front lip, and the bend should clear the
     lip's top. The disc shows where the ball, and so the charger, will be.
   - *Plan template*: slide it in flat at mid height. It should reach the back face
     without binding on the sides. The hole marks the vent side.
2. **`part="ball_test"`**: a small block with the neck and ball, printed exactly like
   the real one. Check the W116's socket clamps it firmly. If it's too tight or loose,
   change `asa_shrink` (1.004 looser … 1.008 tighter) and re-export.

For a full-size fit check, `d4-phone-mount-fit-test-pla.3mf` prints the whole bracket in
PLA on a fast, low-filament draft profile. It isn't strong enough to use in the car.

## Fitting

1. **Dry-fit first.** Push the bracket in with the EPDM strip on and no tape, and check
   it seats against the back face with the EPDM squashed under the hood. Until it's taped
   it can ease back out as the foam springs back, so don't rely on the dry fit to hold it.
2. Stick a strip of **soft closed-cell EPDM foam tape**, about 3 mm (compresses to 2), on
   the block's top face, the part that goes under the hood. Run it right to the back edge
   and across the full width: the back edge is where it does the work. Soft foam is
   better than firm here: it only has to keep contact, and a firm strip squashed hard
   pushes the wedge back out of the notch. Use EPDM rather than felt, because felt takes a
   set and the wedge goes loose.
3. Lay a length of **braided fishing line** in the groove across the back face. Tuck
   its ends down the two sides of the block, where they'll sit in the gaps beside the
   notch walls. This is the rip cord.
4. Clean the notch's back face with isopropyl alcohol. Car trim is often
   low-surface-energy plastic, so a wipe of **3M adhesion promoter (94 or 4298UV)**
   makes VHB grip far better.
5. Put **3M VHB 5952** (black, 1.1 mm) on the back face below the rip-cord groove:
   three strips about 30 × 15 mm (high, middle, low), or one piece about 30 × 45 mm.
   The notch takes the phone's load, and the tape stops the block sliding out. The ledge
   falls away steeply and the squashed EPDM pushes the wedge outward all the time, so the
   tape carries that steadily in a hot cabin; more tape area keeps it from creeping.
   **Don't drive with it dry-fitted**: without the tape it will slowly walk out on
   corrugations.
6. Slide the block in, EPDM first under the hood lip, until the tape meets the back face,
   then press hard for 30 s. Leave it 24 h before hanging the charger on it.
7. Unscrew the W116 head's collar, pop the head onto the printed ball, tighten the
   collar and aim it. It'll want to yaw right, toward you. The neck is kept round on
   that side, so nothing fouls the collar.
8. Clip the USB-C lead into the groove down the sloping front of the wedge. It runs all
   the way to the bottom corner, where a small pocket lets the lead bend over the ledge's
   edge without getting pinched under the wedge.

**Removing it:** pull the two rip-cord ends down and forward with a sawing motion. The
line cuts through the tape. If the line has gone, warm the block with a hair dryer (VHB
softens) and ease it straight out. Adhesive remover takes off any residue.

## Why it's shaped like this

**The notch does the holding; the tape stops it walking.** The model checks the worst
case: the phone's load pulling straight down the back face, trying to tip the wedge out
of the notch about the front edge of its bottom, where it sits on the ledge. Behind that
edge, the top of the wedge pushes up into the hood, where it's already wedged by the
EPDM. The tape on the back face is loaded in *shear*, VHB's strongest direction, and
nothing asks it to hold the phone's weight in peel. In the car the back face leans back
45°, so the phone's weight actually tips the wedge back into the trim; it's jolts toward
you that bring the worst case on.

### Why the bottom uses the whole ledge

Only the hood contact **behind** the pivot pushes back, so the deeper the bottom sits on
the ledge, the longer that lever and the less the EPDM gets squashed. The sloped hood
helps too: it pushes back and down at once, so it has more leverage about the pivot. The
model works this out and asserts it:

| Wedge bottom on the ledge | Push on the EPDM in a 4 g bump | Pressure on the EPDM |
|---|---|---|
| **30 mm (the whole ledge, default)** | **37 N** (9 N sitting still) | **0.05 MPa** peak, well under the 0.15 limit |
| 10 mm | 76 N (19 N sitting still) | 0.27 MPa peak: crushes the foam, so it rocks |

(The pressure peaks at the back edge of the strip, because the wedge pivots about its
front.) A bottom a little *longer* than the ledge is harmless: it just pivots on the
ledge's edge.

So the bottom follows your ledge's slope all the way out. It's still a wedge, just
30 mm at the bottom rather than 10. The plastic itself would be fine either way; it's
the grip on the car that changes. A flat bottom on a sloping ledge would be worst of
all: it touches only at its back corner, and the tape ends up doing all the work.

**Printed lying on its side.** The flat side of the upright goes on the plate, so the
whole side profile prints flat. The phone's weight and every bump bend the block,
upright, neck and ball in the plane of the layers. Nothing is loaded across a layer
line, which is where FDM parts break.

**Integral ball, not a vent clip.** The shortest, stiffest path from dash to charger,
and nothing with jaws to vibrate loose on corrugations.

**The neck tapers, and it's round where it matters.** It starts Ø14 at the head and
tapers gently to Ø10 only for the last few mm, where the socket needs room to swing.
There's no sharp shoulder at the most-stressed point, which matters for vibration
fatigue. This is the exact neck you test-fitted, and the ball joint worked well on it.
Printing a ball on its side needs something under it, so:

- The root has a keel running down to the plate, with sides no steeper than 40°.
- The rest is cut flat underneath and prints as a ~9 mm bridge, as on your test print.
  The keel stops at the root on purpose: the LISEN collar nut sits within about 5 mm of
  the face the neck comes out of, so anything extra there would foul it.
- The ball gets an 8 mm flat where it touches the plate.

All of that is on the vent side. When you swing the charger right toward yourself, the
collar closes on the neck's *right* side, which is kept round, so you keep the full
range of the ball joint.

**The head.** The upper part of the upright leans back 15° from the face, but the stalk
points 20° below square-out, so a stalk straight out of the leaning face would aim 35°
too high. Instead, the stalk comes out of a small head whose face is square to it. The
collar nut sits about 5 mm from that face, just as it sat 5 mm from the flat upright on
your test print, so the joint swings the same way. Below the stalk, the leaning face
angles back toward the collar, so the head's flat face runs 10 mm below the stalk before
it meets it. That leaves about 3 mm between the leaning face and a centred collar nut
(the build checks this, assuming a 26 mm nut), and the nut can't reach the upright at any
tilt of the joint.

**The upright.** It rises from the line of the hood lip, then bends back over the hood.
It's 25 mm deep, 5 mm deeper toward the dash than the print before last, where you found
room. Its front face hasn't moved.

**The back is dished 2 mm and the top slopes with the hood.** The trim face bulges gently
toward you, so the back is a matching shallow arc (`back_sag`). The hood's underside closes
in toward you by about 15°, so the wedge's top follows it (`hood_slope`) and the EPDM gap
stays even all the way out.

## Off-road strength

The file computes the load path and asserts it on every build. Design case: a **0.45 kg**
charger plus big phone in a case, at **4 g** (washouts, corrugations, a hard landing) and
**1.5 g** sideways, with the main load taken straight down the back face (the worst
direction for the wedge; see above). The allowable is printed ASA strength derated to
**60 %** for a hot parked cabin, then divided by a **2.5 safety factor**. Sections are
treated as what the printer really makes: 6 solid perimeters around a 20 % infill core.

| Section | Stress at the design case | Allowable |
|---|---|---|
| Neck where the slim Ø10 part starts (worst point) | 6.3 MPa | 7.2 MPa |
| Neck root at the head (Ø14) | 3.3 MPa | 7.2 MPa |
| Upright where it leaves the wedge (16 × 25) | 0.7 MPa | 7.2 MPa |
| Neck, sideways jolt | 2.4 MPa | 7.2 MPa |

The EPDM under the hood peaks at 0.05 MPa at the same design case (limit 0.15 MPa, see
above). The slim neck is the tightest spot, which is why it's only Ø10 for the last few mm.
Raise `design_mass_kg` for a heavier phone, or change `walls`/`infill`, and the build
tells you if it stops adding up.

**Heat:** ASA softens around 100 °C and is UV-stable. PETG (≈80 °C) would slowly creep
under the phone in a car parked in the sun, and PLA (≈55 °C) would sag in a day.

## Printing

![As it sits on the plate](preview-print.png)

| | |
|---|---|
| Material | **ASA**, dried (80 °C, 4–6 h) |
| Printer | Bambu X1C (enclosed), door and lid closed. ASA gives off styrene, so print in a ventilated room |
| Layer height | 0.2 mm |
| Walls | **6 perimeters** (2.7 mm), which makes the neck and ball mostly solid |
| Infill | 20 % gyroid |
| Top / bottom shells | 5 layers |
| Supports | **Off** (see below) |
| Cooling | Part fan off, except a 30–50 % burst on bridges (Bambu's ASA profiles already do this) |
| Brim | 8 mm, outer only |
| Elephant-foot compensation | **0**, it's built into the model |
| Orientation | As modelled: lying on its side, the upright's flat face on the plate |
| Time / material | roughly 5 h, ~90 g |

`d4-phone-mount-v1.3mf` is a Bambu Studio project with all of this already applied
(X1C, 0.20 mm Standard, Generic ASA). Open it, check the plate, slice.

**About Bambu's support preview.** Every overhang on the part is 40° or less. So if you
turn supports on with a 45° threshold just to look, Bambu should only mark two small spots.
Any ball printed on its side has them:

- the ~9 mm bridge under the neck, which printed fine on your test piece;
- the first ~2 mm of the ball above its flat.

Both print fine with supports off; bridges get the fan burst. Don't add supports under the
ball, because support marks there would sit where the socket grips. If the ball test shows
a rough lower edge on the ball, tell Claude.

## Tuning

| Want | Change |
|---|---|
| Doesn't fit the notch | `notch_h`, `notch_w`, `vent_return`, `cluster_return`, `hood_over` |
| Wedge rocks on the ledge | `floor_drop` (the bottom's slope) |
| Top doesn't sit evenly under the hood | `hood_slope` (the angle between the back face and the top) |
| Back doesn't sit flat on the trim | `back_sag` (0 = flat) |
| Shorter wedge bottom | `block_bottom_d`; the build refuses if the EPDM would be overloaded |
| Charger further out / closer | `upright_front` moves the whole upright |
| Upright deeper / shallower | `up_d` (grows toward the dash; the build refuses if it would reach behind the hood lip) |
| Charger higher / lower | `rise` (from the top of the notch, up the back face) |
| Charger further back / forward | `upright_lean` (0 = straight up the back face) |
| Bend higher / lower | `knee_above_hood`; the build checks the leaning part still clears the lip (using `hood_t`) |
| Charger aimed higher / lower by default | `neck_angle` (the head turns with it) |
| Upright on the cluster side | `beam_side = "right"`, but note the neck's keel then sits on the driver side and limits how far the charger swings right |
| Ball too tight / loose in the socket | `asa_shrink` |
| Thicker USB-C lead | `cable_d` |
| Wobbles on corrugations | `up_d` (stiffer upright), and check the EPDM is compressed |
| Heavier phone | `design_mass_kg` |

## Files

- `d4-phone-mount-v1.scad`: the parametric OpenSCAD model (all dimensions plus strength
  and fit contracts). `part = "bracket" | "gauge" | "ball_test"`.
- `d4-phone-mount-v1.stl` / `.3mf`: the bracket. The 3MF is a Bambu Studio project with
  the ASA settings baked in.
- `d4-phone-mount-fit-test-pla.3mf`: the same bracket as a PLA draft print, for checking
  the fit only (0.28 mm Extra Draft, 2 walls, 8 % lightning infill, no brim).
- `d4-phone-mount-gauge.stl`, `d4-phone-mount-ball-test.stl`: the test prints.
- `measure-guide.svg`: what to measure, drawn as it sits in the car.
- `preview-*.png`: renders (the car views are tilted to the 45° back face).

Preview-only aid: `openscad -D show_context=true d4-phone-mount-v1.scad` ghosts the notch
floor, back face and hood around the part.
