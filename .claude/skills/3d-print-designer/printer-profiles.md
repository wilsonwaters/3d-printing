# Printer Profiles Database

Known printer specifications for auto-populating printer settings. When a user provides a make and model, look up the specs here. If the printer is not listed, ask the user for manual specs.

## How to Use This File

1. Match the user's printer to a profile below (case-insensitive, fuzzy match OK)
2. Present the matched specs to the user for confirmation ("I found specs for your Bambu Lab P1S -- does this look right?")
3. If no match, fall back to [Manual Spec Collection](#manual-spec-collection)
4. Apply the specs to the design parameters

## Bambu Lab

### Bambu Lab X1 Carbon / X1C

| Spec | Value |
|------|-------|
| Build Volume | 256 x 256 x 256 mm |
| Stock Nozzle | 0.4mm hardened steel |
| Supported Nozzles | 0.2, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.08 - 0.28mm (0.4mm nozzle) |
| Max Hotend Temp | 300C |
| Max Bed Temp | 120C |
| Heated Bed | Yes |
| Enclosure | Yes (passive, ~50C chamber) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (force sensor + LiDAR) |
| Multi-Material | Optional AMS (up to 4 units, 16 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, PA, PC, PVA, CF composites |
| Notes | Hardened nozzle handles abrasive filaments. Best Bambu for engineering materials. |

### Bambu Lab P1S

| Spec | Value |
|------|-------|
| Build Volume | 256 x 256 x 256 mm |
| Stock Nozzle | 0.4mm stainless steel |
| Supported Nozzles | 0.2, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.08 - 0.28mm (0.4mm nozzle) |
| Max Hotend Temp | 300C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | Yes (passive, ~45-50C chamber) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (force sensor) |
| Multi-Material | Optional AMS (up to 4 units, 16 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, PVA, PA (with caution) |
| Notes | 100C bed limits PC printing. Enclosure enables ABS/ASA. |

### Bambu Lab P1P

| Spec | Value |
|------|-------|
| Build Volume | 256 x 256 x 256 mm |
| Stock Nozzle | 0.4mm stainless steel |
| Supported Nozzles | 0.2, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.08 - 0.28mm (0.4mm nozzle) |
| Max Hotend Temp | 300C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (open frame) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (force sensor) |
| Multi-Material | Optional AMS (up to 4 units, 16 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU |
| Notes | No enclosure -- ABS/ASA not recommended. Otherwise same platform as P1S. |

### Bambu Lab A1

| Spec | Value |
|------|-------|
| Build Volume | 256 x 256 x 256 mm |
| Stock Nozzle | 0.4mm stainless steel |
| Supported Nozzles | 0.2, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.08 - 0.28mm (0.4mm nozzle) |
| Max Hotend Temp | 300C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (open frame, bed-slinger) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (force sensor) |
| Multi-Material | Optional AMS Lite (up to 4 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU |
| Notes | Bed-slinger design. No enclosure limits to PLA/PETG/TPU. AMS Lite has fewer slots than full AMS. |

### Bambu Lab A1 Mini

| Spec | Value |
|------|-------|
| Build Volume | 180 x 180 x 180 mm |
| Stock Nozzle | 0.4mm stainless steel |
| Supported Nozzles | 0.2, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.08 - 0.28mm (0.4mm nozzle) |
| Max Hotend Temp | 300C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (open frame) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (force sensor) |
| Multi-Material | Optional AMS Lite (up to 4 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU |
| Notes | Small build volume. Good for small parts only. |

## Prusa

### Prusa MK4S / MK4

| Spec | Value |
|------|-------|
| Build Volume | 250 x 210 x 220 mm |
| Stock Nozzle | 0.4mm brass (Nextruder) |
| Supported Nozzles | 0.25, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 290C |
| Max Bed Temp | 120C |
| Heated Bed | Yes |
| Enclosure | No (optional aftermarket / Prusa Enclosure) |
| Extruder Type | Direct Drive (Nextruder) |
| Auto Bed Leveling | Yes (load cell / strain gauge) |
| Multi-Material | Optional MMU3 (5 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS (with enclosure), ASA (with enclosure), PA, PC |
| Notes | 120C bed handles PC. Lack of stock enclosure limits ABS in practice. Asymmetric bed (250x210). |

### Prusa MK3S+ / MK3S

| Spec | Value |
|------|-------|
| Build Volume | 250 x 210 x 210 mm |
| Stock Nozzle | 0.4mm brass (E3D V6) |
| Supported Nozzles | 0.25, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 280C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (optional aftermarket / Prusa Enclosure) |
| Extruder Type | Direct Drive (Bondtech) |
| Auto Bed Leveling | Yes (PINDA probe) |
| Multi-Material | Optional MMU2S (5 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS (with enclosure) |
| Notes | Legacy but still very popular. Asymmetric bed (250x210). |

### Prusa XL (Single/Multi-Tool)

| Spec | Value |
|------|-------|
| Build Volume | 360 x 360 x 360 mm |
| Stock Nozzle | 0.4mm brass (Nextruder) |
| Supported Nozzles | 0.25, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 290C |
| Max Bed Temp | 120C |
| Heated Bed | Yes (segmented) |
| Enclosure | No (optional aftermarket / Prusa Enclosure) |
| Extruder Type | Direct Drive (Nextruder, up to 5 toolheads) |
| Auto Bed Leveling | Yes (load cell per toolhead) |
| Multi-Material | Up to 5 independent toolheads (no purge waste) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS (with enclosure), ASA (with enclosure), PA, PC |
| Notes | Large build volume. Multi-tool = no purge tower waste. Segmented bed heats only area in use. |

### Prusa Core One

| Spec | Value |
|------|-------|
| Build Volume | 250 x 220 x 270 mm |
| Stock Nozzle | 0.4mm brass (Nextruder) |
| Supported Nozzles | 0.25, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 290C |
| Max Bed Temp | 120C |
| Heated Bed | Yes |
| Enclosure | Yes (fully enclosed with active airflow) |
| Extruder Type | Direct Drive (Nextruder) |
| Auto Bed Leveling | Yes (load cell) |
| Multi-Material | Optional MMU3 (5 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, PA, PC |
| Notes | Prusa's first enclosed CoreXY. Handles all materials well. |

## Creality

### Creality K1C

| Spec | Value |
|------|-------|
| Build Volume | 220 x 220 x 250 mm |
| Stock Nozzle | 0.4mm hardened steel |
| Supported Nozzles | 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.10 - 0.30mm |
| Max Hotend Temp | 300C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | Yes |
| Extruder Type | Direct Drive (all-metal, dual-gear) |
| Auto Bed Leveling | Yes (LiDAR + strain sensor) |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, CF composites |
| Notes | Hardened nozzle for CF. Enclosed for ABS. No multi-material. |

### Creality K1 / K1 Max

| Spec | Value |
|------|-------|
| Build Volume | 220 x 220 x 250 mm (K1) / 300 x 300 x 300 mm (K1 Max) |
| Stock Nozzle | 0.4mm brass |
| Supported Nozzles | 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.10 - 0.30mm |
| Max Hotend Temp | 300C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | Yes |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA |
| Notes | K1 Max has larger build volume. Brass nozzle -- avoid CF filaments. |

### Creality Ender 3 V3 / V3 SE / V3 KE

| Spec | Value |
|------|-------|
| Build Volume | 220 x 220 x 250 mm |
| Stock Nozzle | 0.4mm brass |
| Supported Nozzles | 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.10 - 0.30mm |
| Max Hotend Temp | 260C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (open frame) |
| Extruder Type | Direct Drive (V3/KE) / Bowden (V3 SE) |
| Auto Bed Leveling | Yes (CR Touch or strain sensor) |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU (direct drive models only) |
| Notes | Budget printer. 260C hotend limits material options. No enclosure. V3 SE uses Bowden -- limited TPU. |

### Creality Ender 3 / Ender 3 Pro / Ender 3 V2

| Spec | Value |
|------|-------|
| Build Volume | 220 x 220 x 250 mm |
| Stock Nozzle | 0.4mm brass |
| Supported Nozzles | 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.10 - 0.30mm |
| Max Hotend Temp | 255C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (open frame) |
| Extruder Type | Bowden |
| Auto Bed Leveling | No (manual, upgradeable) |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG |
| Notes | Legacy budget printer. Bowden limits TPU. No ABL stock. Very popular -- millions sold. Highly moddable. |

## Voron (Self-Sourced Kits)

### Voron 2.4

| Spec | Value |
|------|-------|
| Build Volume | 250x250x230 / 300x300x280 / 350x350x330 mm (varies by build) |
| Stock Nozzle | 0.4mm (E3D V6, Revo, or Dragon hotend) |
| Supported Nozzles | Any (user choice) |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 285-300C (depends on hotend) |
| Max Bed Temp | 120C (AC silicone heater) |
| Heated Bed | Yes (AC-powered) |
| Enclosure | Yes (fully enclosed, ~50-60C chamber) |
| Extruder Type | Direct Drive (Stealthburner/Clockwork2) |
| Auto Bed Leveling | Yes (Quad Gantry Leveling + probe or Tap) |
| Multi-Material | Optional (ERCF, Tradrack, etc.) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, PA, PC, CF composites |
| Notes | Self-sourced kit -- specs vary by build. CoreXY with 4 independent Z motors. Largest option for enclosed printing. Ask user for their specific build size. |

### Voron Trident

| Spec | Value |
|------|-------|
| Build Volume | 250x250x250 / 300x300x300 / 350x350x350 mm |
| Stock Nozzle | 0.4mm (user choice) |
| Supported Nozzles | Any |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 285-300C (depends on hotend) |
| Max Bed Temp | 120C |
| Heated Bed | Yes (AC-powered) |
| Enclosure | Yes (fully enclosed) |
| Extruder Type | Direct Drive (Stealthburner/Clockwork2) |
| Auto Bed Leveling | Yes (3-point Z leveling + probe or Tap) |
| Multi-Material | Optional |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, PA, PC, CF composites |
| Notes | Similar to 2.4 but with 3-point Z bed leveling instead of QGL. Slightly simpler build. |

### Voron 0.2

| Spec | Value |
|------|-------|
| Build Volume | 120 x 120 x 120 mm |
| Stock Nozzle | 0.4mm |
| Supported Nozzles | 0.2, 0.4mm |
| Layer Height Range | 0.05 - 0.25mm |
| Max Hotend Temp | 285-300C (depends on hotend) |
| Max Bed Temp | 120C |
| Heated Bed | Yes |
| Enclosure | Yes (fully enclosed) |
| Extruder Type | Direct Drive (Mini Stealthburner) |
| Auto Bed Leveling | Yes (probe or Tap) |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, PA, PC |
| Notes | Very small build volume. Designed for small, fast parts. Fully enclosed despite size. |

## Ankermake

### Ankermake M5 / M5C

| Spec | Value |
|------|-------|
| Build Volume | 235 x 235 x 250 mm |
| Stock Nozzle | 0.4mm brass |
| Supported Nozzles | 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.10 - 0.30mm |
| Max Hotend Temp | 260C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (open frame) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (M5) / No (M5C) |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU |
| Notes | 260C limit restricts to PLA/PETG/TPU. No enclosure. |

## Elegoo

### Elegoo Neptune 4 Pro / Neptune 4

| Spec | Value |
|------|-------|
| Build Volume | 225 x 225 x 265 mm |
| Stock Nozzle | 0.4mm brass |
| Supported Nozzles | 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.10 - 0.30mm |
| Max Hotend Temp | 300C |
| Max Bed Temp | 110C |
| Heated Bed | Yes |
| Enclosure | No (open frame) |
| Extruder Type | Direct Drive (Pro) / Bowden (base) |
| Auto Bed Leveling | Yes |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU (Pro only), ABS (limited without enclosure) |
| Notes | Neptune 4 Pro has direct drive; base Neptune 4 is Bowden. |

## Ratrig

### Ratrig V-Core 4

| Spec | Value |
|------|-------|
| Build Volume | 200x200x200 / 300x300x300 / 400x400x400 / 500x500x500 mm |
| Stock Nozzle | 0.4mm (user choice of hotend) |
| Supported Nozzles | Any |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 285-300C (depends on hotend) |
| Max Bed Temp | 120C |
| Heated Bed | Yes (AC or DC) |
| Enclosure | Optional (panels available) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (Beacon or similar) |
| Multi-Material | Optional |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS/ASA (with enclosure), PA, PC (with enclosure) |
| Notes | Semi-kit. Very large build options (up to 500mm). Ask user for their specific build size. |

---

## Manual Spec Collection

When the user's printer is not listed above, collect these specs in order of importance:

### Must-Have (affects model geometry directly)

1. **Build volume** (X x Y x Z in mm) -- "What is your printer's build volume / bed size?"
2. **Nozzle diameter** (mm) -- "What nozzle size are you using?" (default: 0.4mm)

### Important (affects material and feature choices)

3. **Max hotend temperature** (C) -- "What's the maximum hotend/nozzle temperature?"
4. **Enclosure** (yes/no) -- "Does your printer have an enclosure?"
5. **Max bed temperature** (C) -- "What's the maximum bed temperature?"
6. **Extruder type** (direct drive / bowden) -- "Is your extruder direct drive or Bowden?"

### Nice-to-Have (affects advanced features)

7. **Auto bed leveling** (yes/no) -- "Does it have auto bed leveling?"
8. **Multi-material** (yes/no, type) -- "Does it support multi-material printing (AMS, MMU, etc.)?"

### Sensible Defaults (when user doesn't know)

| Spec | Default | Rationale |
|------|---------|-----------|
| Nozzle diameter | 0.4mm | Standard on nearly all printers |
| Layer height | 0.2mm | Good balance of speed and quality |
| Max hotend temp | 260C | Conservative; covers PLA/PETG |
| Max bed temp | 100C | Common for mid-range printers |
| Enclosure | No | Most consumer printers are open frame |
| Extruder | Direct Drive | Increasingly standard on modern printers |
| ABL | Yes | Standard on modern printers |
| Multi-material | No | Most setups are single material |
| Filament diameter | 1.75mm | Near-universal standard |
