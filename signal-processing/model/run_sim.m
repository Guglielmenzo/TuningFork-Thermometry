% RUN_SIM  Run one tracking method and look at the result.
%
% Change the settings below and press Run. All the constants live in
% params.m; anything set here overrides params.m for this run only.

clear; close all;

p = params();

% ---- Choose the tracking method: 'vna', 'pll', 'dfrt' or 'pdh' ----
method = ['pdh'];

% ---- Things worth sweeping (uncomment to try) ----
% p.dC    = 0.5e-12;     % C0 cancellation mismatch (F)
% p.Vd    = 2e-3;        % drive amplitude (V)
% p.nbits = 12;  p.LSB = p.Vfs/2^p.nbits;   % fewer ADC bits

% ---- Temperature profile (one value per block) ----
% Default from params.m: 10 mK, stepping to 12 mK halfway through.
% A slow ramp instead:
% p.T_true = linspace(10e-3, 15e-3, p.Nblocks);

log = simulate(method, p);
res = evaluate(log, p);
