function [Rm, Lm, width] = fork_params(T, p)
% FORK_PARAMS  Motional Rm and Lm of the fork at temperature T (in kelvin).
%
% The fork is a series Rm-Lm-Cm circuit. Helium changes it in two ways:
%   - damping (viscosity) sets the resonance width, and so Rm
%   - added mass raises Lm (p.mass_load, 0 for now)
%
% Width of a series RLC resonance (full width at half power):
%       width = Rm/(2*pi*Lm)        so   Rm = 2*pi*Lm*width
% This is the same as Blaauwgeers et al. 2007, where width = dw/(2*pi) and
% the fork's equivalent R and L are set by its mass and damping.

    Lm    = p.Lm0*(1 + p.mass_load);   % H
    width = p.He_A./T + p.He_B;        % Hz, helium law from params.m
    Rm    = 2*pi*Lm.*width;            % Ohm
end
