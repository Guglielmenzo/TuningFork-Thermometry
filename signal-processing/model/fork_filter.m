function [bF, aF] = fork_filter(Rm, Lm, p)
% FORK_FILTER  Digital filter for the fork's motional branch.
%
% Drive voltage in, fork current out. For Rm, Lm, Cm in series the admittance is
%       I/V = 1/(Rm + s*Lm + 1/(s*Cm)) = s*Cm/(s^2*Lm*Cm + s*Rm*Cm + 1)
% Dividing top and bottom by Lm*Cm keeps the numbers a sensible size:
%       I/V = (s/Lm) / (s^2 + s*Rm/Lm + 1/(Lm*Cm))
%
% c2d with 'zoh' (zero-order hold) maps it to discrete time. ZOH puts the
% resonance at exactly the right frequency. (Tustin without prewarping
% shifts it slightly, which matters for a 200 Hz wide peak at 32 kHz.)

    sysF = tf([1/Lm 0], [1, Rm/Lm, 1/(Lm*p.Cm)]);
    [bF, aF] = tfdata(c2d(sysF, p.dt, 'zoh'), 'v');
end
