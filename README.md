# Resonant Tuning Fork Thermometry — Readout Electronics

Colorado School of Mines Capstone project F26-4.3, sponsored by Maybell Quantum.

## Goal

Develop a manufacturable, self-contained thermometer that uses a quartz tuning
fork immersed in liquid ³He/⁴He to measure the temperature of a dilution
refrigerator cooling plate down to **7 mK**, accurate to **±1 mK**, with a new
reading at least every **30 s**.

This repository holds the readout side of the system: the electronics that drive
the fork, measure its resonant response, and convert it to a temperature.

## Key requirements

| Requirement | Target |
| --- | --- |
| Accuracy at lower limit | ±1 mK |
| Lower measurement limit | 7 mK |
| Polling interval | < 30 s (stretch: < 10 s) |
| Displayed values | Drive voltage, response current, frequency, temperature |
| Integration | Secondary equipment rack, existing power supplies |
| Calibration | Method for fork-to-fork manufacturing variance |
| Environment | Reliable at mK temperatures and fields up to 14 T |
| In-fridge impact | Minimal EMI/noise and heat load from wiring |

## System overview

- **Helium Thermometry Cell (HTC):** sealed cell holding the He mixture and the tuning fork.
- **Readout device:** drives the fork, measures its response, computes and displays temperature.
- **Interconnect:** low-noise, low-heat-load wiring between the HTC and the readout.

## Repository layout

- `hardware/pcb/` — readout schematic and layout (KiCad)
- `hardware/datasheets/` — component datasheets
- `firmware/` — readout interface code
- `docs/` — project plan, requirements, meeting notes
- `test/` — validation and calibration data

## Status

Requirements phase; readout circuit simulations (SPICE, MATLAB) starting October 2026.

## Team

Evan Christie, Enzo Guglielmo, Nathan Johnston, Ryan Montoya, Zurin Trzaska,
Anastasiia Usmanova. Project advisor: Eric Brighton.
