function e=extrema(A)
  if exist('bounds')
    [e(1),e(2)] = bounds(A(:));
  else
    e(1) = min(A(:));
    e(2) = max(A(:));
  end
end
