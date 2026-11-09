function p = params()
% PARAMS  Every fixed constant in the readout model, in one struct.
%
%   p = params();   then use p.Rf, p.Cm, ... everywhere else.
%
% Nothing in here changes while a simulation runs. run_sim.m may overwrite a
% few fields (method, temperature profile, gain) before calling simulate().
%
% Where values come from is written next to each one. "ESTIMATE" means it is
% a guess that should be replaced by a measurement.

%% ---------------- Fork (quartz tuning fork, motional branch) ----------------
% Source: 32.768 kHz watch-crystal datasheet (VT200F-6PF20PPM), room
% temperature, in vacuum. The BVD model (Butterworth-Van Dyke) treats the fork
% as Rm-Lm-Cm in series (the "motional branch") with C0 in parallel.
p.f0_nom = 32768;                        % Hz, nominal resonance (datasheet)
p.Cm     = 2.0e-15;                      % F, motional capacitance C1 (datasheet)
p.C0     = 0.9e-12;                      % F, shunt capacitance C0 (datasheet)
% Lm follows from the series-resonance formula f0 = 1/(2*pi*sqrt(Lm*Cm)):
p.Lm0    = 1/((2*pi*p.f0_nom)^2*p.Cm);   % H, about 11.8 kH

% Helium mass loading: liquid 3He moving with the tines adds mass, which
% raises Lm and lowers f0 (Blaauwgeers et al. 2007, J. Low Temp. Phys. 146).
% Set to 0 for now. Example: 0.01 means Lm is 1% higher than in vacuum.
p.mass_load = 0.0;

%% ---------------- Helium damping law (width vs temperature) ----------------
% In normal liquid 3He the resonance width grows as the temperature drops,
% because viscosity goes as 1/T^2 (Fermi liquid) and the fork's damping goes
% roughly as sqrt(viscosity). zonk read a straight line off the 0 bar plot in
% Blaauwgeers et al. 2007:
%       width = He_A/T + He_B
% PLACEHOLDER: replace with a fit to real fork data when it exists.
p.He_A = 2.14;     % Hz*K  (gives 214 Hz at 10 mK)
p.He_B = 0;        % Hz    (about 25 Hz at 29 bar)

%% ---------------- Cryostat wiring and C0 cancellation ----------------
% ESTIMATES, to be measured on the real fridge wiring.
p.C_cable = 350e-12;            % F, cable capacitance from sense line to ground
p.Cx      = 1.0e-12;            % F, drive-to-sense crosstalk capacitance
p.Cc      = p.C0 + p.Cx;        % F, cancellation capacitor (driven by inverted drive)
% After cancellation only the mismatch dC is left. It leaks drive straight into
% the TIA as i = dC*dV/dt. Sweep this +/-0.5 pF to see how much it matters.
p.dC      = 0;                  % F

%% ---------------- Drive ----------------
p.Vd = 1e-3;                    % V, drive amplitude per tone (about 1 mV, from the
                                %    readout architecture; keeps the fork linear)

%% ---------------- Transimpedance amplifier (TIA) ----------------
% Values match the LTspice front-end model.
p.Rf  = 500e3;                  % Ohm, feedback resistor (chosen in LTspice)
p.GBW = 18e6;                   % Hz, op-amp gain-bandwidth (LTC6240 datasheet)
p.Cin = p.C_cable + p.C0 + p.Cx + p.Cc;     % F, total capacitance at the TIA input
% Minimum feedback capacitor for a stable TIA (standard result, e.g.
% Graeme, "Photodiode Amplifiers", 1996):  Cf >= sqrt(Cin/(2*pi*Rf*GBW))
p.Cf_min = sqrt(p.Cin/(2*pi*p.Rf*p.GBW));
p.Cf  = 1.5*p.Cf_min;           % F, 50% margin
p.i_n = 0.6e-12;                % A/rtHz, input-referred current noise (LTspice .noise)

%% ---------------- Gain stage (PGA) and ADC ----------------
p.G_list = [10 100 1000 10000]; % available PGA gains. run_sim picks one.
p.G      = 1000;                % default gain (overwritten by pick_gain in simulate)
p.nbits  = 16;                  % ADC resolution, bits (architecture: >=16 bit)
p.Vfs    = 2.0;                 % V, ADC full-scale range (+/-1 V)
p.LSB    = p.Vfs/2^p.nbits;     % V, one ADC step

%% ---------------- Sampling and timing ----------------
p.fs      = 500e3;              % Hz, sample rate (about 15 samples per 32.8 kHz cycle)
p.dt      = 1/p.fs;             % s
p.T_block = 10e-3;              % s, one loop block. The tracker acts once per block.
p.N_block = round(p.T_block*p.fs);   % samples per block (5000)
p.T_run   = 60;                 % s, total simulated time
p.Nblocks = round(p.T_run/p.T_block);

%% ---------------- Discrete TIA filter ----------------
% Continuous TIA:  Vout/Iin = -Rf/(1 + s*Rf*Cf)
% c2d with 'zoh' turns it into a digital filter we can run with filter().
sysT = tf(-p.Rf, [p.Rf*p.Cf 1]);
[p.bT, p.aT] = tfdata(c2d(sysT, p.dt, 'zoh'), 'v');

%% ---------------- Temperature profile ----------------
% The "true" fridge temperature for every block. run_sim.m can replace this.
% Default: 10 mK, then a step to 12 mK halfway through.
p.t_blk  = (0:p.Nblocks-1)*p.T_block;          % s, start time of each block
p.T_true = 10e-3*ones(1, p.Nblocks);
p.T_true(p.t_blk >= p.T_run/2) = 12e-3;

%% ---------------- Random seed ----------------
p.seed = 1;                     % same noise every run, so methods compare fairly
end
