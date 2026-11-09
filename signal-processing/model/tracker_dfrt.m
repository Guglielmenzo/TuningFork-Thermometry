function [drive, s] = tracker_dfrt(s, lock, p)
% TRACKER_DFRT  Dual-frequency resonance tracking: two tones, two loops.
%
% Drives two tones at once, fc - D/2 and fc + D/2, and the lock-in measures
% each one separately.
%
% Center loop: the two tones have equal amplitude only when they sit
% symmetrically around the peak. Error e1 = (A2 - A1)/(A1 + A2). Working
% through the Lorentzian, e1 ~ -(fc - f0)/width, so  fc = fc + k1*e1*D.
%
% Spacing loop: the phase of a series RLC is  -atan(2*(f - f0)/width), so at
% f0 -/+ width/2 the two tones are at +45 and -45 deg: 90 deg apart. Error
% e2 = (phi1 - phi2) - pi/2 ~ (D - width)/width, so  D = D - k2*e2*D.
% When both loops settle, fc = f0 and D = width.

    % ---------------- Settings ----------------
    k1 = 0.3;  k2 = 0.3;  % loop gains (1 would correct the full error each block)
    tau_lock = 10e-3;     % s. Each lock-in channel sees the other tone as a
                          % beat at D (~200 Hz). It needs tau >> 1/(2*pi*D) to
                          % reject it.
    n_avg = 10;           % blocks of smoothing on the reported width

    if isempty(s)
        s.mode = 'acquire';
        [drive, s.vna] = tracker_vna([], [], p);
        s.f0 = NaN;  s.width = NaN;  s.new_reading = false;
        return
    end

    s.new_reading = false;

    switch s.mode
        case 'acquire'
            [drive, s.vna] = tracker_vna(s.vna, lock, p);
            if s.vna.new_reading
                s.f0 = s.vna.f0;  s.width = s.vna.width;  s.new_reading = true;
            end
            if s.vna.sweeps_done >= 2
                s.fc = s.vna.f0;
                s.D  = s.vna.width;
                s.wait = ceil(5*tau_lock/p.T_block);   % lock-in settles to the new tau
                s.mode = 'track';
            else
                return
            end

        case 'track'
            if s.wait > 0
                s.wait = s.wait - 1;
            else
                A   = hypot(lock.X, lock.Y);           % [A1 A2]
                phi = atan2(lock.Y, lock.X);           % [phi1 phi2]

                e1 = (A(2) - A(1))/(A(1) + A(2));
                e2 = angle(exp(1j*(phi(1) - phi(2)))) - pi/2;
                s.fc = s.fc + k1*e1*s.D;
                s.D  = s.D  - k2*e2*s.D;

                s.f0    = s.fc;
                s.width = s.width + (s.D - s.width)/n_avg;   % running average
                s.new_reading = true;
            end
    end

    drive.f = [s.fc - s.D/2, s.fc + s.D/2];
    drive.pm = [];
    drive.tau_lockin = tau_lock;
end
