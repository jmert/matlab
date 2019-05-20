function dly = fftgroupdelay(H, samprate, N)
% dly = fftgroupdelay(H, samprate, N)
%
% Return the group delay of the transfer function H.
%
% INPUTS
%   H           Complex transfer function.
%   samprate    Sample rate of the corresponding time-domain impulse response.
%   N           Defaults to length(N). Full length of the transfer function.
%               If H has been truncated to the even/odd Nyquest frequency,
%               then N should be 2*length(H) + [0,1] where +1 corresponds to
%               an odd length.
%
% OUTPUTS
%   dly         Group delay in the transfer function.
%
% EXAMPLE
%
%   T = firpm(32, [0, 0.25, 0.5, 1], [1, 1, 0, 0]);
%   T = padarray(T, [0, 100-33], 0, 'post');
%   H = fft(T);
%   fsamp = 20;
%   f = fftfreq(100, fsamp);
%   j = fftgroupdelay(H, fsamp);
%   plot(f(1:end/2), j(1:end/2))

if ~exist('N','var') || isempty(N)
  N = length(H);
end
ph = unwrap(angle(H(:)'));
dfq = 2*pi*samprate * 1 / N;
dly = -diff(ph) ./ dfq;
% assuming the DC phase delta is the same as the next
dly = [dly(1) dly];

end
