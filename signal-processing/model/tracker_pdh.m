function [drive, s] = tracker_pdh(s, lock, p)
% TRACKER_PDH  Modulation lock (simplified Pound-Drever-Hall style).
%
% The drive is phase-modulated:  phase = 2*pi*fc*t + beta*sin(2*pi*fm*t).
% That wobbles the instantaneous frequency by +/- dev = beta*fm around fc.
% As the frequency wobbles, the fork's amplitude wobbles too:
%   - below the peak, amplitude rises with frequency  -> in phase with the wobble
%   - above the peak, amplitude falls with frequency  -> opposite phase
%   - on the peak, no wobble at fm at all
% Demodulating the lock-in amplitude at fm gives an error signal that
% crosses zero at f0 and tells which way to move.
%
% SIMPLIFICATION: fm (100 Hz) is about half the width here, so this is the
% slow-modulation limit of PDH (closer to a "dither" lock). Textbook PDH
% (Black, "An introduction to Pound-Drever-Hall laser frequency
% stabilization", Am. J. Phys. 69, 2001) uses fm larger than the width.
%
% The error signal only gives f0. The width comes from a VNA sweep that
% is repeated every width_period seconds.

    % ---------------- Settings ----------------
    fm           = 100;     % Hz, modulation frequency. Exactly 1 cycle per 10 ms
                            % block, so a block-long average rejects other terms.
    dev_frac     = 0.25;    % frequency wobble = dev_frac*width
    Kp           = 0.5;     % fraction of the estimated error corrected per block
    tau_lock     = 0.2e-3;  % s. Must pass the 100 Hz wobble: tau << 1/(2*pi*fm) = 1.6 ms
    width_period = 30;      % s, how often to stop and re-measure the width

    if isempty(s)
        s.mode = 'acquire';
        [drive, s.vna] = tracker_vna([], [], p);
        s.f0 = NaN;  s.width = NaN;  s.new_reading = false;
        return
    end

    s.new_reading = false;

    switch s.mode
        case {'acquire', 'sweep'}
            % 'acquire' is the start-up search, 'sweep' is the periodic width check
            [drive, s.vna] = tracker_vna(s.vna, lock, p);
            if s.vna.new_reading
                s.f0 = s.vna.f0;  s.width = s.vna.width;  s.new_reading = true;
            end
            done = (strcmp(s.mode, 'acquire') && s.vna.sweeps_done >= 2) || ...
                   (strcmp(s.mode, 'sweep')   && s.vna.sweeps_done >= 1);
            if done
                s.fc = s.vna.f0;
                s.t_last_sweep = lock.t0;
                s.wait = 2;
                s.mode = 'track';
            else
                return
            end

        case 'track'
            if s.wait > 0
                s.wait = s.wait - 1;
            else
                % Amplitude of the fork response at every sample of the last block
                A_t = hypot(lock.Xs(:,1), lock.Ys(:,1));
                t   = lock.t0 + (0:numel(A_t)-1).'*p.dt;

                % The amplitude can't follow the wobble instantly. The fork's
                % envelope acts like a low-pass with corner width/2 (its time
                % constant is 1/(pi*width)), and the lock-in filter is another
                % low-pass. Each delays and shrinks the wobble:
                %   lag  = atan(f/fc),   gain = 1/sqrt(1 + (f/fc)^2)
                fk   = s.width/2;
                fl   = 1/(2*pi*tau_lock);
                lag  = atan(fm/fk) + atan(fm/fl);
                gain = 1/sqrt(1 + (fm/fk)^2) / sqrt(1 + (fm/fl)^2);

                % Demodulate at fm, lined up with the frequency wobble (which
                % goes as cos(2*pi*fm*t), the derivative of the phase sin term)
                e = 2*mean(A_t.*cos(2*pi*fm*t - lag));

                % Near the peak A = A0/sqrt(1 + (2*d/width)^2), so dA/df = -4*A0*d/width^2
                % with d = f - f0. The wobble amplitude is dA/df*dev*gain, so
                %   d = -e*width^2/(4*A0*dev*gain)
                dev = dev_frac*s.width;
                A0  = mean(A_t);
                d   = -e*s.width^2/(4*A0*dev*gain);
                s.fc = s.fc - Kp*d;
                s.f0 = s.fc;              % f0 is new every block, but the width
                                          % (and so the temperature) only changes
                                          % after each sweep
            end

            % Time for a width check?
            if lock.t0 - s.t_last_sweep >= width_period
                s.mode = 'sweep';
                [drive, s.vna] = tracker_vna([], [], p, s.fc, s.width);
                return
            end
    end

    dev = dev_frac*s.width;
    drive.f  = s.fc;
    drive.pm = struct('beta', dev/fm, 'fm', fm);   % beta*fm = frequency wobble
    drive.tau_lockin = tau_lock;
end
