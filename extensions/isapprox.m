function tf=isapprox(A,B,rtol,atol)
% tf=isapprox(A,B,rtol,atol)
%
% Performs an inexact equality comparison according to
%   norm(A-B) <= atol + rtol*max(norm(A),norm(B))
% where both scalar and equal-length array inputs are accepted. If the norm
% is not finite, then the comparison falls back to doing element-by-element
% approximate comparisons.
%
% INPUTS
%
%   A       Scalar or vector.
%
%   B       Scalar or vector of equal length to A.
%
%   rtol    Relative tolerance. Defaults to sqrt(eps()) of the appropriate
%           type ('single' or 'double', depending on types of A and B).
%
%   atol    Absolute tolerance. Defaults to 0.
%
% OUTPUTS
%
%   tf      True if A approx-eq B, otherwise false.
%
% NOTES
%
%   Based off the Julia implementation. See julialang.org for more info.
%

  % Possibly convert integer arguments to a floating point, and then get the
  % biggest float type used in the two arguments.
  A = floatify(A);
  B = floatify(B);
  T = promote_float_type(A,B);

  % Default relative tolerance depends on the class of the floating point
  % values.
  if ~exist('rtol','var') || isempty(rtol)
    rtol = sqrt(eps(T));
  end
  % Default absolute tolerance is 0.
  if ~exist('atol','var') || isempty(atol)
    atol = 0;
  end

  % Handle the scalar case separately since the recursive call for the array
  % fallback case is infinite if we don't.
  if numel(A)==1 && numel(B)==1
    if A == B
      tf = true;
    else
      tf = abs(A-B) <= atol + rtol*max([abs(A),abs(B)]);
    end

  % Array case
  else
    X = norm(A - B);
    % If the norm worked, then do a relative comparison
    if isfinite(X)
      tf = X <= atol + rtol*max([norm(A),norm(B)]);
    % Otherwise, fall back to using component-wise approximate comparisons
    else
      tf = all(arrayfun(@(x,y) isapprox(x,y,rtol,atol), A, B));
    end
  end
end

function X=floatify(X)
  switch class(X)
    case {'single','double'}
      return
    case {'int8','uint8','int16','uint16','int32','uint32','int64','uint64'}
      X = double(X);
    otherwise
      error('Encountered a non-numeric type')
  end
end

function T=promote_float_type(A,B)
  % Only options after floatifying are 'single' and 'double', so with two
  % unique entries, they must be mismatched types and we promote to double.
  % Otherwise, they're the same (either both single or both double), so use
  % whatever type matches.
  if ~strcmp(class(A), class(B))
    T = 'double';
  else
    T = class(A);
  end
end

