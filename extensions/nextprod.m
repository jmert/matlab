function y=nextprod(k,x)
% y=nextprod(k,x)
%
% Computes the next integer y greater than or equal to x which has prime
% factorization containing only elements of k, i.e.
%
%   x = \prod_{i=0}^N k_i ^ p_i
%
% for some values of p_i.
%
% This is a Matlab translation of Julia's nextprod function.
%

  n = length(k);
  cp = ones(1, n);    % current value of each counter
  mp = nextpow(k, x); % maximum value for each counter
  cp(1) = mp(1);      % start at first case that is >= x
  p = mp(1);          % initial value of product in this case
  best = p;
  icarry = 1;

  while cp(end) < mp(end)
    if p >= x
      % keep the best found yet
      if p < best
        best = p;
      end
      carrytest = true;
      while carrytest
        p = floor(p / cp(icarry));
        cp(icarry) = 1;
        icarry = icarry + 1;
        p = p * k(icarry);
        cp(icarry) = cp(icarry) * k(icarry);
        carrytest = cp(icarry) > mp(icarry) & icarry < n;
      end
      if p < x
        icarry = 1;
      end
    else
      while p < x
        p = p * k(1);
        cp(1) = cp(1) * k(1);
      end
    end
  end
  y = best;
end

function y=nextpow(k,x)
  y = k .^ ceil(log(x) ./ log(k));
end
