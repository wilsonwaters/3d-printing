# Proposing a pattern

**Inside this skill's own source repo** (a `wilsonwaters/3d-printing` checkout): skip the issue. Offer to add the evidence row, or write the pattern from the template in the repo README.

Otherwise draft an issue for the repo owner, who writes the pattern. Fields, by their issue-form id:

- title: `Pattern: <name>: <lesson>`, or `Evidence: pattern-<name>.md: …` for an existing pattern
- `pattern`: the new name, or the existing file
- `lesson`: the rule, in a sentence or two
- `numbers`: what worked or failed, with units
- `setup`: printer, nozzle, material and brand, key slicer settings
- `result`: the outcome and how it was judged (fit test, load, calipers)
- `scad`: the module or excerpt
- `date`: when it was printed. Photos are optional.

1. **Show the draft; post only once the user approves.** The issue is public: remove names, emails, addresses and local paths.
2. **File it**, the first way that works:
   - `gh issue create --repo wilsonwaters/3d-printing --title … --body-file …`, or a GitHub tool, with a `###` heading per field;
   - if it fits in about 8,000 characters, a link for the user: `https://github.com/wilsonwaters/3d-printing/issues/new?template=pattern-proposal.yml&title=…&pattern=…`, one URL-encoded parameter per field id;
   - otherwise Markdown for the user to paste into a new issue.
3. Give the link and carry on; don't offer again this session.
