# Signal Processing

This folder holds the MATLAB model of the full readout. It takes the tuning fork from the LTspice front end, runs it through the same chain the real electronics will use, and tracks how well each tracking method (VNA, PLL, DFRT, PDH) recovers the fork's resonance and the fridge temperature over time.

## Files

| File | What it does |
|---|---|
| [`scripts/readout_model.m`](scripts/readout_model.m) | Everything the trackers share: constants, the fork model, the TIA and its noise, the ADC and the lock-in |

## How a run works

The simulation steps through time in short **blocks** (10 ms each, about 330 fork cycles). In each block the drive frequency is held constant, and the loop does the following:

1. The tracker picks a drive frequency.
2. `readout_model` simulates the fork, TIA, gain stage, ADC and lock-in for that block and returns the lock-in output.
3. The tracker reads that output and updates its estimate of f0 and the resonance width.
4. The true and estimated temperatures are logged.

Filter states carry over from one block to the next, so the fork keeps ringing across block boundaries just like the real one. After every block has run, `evaluate` turns the log into error and timing results.

Inside each block the signal is a stream of samples at **500 kHz** (2 µs apart), about 15 per fork cycle.

## The signal chain

### Drive
A sine wave at the frequency the tracker chooses, about 1 mV in amplitude. Its phase carries over between blocks so there are no jumps.

### Fork
The fork is modeled as its motional branch (Rm, Lm, Cm in series). The inductance comes from the datasheet frequency and capacitance:

$$L_m = \frac{1}{(2\pi f_0)^2 C_m}$$

The current it passes for a given drive voltage is

$$\frac{I}{V} = \frac{sC_m}{s^2L_mC_m + sR_mC_m + 1}$$

Helium loading changes Rm and Lm with temperature, so the fork is rebuilt at the start of every block. Rm sets the resonance width and how long the fork takes to settle after the drive changes:

$$\Delta f = \frac{R_m}{2\pi L_m}, \qquad \tau = \frac{2L_m}{R_m}$$

After a frequency change, a tracker waits about 5τ before trusting the reading.

### TIA
The transimpedance amplifier turns the fork's tiny current into a voltage. It holds the sense line at virtual ground, so all the fork current flows through the feedback network Rf ∥ Cf:

$$\frac{V_{out}}{I_{in}} = -\frac{R_f}{1 + sR_fC_f}$$

At the fork frequency this is close to −Rf. Cf keeps the op-amp stable against the cable capacitance at its input:

$$C_f \ge \sqrt{\frac{C_{in}}{2\pi R_f \, GBW}}$$

The amplifier's input current noise is added here as white noise.

### Turning circuits into samples
MATLAB works one sample at a time, so the fork and TIA are converted with `c2d` (zero-order hold). For the TIA this gives a simple rule. Each new output keeps a fraction *a* of the last one and moves the rest of the way toward −Rf times the input, exactly like an RC circuit charging:

$$y[n] = a\,y[n-1] - R_f(1-a)\,x[n-1], \qquad a = e^{-\Delta t/(R_fC_f)}$$

### Gain stage and ADC
A programmable gain stage scales the signal so its peak sits around half of the ADC's range. The gain steps up as Rm grows at lower temperatures. The ADC then clips anything outside full scale and rounds to 16 bits:

$$\text{LSB} = \frac{V_{FS}}{2^{N}}$$

### Lock-in
The lock-in multiplies the samples by a sine and a cosine at the drive frequency and low-pass filters the result. That leaves two slow numbers, X and Y, which give the amplitude and phase of the fork's response. Its time constant sets how much noise is averaged away against how quickly it responds.

### Tracker and temperature
Each tracker uses the lock-in output to find the resonance. The resonance width is then converted to temperature through the helium model used to build the fork, so any error in the final temperature comes from the readout itself.
