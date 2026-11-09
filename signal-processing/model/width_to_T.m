function T = width_to_T(width, p)
% WIDTH_TO_T  Turn a measured resonance width (Hz) back into temperature (K).
%
% This is the helium law from params.m solved for T:
%       width = He_A/T + He_B    ->    T = He_A/(width - He_B)
% It uses the same law that built the fork in fork_params, so any error in the
% final temperature comes from the readout, not from the calibration.

    T = p.He_A./(width - p.He_B);
    T(~isfinite(width) | width <= p.He_B) = NaN;   % no valid width yet
end
