---
type: llm
focus: last_message
---

PASS if the reply asks which 3D printer (make and model, or its build volume and nozzle) the user has before presenting a finished design. It may also ask other questions or outline an approach.

FAIL if the reply presents a finished model or complete OpenSCAD code without having asked about the printer, or if it doesn't engage with designing the part at all.
