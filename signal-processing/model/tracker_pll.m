function [drive, s] = tracker_pll(s, lock, p)
% TRACKER_PLL  Phase-locked loop: keeps the drive sitting on the resonance.
%
% 1. Acquire: run two VNA sweeps to find f0, the width, the phase at
%    resonance (phi_ref) and the peak amplitude.
% 2. Track: every block, compare the measured phase with phi_ref. Near
%    resonance the phase of a series RLC falls off as
%           phi - phi_ref = -atan(2*(f - f0)/width)  ~  -2*(f - f0)/width
%    so the frequency error is roughly  f0 - f = (phi - phi_ref)*width/2.
%    Move the drive part of the way there each block (gain Kp).
%
% Width: on resonance the fork current is Vd/Rm, so the amplitude A is
% proportional to 1/Rm, and width = Rm/(2*pi*Lm) is proportional to 1/A.
% The VNA sweeps give (width, A_peak) pairs to calibrate against:
%           width = (width_cal*A_cal)/A
% One sweep is noisy, and any error in the calibration stays in every reading
% after it, so the product width*A_peak is averaged over n_cal sweeps.
% This cancels every gain in the chain (TIA, PGA, ADC), so we never need Lm.

    % ---------------- Settings ----------------
    Kp       = 0.5;     % fraction of the frequency error corrected each block.
                        % The fork settles in about 1.5 ms at 10 mK, much faster
                        % than one 10 ms block, so 0.5 is stable.
    tau_lock = 2e-3;    % s, lock-in time constant
    n_avg    = 10;      % blocks of smoothing on the width (100 ms)
    n_cal    = 4;       % sweeps averaged for the calibration (after the first,
                        % which uses a rough guess and isn't centered)

    if isempty(s)
        s.mode = 'acquire';
        [drive, s.vna] = tracker_vna([], [], p);
        s.f0 = NaN;  s.width = NaN;  s.new_reading = false;
        s.cal_wA = 0;  s.cal_phi = 0;
        return
    end

    s.new_reading = false;

    switch s.mode
        case 'acquire'
            [drive, s.vna] = tracker_vna(s.vna, lock, p);
            if s.vna.new_reading           % report the sweep results meanwhile
                s.f0 = s.vna.f0;  s.width = s.vna.width;  s.new_reading = true;
                if s.vna.sweeps_done >= 2  % sweeps 2 onward are well centered
                    s.cal_wA  = s.cal_wA  + s.vna.width*s.vna.A_peak;
                    s.cal_phi = s.cal_phi + exp(1j*s.vna.phi_ref);  % average as unit vectors
                end
            end
            if s.vna.sweeps_done >= 1 + n_cal
                s.f       = s.vna.f0;
                s.phi_ref = angle(s.cal_phi);
                s.wA_cal  = s.cal_wA/n_cal;
                s.wait    = 2;             % let the fork and lock-in settle first
                s.mode    = 'track';
            else
                return
            end

        case 'track'
            if s.wait > 0
                s.wait = s.wait - 1;
            else
                A   = hypot(lock.X(1), lock.Y(1));
                phi = atan2(lock.Y(1), lock.X(1));
                e   = angle(exp(1j*(phi - s.phi_ref)));  % phase error wrapped to +/-pi
                df  = e*s.width/2;                       % estimate of f0 - f
                s.f = s.f + Kp*df;

                w_new   = s.wA_cal/A;
                s.width = s.width + (w_new - s.width)/n_avg;   % running average
                s.f0    = s.f;
                s.new_reading = true;
            end
    end

    drive.f = s.f;
    drive.pm = [];
    drive.tau_lockin = tau_lock;
end
