function val=ifelse(condition, trueval, falseval)
% val=ifelse(condition, trueval, falseval)
%
% Function wrapper around the statement
%
%   if condition; val=trueval; else; val=falseval; end;
%
% for convenience in allowing conditionals in anonymous functions and/or
% emulating the ternary operator.
%

  if condition
    val = trueval;
  else
    val = falseval;
  end
end
