function r = urandom_seed()
% r = urandom_seed()
%
% Obtain a seed value from the Linux /dev/urandom device.
%

  h = fopen('/dev/urandom');
  if h < 0
    error('Error opening /dev/urandom');
  end
  r = fread(h, 1, 'uint32');
  fclose(h);
end
