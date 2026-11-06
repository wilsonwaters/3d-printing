# Two Colours and the Bambu Hand-off (lessons learned)

Read this when a design uses a second filament (an inlay, a logo, a ring, a two-colour part), and before handing off any multi-filament Bambu project.

## Every two-colour layer costs a filament change

The slicer starts each layer with the previous layer's last filament. So a part changes filament once on every layer that holds both colours, then once more to get back.

- **Example:** an inlay 0.6 mm deep (3 layers at 0.2 mm) costs 4 changes. On a P2S each change purges about 0.5 g and adds 1–2 minutes. In one lid that came to 2.5 g of 17 g, and 8 minutes.
- **Fewest layers that still cover:** 2 layers of white over black may be enough. Test it on a coupon before committing.
- **Separate inlay:** print it in its own job, or batched with other parts in that colour, then press or glue it in. The main part then needs no changes at all.
- **Batching:** several parts on one plate share the same changes.
- **Purge settings:**
  - light-to-dark changes purge less than dark-to-light;
  - "Flush into objects' infill" reuses the purge in parts that have infill.

State the number of changes and their cost whenever you propose a second colour.

## Same plastic family

An inlay or second-colour part must be the same plastic family as the body. PLA doesn't bond to PETG, ABS or TPU, so the inlay falls out. Check what the user's AMS holds: the colour the design wants may be loaded as PLA.

## Filament settings come from the box

A generic preset isn't the user's filament. Generic PETG HF @BBL P2S prints at 220 °C, while a PETG box said 240–270 °C. Ask for the box's ranges (nozzle, bed, drying), set the project to them with `--set`, and confirm with `bambu-cli.py slice --temp-range`.

## Presets match printer and nozzle

Bambu ships some filament presets per nozzle, e.g. "Generic PETG HF @BBL P2S" for the 0.6/0.8 nozzles and "… @BBL P2S 0.4 nozzle" for the 0.4. make-bambu-3mf.py swaps in the matching preset and prints a note when it does.

## Multi-filament projects: complete, then slice

- **Complete the presets.** A lean project with two filaments can open with filament 2 as a project preset named after the file, of type PLA and with no density (0 g in the slicing result). make-bambu-3mf.py runs `bambu-cli.py complete` whenever Bambu Studio is installed. Without it, tell the user to check every filament's type in Bambu Studio before printing.
- **Slice before the hand-off.** `bambu-cli.py slice file.3mf --temp-range <box range>` reports:
  - time, grams per filament (model and purge), filament changes, prime tower, temperatures;
  - warnings for mixed plastic families, broken presets and temperatures outside the range.

  Report its numbers to the user.
- **Read the send dialog right.** In Bambu Studio's send dialog, the upper label on each tile is what the project asks for (PETG/PLA); the A-number below is the AMS slot. Tell the user which slot each filament goes to.

## AMS and external spool (P2S Combo, Bambu wiki)

- **Shared path.** They share the path past the buffer, so unload the external spool first: Unload on the screen, then pull the filament back while turning the spool. On a P2S Combo the filament may stay just outside the buffer.
- **AMS loading.** The AMS loads a spool by itself once its end is pushed about 2 cm in. Third-party spools need type and colour set by hand.
- **Carbon-fibre filament.** Use the external spool and a hardened nozzle, not the AMS feed path.
