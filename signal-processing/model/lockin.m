function [lock, zL] = lockin(v, ph, tau, zL, p)
% LOCKIN  Digital I/Q lock-in, one channel per drive tone.
%
%   v    ADC samples for this block, N x 1
%   ph   reference phase of each tone at every sample, N x ntones (from make_drive)
%   tau  low-pass time constant (s). Long = less noise, short = faster response.
%   zL   filter state carried between blocks ([] to start fresh)
%
%   lock.X, lock.Y    block-average output, 1 x ntones
%   lock.Xs, lock.Ys  output at every sample, N x ntones (PDH needs these)
%
% How it works: if v = A*cos(ph + phi), then
%       v*2*cos(ph)  = A*cos(phi) + (a term at twice the frequency)
%      -v*2*sin(ph)  = A*sin(phi) + (a term at twice the frequency)
% A low-pass filter removes the 2f terms, leaving X = A*cos(phi), Y = A*sin(phi).
% So amplitude A = hypot(X, Y) and phase phi = atan2(Y, X).
%
% The low-pass is a first-order IIR, the digital version of an RC filter:
%       y[n] = y[n-1] + alpha*(x[n] - y[n-1]),   alpha = 1 - exp(-dt/tau)

    ntones = size(ph, 2);
    if isempty(zL) || size(zL.X, 2) ~= ntones     % first block, or tone count changed
        zL.X = zeros(1, ntones);
        zL.Y = zeros(1, ntones);
    end

    I =  v.*2.*cos(ph);                % mix with the reference (N x ntones)
    Q = -v.*2.*sin(ph);

    alpha = 1 - exp(-p.dt/tau);
    [Xs, zL.X] = filter(alpha, [1, alpha-1], I, zL.X);
    [Ys, zL.Y] = filter(alpha, [1, alpha-1], Q, zL.Y);

    lock.Xs = Xs;   lock.Ys = Ys;
    lock.X  = mean(Xs, 1);
    lock.Y  = mean(Ys, 1);
end
