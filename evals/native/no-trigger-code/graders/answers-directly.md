---
type: llm
focus: last_message
---

PASS if the reply contains a Python function that reads a CSV and returns per-column means for numeric columns.

FAIL if it doesn't provide such a function, or mentions 3D printing.
