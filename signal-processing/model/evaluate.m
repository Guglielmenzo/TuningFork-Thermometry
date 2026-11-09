function res = evaluate(log, p)
% EVALUATE  Compare estimated and true temperature, print results, plot.
%
%   res = evaluate(log, p)
%
% Reports, for each temperature the run holds:
%   - mean and RMS error of T_est - T_true (mK). Target is +/-1 mK.
%   - settle time: how long after the temperature changed until the
%     estimate (averaged over 1 s) is within 1 mK and stays there
% and overall:
%   - time to the first valid reading
%   - average time between new readings (target: under 30 s)

    err_mK = (log.T_est - log.T_true)*1e3;
    t = log.t;
    n1 = round(1/p.T_block);           % blocks in 1 s

    res.method = log.method;
    i_first = find(~isnan(log.T_est), 1);
    res.t_first = t(i_first);
    t_new = t(log.new);
    res.update_interval = mean(diff(t_new));   % includes the start-up sweeps

    fprintf('\n=== %s ===\n', upper(log.method));
    fprintf('First valid reading: %.2f s\n', res.t_first);
    fprintf('Average update interval: %.3f s\n', res.update_interval);

    % Split the run into stretches of constant temperature
    edges = [1, find(diff(log.T_true) ~= 0) + 1, numel(t) + 1];
    res.levels = [];
    for j = 1:numel(edges) - 1
        idx = edges(j):edges(j+1) - 1;
        e   = err_mK(idx);
        % 1 s moving average of the error, restarted at each temperature change
        % (dividing by the number of points so far for the first second)
        ea  = filter(ones(1, n1), 1, e)./min(1:numel(e), n1);
        % Settle time: first point after which the averaged error stays under 1 mK
        bad = find(isnan(ea) | abs(ea) > 1, 1, 'last');
        if isempty(bad), i_set = 1; else, i_set = bad + 1; end
        if i_set > numel(idx)
            t_set = NaN;                  % never settled in this stretch
            e_ok  = e(~isnan(e));
        else
            t_set = t(idx(i_set)) - t(idx(1));
            e_ok  = e(i_set:end);         % only judge accuracy once settled
        end
        L.T_mK    = log.T_true(idx(1))*1e3;
        L.settle  = t_set;
        L.mean_mK = mean(e_ok);
        L.rms_mK  = sqrt(mean(e_ok.^2));
        res.levels = [res.levels, L];
        fprintf('T = %5.1f mK: settle %6.2f s, error mean %+6.3f mK, RMS %6.3f mK\n', ...
                L.T_mK, L.settle, L.mean_mK, L.rms_mK);
    end

    % ---- Plots ----
    figure('Name', upper(log.method));
    subplot(3,1,1);
    plot(t, log.T_true*1e3, 'k', t, log.T_est*1e3, 'b');
    ylabel('T (mK)'); legend('true', 'estimate', 'Location', 'best'); grid on;
    title([upper(log.method) ' tracker']);

    subplot(3,1,2);
    plot(t, err_mK, 'b', t([1 end]), [1 1], 'r--', t([1 end]), [-1 -1], 'r--');
    ylabel('error (mK)'); ylim([-3 3]); grid on;

    subplot(3,1,3);
    plot(t, log.f_drive - p.f0_nom, 'Color', [0.6 0.6 0.6]); hold on;
    plot(t, log.f0_est - p.f0_nom, 'b'); hold off;
    ylabel('f - 32768 (Hz)'); xlabel('time (s)'); legend('drive', 'f0 estimate', 'Location', 'best'); grid on;
end
