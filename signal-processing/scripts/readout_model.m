function p = params ()
% This function serves as the front end model for the tuning fork readout


% --- Fork Parameters, pulled from fork datasheet (VT200F-6PF20PPM)
% Fork parameters are from room temperature and in a vaccuum

p.f0_nom = 32768; % Nominal frequency
p.Cm     = 2.0e-15; % Motional capacitance C1
p.R1     = 50e3; % ESR (datasheet max)
p.C0     = 0.9e-12; % hunt capacitance
p.Lm0    = 1/((2*pi*p.f0_nom)^2*p.Cm); % H, motional inductance, ~11.8 kH


% --- Cable and other interferences 
% These are all estimated values and should be measured prior to production

p.C_cable = 350e-12; % Per ft cable capacitance
p.Cx = 1e-12; % Capacitave crosstalk between cables.
p.Cc = p.C0 + p.Cx; % Canceling capacitance
p.dC = 0; % Additional capacitance, used to model variaton in p.CC, sweep -/+ .5 pF


% --- Driving voltage
p.Vd = 1e-3


% --- Trans-Impedance Amplifier
p.Rf = 5e6; % Feedback resistor
p.Cf = 3.7e-12; % Bypass capacitor
p.Cin = p.C_cable + p.C0 + p.Cx + p.Cc; % Total capacitance seen at TIA input
p.Cf_min = sqrt(p.Cin/(2*pi*p.Rf*p.GBW)); % minimum feedbakc capacitance
p.Cf = 1.5*p.Cf_min; % feedback capacitor with 50% margin
p.i_n = 0.6e-12 % average input refered currnet noise (See Spice model)

% --- Gain stage
p.G = [10,100,1000] % Different gains to be explored

% --- Analog to Digital Converter
p.A_res = 16 % ADC resolution (bits)
p.Vs = 2 % ADC max voltage swing
p.LSB = p.Vs/(2^p.A_res) % Step size between bits in the ADC
p.fs = 500e3; % ADC sampling frequency (ballpark)

% --- Sampling times
p.T_block = 10e-3; % length of one loop block
p.N_block = round(p.T_block*p.fs); % samples per block
p.T_run = 120; % total simulated time
p.Nblocks = round(p.T_run/p.T_block); % total number of blocks in sim
p.tau_lockin = 2e-3; % lock-in low-pass time constant

% --- Temperature 
t_blk = (0:p.Nblocks-1)*p.T_block; % Start time of each block
p.T_true = 10e-3 + 0*t_blk; % Initial temperature assumption

end