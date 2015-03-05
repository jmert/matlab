function idx=binsearch(haystack,needle,exact)
%function idx=binsearch(haystack,needle,exact)
%
%Use a binary search to find needle in haystack.
%
%INPUTS
%  haystack    The array to search. Assumed that haystack is sorted.
%
%  needle      The element to search for.
%
%  exact       Defaults to true. If needle is not found and exact is true, then
%              the empty set is returned to indicate it doesn't exist. If false
%              the position where needle could be inserted (shifting the
%              latter portion of the array one index higher) and maintain
%              haystack's sorted order.
%
%OUTPUTS
%  idx         Position of the element.
%

  if ~isa(needle,class(haystack))
    error('binsearch:TypeMismatch', 'haystack and needle must be same type.');
  end

  if ~exist('exact','var') || isempty(exact)
    exact = true;
  end

  lbound = 1;
  ubound = length(haystack)+1;

  fprintf('init: lb = %i, ub = %i\n', lbound, ubound);

  while lbound<=length(haystack) && ubound>lbound
    mid = fix((ubound+lbound)/2);
    fprintf('iter: lb = %i, mid = %i, ub = %i\n', lbound, mid, ubound);
    if needle == haystack(mid)
      idx = mid;
      return
    elseif needle < haystack(mid)
      ubound = mid;
    else
      lbound = mid + 1;
    end
  end

  if lbound<=length(haystack) && needle==haystack(lbound)
    idx = lbound;
  elseif exact
    idx = [];
  else
    idx = lbound;
  end

  fprintf('final: lb = %i, ub = %i\n', lbound, ubound);
end