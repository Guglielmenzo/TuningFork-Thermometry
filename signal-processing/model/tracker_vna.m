function [drive, s] = tracker_vna(s, lock, p, f0_guess, w_guess)
% TRACKER_VNA  Swept-frequency (VNA style) tracker.
%
% Steps the drive through a list of frequencies around the resonance. At each
% point it waits for the fork and lock-in to settle, averages the lock-in
% output for a few blocks, then moves on. After the last point it fits a
% complex Lorentzian (lorentz_fit.m) to get f0 and the width, re-centers the list on
% the new estimate, and starts the next sweep.
%
% Called once per block by simulate.m:
%   [drive, s] = tracker_vna([], [], p)       first call, sets up the state
%   [drive, s] = tracker_vna(s, lock, p)      every block after that
% The other trackers also call it with f0_guess and w_guess to run a sweep
% centered where they think the resonance is.
%
%   lock   lock-in output from the block that just ran (see lockin.m)
%   drive  what to send next block: drive.f (Hz), drive.pm, drive.tau_lockin
%   s      state kept between blocks. s.f0 and s.width are the current
%          estimates (NaN until the first sweep finishes).

    % ---------------- Settings ----------------
    N_points  = 25;      % points per sweep
    span      = 3;       % sweep covers f0 +/- span*width
    n_measure = 2;       % blocks averaged at each point
    tau_lock  = 2e-3;    % s, lock-in time constant. Long is fine here because we
                         % are waiting for the fork to settle anyway.

    if isempty(s)
        % ---------------- First call: set up ----------------
        if nargin < 4, f0_guess = p.f0_nom; end   % start at the datasheet frequency
        if nargin < 5, w_guess  = 500;      end   % Hz, deliberately wide first guess
        s.f0 = NaN;  s.width = NaN;  s.A_peak = NaN;  s.phi_ref = NaN;
        s.sweeps_done = 0;
        s.new_reading = false;
        s.n_measure = n_measure;
        s.tau_lock  = tau_lock;
        s = start_sweep(s, f0_guess, w_guess, N_points, span, p);
    else
        % ---------------- Every block: record and step ----------------
        s.new_reading = false;
        s.count = s.count + 1;                  % blocks spent at this point

        if s.count > s.n_settle                 % settled, so the reading counts
            s.Xsum = s.Xsum + lock.X(1);
            s.Ysum = s.Ysum + lock.Y(1);
        end

        if s.count == s.n_settle + s.n_measure  % done at this point
            s.X_list(s.k) = s.Xsum/s.n_measure;
            s.Y_list(s.k) = s.Ysum/s.n_measure;
            s.k = s.k + 1;  s.count = 0;  s.Xsum = 0;  s.Ysum = 0;
        end

        if s.k > numel(s.f_list)                % sweep finished: fit it
            Z = s.X_list + 1j*s.Y_list;          % complex response at each point
            [f0, width, A_peak, phi_ref, ok] = lorentz_fit(s.f_list, Z);
            if ok && width < 4*s.w_sweep        % sanity check on the fit
                s.f0 = f0;  s.width = width;  s.A_peak = A_peak;
                % phi_ref is the phase at resonance. The TIA, gain stage and
                % lock-in add their own phase, so it isn't 0 (the TIA alone
                % gives 180 deg). The PLL locks to this value.
                s.phi_ref = phi_ref;
                s.sweeps_done = s.sweeps_done + 1;
                s.new_reading = true;
                s = start_sweep(s, f0, width, N_points, span, p);
            else
                % Bad fit (peak not in the sweep, or too noisy): try wider.
                s = start_sweep(s, s.f_list(ceil(end/2)), 2*s.w_sweep, N_points, span, p);
            end
        end
    end

    drive.f = s.f_list(s.k);
    drive.pm = [];
    drive.tau_lockin = s.tau_lock;
end

function s = start_sweep(s, f0, w, N_points, span, p)
% Build a new list of frequencies around f0 and reset the counters.
    s.w_sweep = w;
    s.f_list  = f0 + linspace(-span, span, N_points)*w;
    s.X_list  = zeros(1, N_points);
    s.Y_list  = zeros(1, N_points);
    s.k = 1;  s.count = 0;  s.Xsum = 0;  s.Ysum = 0;
    % Wait about 5 time constants after each frequency step before trusting
    % the reading (5 tau = 99.3% settled). The fork rings with
    % tau = 2*Lm/Rm = 1/(pi*width), and the lock-in filter adds its own tau.
    tau_fork   = 1/(pi*w);
    s.n_settle = ceil(5*(tau_fork + s.tau_lock)/p.T_block);
end
