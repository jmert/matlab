function S = tryrmfield(S, fields)
% S = tryrmfield(S, fields)
%
% Removes the fields contained in fields from S, only if they exist. Does
% not throw an error when the field is not present, unlike the standard
% call to rmfield().
%
  x = intersect(fieldnames(S), flatten(fields));
  if ~isempty(x)
    S = rmfield(S, x);
  end
end
