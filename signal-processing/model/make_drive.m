function [v, ph, ph_end] = make_drive(f, ph0, t0, pm, p)
% MAKE_DRIVE  Drive voltage for one block: one or more tones, phase-continuous.
%
%   f    row of tone frequencies in Hz (1 tone for VNA/PLL/PDH, 2 for DFRT)
%   ph0  phase of each tone at the start of the block (rad), carried over
%   t0   absolute time at the start of the block (s), for phase modulation
%   pm   phase modulation (PDH only): pm.beta (rad) and pm.fm (Hz). Use [] for none.
%
%   v      drive voltage, N_block x 1
%   ph     phase of every tone at every sample, N_block x ntones. The lock-in
%          uses this as its reference, so it measures the fork's response
%          relative to exactly what was sent.
%   ph_end phase of each tone at the start of the next block
%
% Each tone is  Vd*cos(phase). Keeping the phase continuous across blocks means
% a frequency change does not cause a jump, just like a real DDS/NCO.

    n  = (0:p.N_block-1).';            % sample index within the block
    ph = ph0 + 2*pi*(n*p.dt)*f;        % N x ntones (implicit expansion)
    ph_end = ph0 + 2*pi*p.N_block*p.dt*f;
    ph_end = mod(ph_end, 2*pi);        % keep the numbers small

    if ~isempty(pm)
        % Phase modulation: phase += beta*sin(2*pi*fm*t). Uses absolute time,
        % so it is automatically continuous across blocks.
        t  = t0 + n*p.dt;
        ph = ph + pm.beta*sin(2*pi*pm.fm*t);
    end

    v = p.Vd*sum(cos(ph), 2);          % add the tones together
end
