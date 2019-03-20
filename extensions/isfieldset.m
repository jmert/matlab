function tf = isfieldset(S, f)
% tf = isfieldset(S, f)
%
% Checks whether the structure `S` has a field named by `f`, and if it does,
% whether it is non-empty. If both statements are true, returns true,
% otherwise false.
%
% EXAMPLE
%
%   A.a = 2;
%   A.b = [];
%
%   if ~isfieldset(A, 'a')
%     A.a = 1;
%   end
%   if ~isfieldset(A, 'b')
%     A.b = true;
%   end
%   if ~isfieldset(A, 'c')
%     A.c = 'name';
%   end
%
%   % A.a will still be 2, A.b has been update to true, and A.c is newly
%   % created and defaulted to 'name'.
%   disp(A)
%

  if isfield(S, f) && ~isempty(S.(f))
    tf = true;
  else
    tf = false;
  end
end

