function log = simulate(method, p)
% SIMULATE  Run the whole readout over time with one tracking method.
%
%   log = simulate('vna', p)     method is 'vna', 'pll', 'dfrt' or 'pdh'
%
% Time is cut into blocks (p.T_block, 10 ms). In each block:
%   1. the fridge is at temperature T, which sets the fork's Rm and Lm
%   2. the drive plays the frequency the tracker asked for
%   3. fork -> TIA (+ noise, + C0 feedthrough) -> gain and ADC -> lock-in
%   4. the tracker reads the lock-in and picks the next drive frequency
%   5. true and estimated temperature are logged
% Every filter keeps its state between blocks, so the fork keeps ringing
% across block edges exactly like the real one.

    rng(p.seed);                                % repeatable noise
    tracker = str2func(['tracker_' method]);    % e.g. @tracker_vna
    p.G = pick_gain(p);
    fprintf('%s: PGA gain %g, %d blocks (%.0f s)\n', upper(method), p.G, p.Nblocks, p.T_run);

    % ---- Start-up ----
    [drive, state] = tracker([], [], p);        % tracker's first drive request
    zF = zeros(2, 1);                           % fork filter state (2nd order)
    fe = [];                                    % TIA state (set up in frontend)
    zL = [];                                    % lock-in state
    ph = 0;                                     % drive phase per tone
    T_prev = NaN;

    % ---- Log ----
    log.method  = method;
    log.t       = p.t_blk;
    log.T_true  = p.T_true;
    log.T_est   = NaN(1, p.Nblocks);
    log.f0_est  = NaN(1, p.Nblocks);
    log.w_est   = NaN(1, p.Nblocks);
    log.w_true  = NaN(1, p.Nblocks);
    log.f_drive = NaN(1, p.Nblocks);
    log.new     = false(1, p.Nblocks);

    for k = 1:p.Nblocks
        t0 = p.t_blk(k);

        % 1. Fork at this block's temperature (only rebuilt when T changes,
        %    since c2d is slow). Keeping the old filter state when the
        %    coefficients change is a small approximation, fine for slow changes.
        T = p.T_true(k);
        if T ~= T_prev
            [Rm, Lm, w_true] = fork_params(T, p);
            [bF, aF] = fork_filter(Rm, Lm, p);
            T_prev = T;
        end

        % 2. Drive. If the number of tones changed (e.g. DFRT going from a
        %    one-tone sweep to two tones), restart the phases.
        if numel(ph) ~= numel(drive.f), ph = zeros(1, numel(drive.f)); end
        [v_drive, ph_all, ph] = make_drive(drive.f, ph, t0, drive.pm, p);

        % 3. Signal chain
        [i_fork, zF]  = filter(bF, aF, v_drive, zF);
        [v_tia, fe]   = frontend(i_fork, v_drive, fe, p);
        v_adc         = adc(v_tia, p);
        [lock, zL]    = lockin(v_adc, ph_all, drive.tau_lockin, zL, p);
        lock.t0 = t0;

        % 4. Tracker
        log.f_drive(k) = drive.f(1);
        [drive, state] = tracker(state, lock, p);

        % 5. Log
        log.w_true(k) = w_true;
        log.f0_est(k) = state.f0;
        log.w_est(k)  = state.width;
        log.T_est(k)  = width_to_T(state.width, p);
        log.new(k)    = state.new_reading;

        if mod(k, round(p.Nblocks/10)) == 0
            fprintf('  %3.0f%%\n', 100*k/p.Nblocks);
        end
    end
end

function G = pick_gain(p)
% Pick the largest PGA gain that keeps the signal plus noise inside the ADC.
% Biggest signal: the warmest temperature in the run (smallest Rm), on
% resonance, two tones (DFRT) in the worst case:  2*Vd*Rf/Rm.
% Noise at the TIA output: white current noise through the TIA low-pass,
% whose noise bandwidth is 1/(4*Rf*Cf):  i_n*Rf*sqrt(1/(4*Rf*Cf)).
    Rm_min  = fork_params(max(p.T_true), p);
    sig     = 2*p.Vd*p.Rf/Rm_min;
    noise   = p.i_n*p.Rf*sqrt(1/(4*p.Rf*p.Cf));
    peak    = sig + 4*noise;                     % 4 sigma: clips very rarely
    ok      = p.G_list(p.G_list*peak < p.Vfs/2);
    if isempty(ok), G = p.G_list(1); else, G = max(ok); end
end
