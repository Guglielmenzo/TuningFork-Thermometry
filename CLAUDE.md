# CLAUDE.md — tuning-fork-readout-pcb

## Current status

Project scaffolding only — no schematic, requirements doc, or firmware yet.
This is a senior design project: readout PCB and interface electronics for
Maybell Quantum's tuning fork thermometer.

## Next steps

1. Capture design requirements and any Maybell Quantum meeting notes in `docs/`.
2. Start schematic/layout in `hardware/pcb/` — KiCad is assumed as the tool
   unless told otherwise.
3. Collect relevant component datasheets in `hardware/datasheets/`.
4. Scope whether firmware (`firmware/`) is needed for the readout interface,
   and start once requirements are clearer.
5. Define validation/calibration test plan in `test/` once hardware exists.

## Notes for future sessions

- Tooling assumptions (KiCad, MCU choice, etc.) are placeholders — confirm
  with the user before committing to a toolchain if it's not already evident
  from files added to the repo.
