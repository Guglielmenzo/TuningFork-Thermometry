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
- `sim/` — LTspice simulations
  - `ltspice/` — schematics (`.asc`), netlists, plot settings
  - `data/` — exported waveforms/results (CSV/TXT)
  - `images/` — plots and screenshots
- `signal-processing/` — MATLAB signal processing
  - `scripts/` — `.m` / `.mlx` code
  - `data/` — input and processed data
  - `figures/` — generated plots
- `cad/` — mechanical CAD and production files
  - `models/` — part and assembly models
  - `production/` — fabrication and assembly outputs (Gerbers, drawings, BOMs)
- `firmware/` — readout interface code
- `docs/` — project plan, requirements, meeting notes
- `test/` — validation and calibration data

## Simulation

### Tuning fork model

The quartz tuning fork is modeled electrically with the Butterworth–Van Dyke
equivalent circuit:

![Tuning fork equivalent circuit](sim/images/tuning-fork-bvd-model.png)

- **Motional branch (L, R, C in series):** represents the fork's mechanical
  resonance. L corresponds to the effective mass of the tines, C to their
  stiffness, and R to the damping (energy lost to the surrounding fluid and
  internal losses). This branch carries the motional current I<sub>m</sub>.
- **Parallel capacitance C<sub>0</sub>:** the static capacitance of the fork's
  electrodes and leads, which carries the background current I<sub>c</sub>.
- **Drive and response:** the fork is driven with an AC voltage
  V<sub>0</sub>e<sup>iωt</sup>, and the measured output is the total current
  I<sub>e</sub> = I<sub>m</sub> + I<sub>c</sub>.

The motional branch resonates at f<sub>0</sub> = 1 / (2π√(LC)) with quality
factor Q = (1/R)√(L/C). In liquid helium, the fluid's density adds effective
mass (lowering f<sub>0</sub>) and its viscosity adds damping (raising R and
widening the resonance). Because the viscosity of the ³He/⁴He mixture depends
on temperature, the resonance frequency and width measured from I<sub>e</sub>
give the temperature.

### Circuit parameters

The L, R, C values are approximated from the fork's mechanical properties
using the model of Blaauwgeers et al. (2007), *Quartz Tuning Fork:
Thermometer, Pressure- and Viscometer for Helium Liquids*:

$$F_0 = \frac{a}{2}\,U_0$$

$$R = \frac{2m\gamma}{a^2}, \qquad L = \frac{2m}{a^2}, \qquad C = \frac{a^2}{2k}$$

The fork constant a can be found from the measured resonance,

$$a = \sqrt{\frac{4\pi m_e I_0\,\Delta f}{V_0}}$$

or, as defined in Blaauwgeers et al., from the circuit parameters,

$$a = \sqrt{\frac{2m\,\Delta\omega}{R}}$$

where F<sub>0</sub> is the driving force on the prongs, U<sub>0</sub> (V<sub>0</sub>)
the drive voltage amplitude, m (m<sub>e</sub>) the effective prong mass,
k the prong spring constant, γ the damping, I<sub>0</sub> the current amplitude
at resonance, Δf the resonance width, and Δω = 2πΔf.

## Status

Requirements phase; readout circuit simulations (SPICE, MATLAB) starting October 2026.

## Team

Evan Christie, Enzo Guglielmo, Nathan Johnston, Ryan Montoya, Zurin Trzaska,
Anastasiia Usmanova. Project advisor: Eric Brighton.
