% COMPARE_METHODS  Run all four trackers on the same fork, noise and
% temperature profile, then print a table and overlay the errors.

clear; close all;

p = params();
methods = {'vna', 'pll', 'dfrt', 'pdh'};

for i = 1:numel(methods)
    logs{i} = simulate(methods{i}, p);
    res(i)  = evaluate(logs{i}, p);
end

% ---- Summary table ----
fprintf('\n%-6s %10s %12s', 'method', 'first (s)', 'update (s)');
for L = res(1).levels, fprintf('   %4.1f mK RMS', L.T_mK); end
fprintf('\n');
for i = 1:numel(res)
    fprintf('%-6s %10.2f %12.3f', upper(res(i).method), res(i).t_first, res(i).update_interval);
    for L = res(i).levels, fprintf('   %8.3f mK', L.rms_mK); end
    fprintf('\n');
end

% ---- Overlay of temperature error ----
figure('Name', 'All methods');
hold on;
for i = 1:numel(logs)
    plot(logs{i}.t, (logs{i}.T_est - logs{i}.T_true)*1e3);
end
plot(p.t_blk([1 end]), [1 1], 'k--', p.t_blk([1 end]), [-1 -1], 'k--');
hold off; grid on; ylim([-3 3]);
xlabel('time (s)'); ylabel('T_{est} - T_{true} (mK)');
legend(upper(methods), 'Location', 'best');
