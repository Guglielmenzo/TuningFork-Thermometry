function [v_tia, fe] = frontend(i_fork, v_drive, fe, p)
% FRONTEND  Everything between the fork and the TIA output.
%
%   i_fork   fork motional current for this block (A)
%   v_drive  drive voltage for this block (V), used for the C0 feedthrough
%   fe       state carried between blocks: fe.zT (TIA filter), fe.v_last
%
% Three things add up at the TIA input:
%   1. the fork's motional current
%   2. C0 feedthrough left after cancellation:  i = dC*dV/dt
%      (current through a capacitor is C*dV/dt)
%   3. the amplifier's input current noise, white, 0.6 pA/rtHz (LTspice)
% then the TIA turns current into voltage with -Rf/(1 + s*Rf*Cf).

    if isempty(fe)                     % first block: start everything at zero
        fe.zT = zeros(max(length(p.aT), length(p.bT)) - 1, 1);
        fe.v_last = 0;
    end

    % 2. Feedthrough. dV/dt by finite difference, using the last sample of the
    %    previous block so there is no glitch at the block edge.
    dv   = diff([fe.v_last; v_drive])/p.dt;
    i_ff = p.dC*dv;
    fe.v_last = v_drive(end);

    % 3. Noise. White noise with density i_n (A/rtHz), sampled at fs, has
    %    RMS = i_n*sqrt(fs/2)  (all the noise up to the Nyquist frequency).
    i_noise = p.i_n*sqrt(p.fs/2)*randn(size(i_fork));

    % TIA, carrying its filter state so it is continuous across blocks.
    [v_tia, fe.zT] = filter(p.bT, p.aT, i_fork + i_ff + i_noise, fe.zT);
end
