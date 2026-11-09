# MATLAB readout model

Simulates the full readout over time (fork in 3He, TIA, gain stage, ADC, lock-in, tracker) and compares four tracking methods on the same fork, noise and temperature profile. Needs the Control System Toolbox (`tf`, `c2d`).

## How to run

- `run_sim.m`: one method. Set `method` at the top (`'vna'`, `'pll'`, `'dfrt'`, `'pdh'`) and press Run.
- `compare_methods.m`: all four, then a summary table and an overlay of the temperature error.

A 60 s run takes a few seconds.

## Files

| File | What it does |
|---|---|
| `params.m` | Every constant, with where it comes from |
| `fork_params.m` | Temperature to Rm, Lm and width (helium law) |
| `width_to_T.m` | Width back to temperature (the same law, inverted) |
| `fork_filter.m` | Fork motional branch as a digital filter (`c2d`, ZOH) |
| `make_drive.m` | Drive tones, phase-continuous across blocks, optional phase modulation |
| `frontend.m` | C0 feedthrough, input current noise, TIA |
| `adc.m` | Gain, clip, quantize |
| `lockin.m` | I/Q lock-in, one channel per tone |
| `lorentz_fit.m` | Complex Lorentzian fit of a sweep: f0, width, peak amplitude and phase |
| `tracker_vna.m` | Stepped sweep plus fit |
| `tracker_pll.m` | Locks to the phase at resonance, width from amplitude |
| `tracker_dfrt.m` | Two tones, one loop for center and one for spacing |
| `tracker_pdh.m` | Phase-modulation lock for f0, periodic sweep for width |
| `simulate.m` | The block-by-block time loop |
| `evaluate.m` | Error, settle time, update interval, plots |

## How a block works

Each 10 ms block: the temperature sets Rm and Lm, the drive plays the tracker's frequency, the samples go through fork, TIA, ADC and lock-in, and the tracker reads the lock-in and picks the next frequency. All filter states carry over between blocks, so the fork keeps ringing across block edges.

PLL, DFRT and PDH all start with VNA sweeps to find the resonance, then switch to tracking.
