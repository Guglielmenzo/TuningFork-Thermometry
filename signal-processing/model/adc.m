function v_out = adc(v_in, p)
% ADC  Gain stage, then clip and quantize like a real ADC.
%
% The gain stage multiplies by p.G. The ADC can only read -Vfs/2 to +Vfs/2,
% so anything outside is clipped, then the value is rounded to the nearest
% step:  LSB = Vfs/2^nbits.

    v = p.G*v_in;
    v = min(max(v, -p.Vfs/2), p.Vfs/2 - p.LSB);   % clip
    v_out = round(v/p.LSB)*p.LSB;                 % quantize
end
