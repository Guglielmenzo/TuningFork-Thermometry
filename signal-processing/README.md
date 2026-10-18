# Signal Processing

MATLAB model of the readout chain: fork, TIA, gain, ADC, lock-in, then a tracker (VNA, PLL, DFRT or PDH) that estimates f0 and width.

## Files
- [`scripts/readout_model.m`](scripts/readout_model.m): constants, fork model, TIA and noise, ADC, lock-in

## Equations

**Fork (motional branch)**

$$L_m = \frac{1}{(2\pi f_0)^2 C_m}, \qquad \frac{I}{V} = \frac{sC_m}{s^2L_mC_m + sR_mC_m + 1}$$

$$\Delta f = \frac{R_m}{2\pi L_m}, \qquad \tau = \frac{2L_m}{R_m}$$

**TIA**

$$\frac{V_{out}}{I_{in}} = -\frac{R_f}{1 + sR_fC_f}, \qquad C_f \ge \sqrt{\frac{C_{in}}{2\pi R_f \, GBW}}$$

**Discretization** (`c2d`, zero-order hold, step $\Delta t = 1/f_s$)

$$y[n] = a\,y[n-1] - R_f(1-a)\,x[n-1], \qquad a = e^{-\Delta t/(R_fC_f)}$$

**ADC**

$$\text{LSB} = \frac{V_{FS}}{2^{N}}$$
