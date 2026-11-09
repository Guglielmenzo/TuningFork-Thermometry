function [f0, width, A_peak, phi_ref, ok] = lorentz_fit(f, Z)
% LORENTZ_FIT  Find the resonance frequency and width from a frequency sweep.
%
%   f   sweep frequencies (Hz)
%   Z   lock-in output at each frequency as a complex number, X + 1j*Y
%
% Near resonance a series RLC fork's response is a complex Lorentzian:
%       Z(f) = K*exp(1j*theta) / (1 + 1j*2*(f - f0)/width)
% K and theta are whatever gain and phase the TIA, PGA and lock-in add.
% Flip it over and it becomes a straight line in f:
%       1/Z = a + b*f        (a and b are complex numbers)
% Working through the algebra:
%       a/b = -f0 - 1j*width/2
% so a straight-line fit gives everything:
%       f0     = -real(a/b)
%       width  = -2*imag(a/b)
%       Z(f0)  = 1/(a + b*f0)    -> peak amplitude and phase at resonance
%
% Why complex and not just the amplitude: noise always makes hypot(X, Y)
% bigger than the true amplitude, and the effect is worst in the tails where
% the signal is small. That makes the peak look wider than it is. X and Y
% themselves have zero-mean noise, so fitting them keeps the answer honest.
%
% Weighting: the noise on 1/Z grows as 1/|Z|^2, so the tails are noisy.
% Weighting each point by |Z|^2 evens that out (weighted least squares:
% multiply each equation by its weight before solving). The measured |Z| is
% itself noisy, so the fit is done twice: the second pass weights by the
% smooth |Z| from the first fit instead.

    fc = mean(f);                      % fit around the sweep center, because
    d  = f(:) - fc;                    % numbers near 32768 lose precision
    y  = 1./Z(:);
    M  = [ones(size(d)), d];

    w  = abs(Z(:)).^2;                 % pass 1: weights from the data
    ab = (M.*w) \ (y.*w);              % complex weighted least squares
    w  = 1./abs(M*ab).^2;              % pass 2: weights from the fitted curve
    ab = (M.*w) \ (y.*w);
    a  = ab(1);  b = ab(2);

    r       = a/b;
    f0      = fc - real(r);
    width   = -2*imag(r);
    Zpk     = 1/(a + b*(f0 - fc));
    A_peak  = abs(Zpk);
    phi_ref = angle(Zpk);

    ok = isfinite(width) && width > 0;
    if ~ok
        f0 = NaN; width = NaN; A_peak = NaN; phi_ref = NaN;
    end
end
