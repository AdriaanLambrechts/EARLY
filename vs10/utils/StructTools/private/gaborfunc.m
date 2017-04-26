function y = gaborfunc(c, t)
%GABORFUNC  gabor function
%   Y = GABORFUNC(C, X) calculates the function value for X with constants C. C must be a vector with
%   eight elements.

%B. Van de Sande 25-03-2003

%General GABOR-function:
A  = c(1); %Amplitude ...
DC = 0;    %DC-value ...

EnvMax   = c(2); %Position of enveloppe-maximum ...
EnvWidth = c(3); %Width of enveloppe ...
EnvShape = 2;    %Shape of enveloppe (small values give accentuation of the central peak, large values give a box-like shape)...

Freq = c(4); %Frequency ...
Ph   = c(5); %Phase-shift ...

y = A * exp(-((abs(t-EnvMax)/EnvWidth).^EnvShape)) .* cos(2*pi*Freq*t + Ph) + DC;
