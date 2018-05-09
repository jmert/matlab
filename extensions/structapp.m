function O=structapp(S1,S2,varargin)
% O=structapp(S1,S2,...)
%
% Appends a structure to a structure array. The fieldnames are chosen such
% that fieldnames(O) = union(fieldnames(S1), fieldnames(S2)).
%
% INPUTS
%     S1    A structure array.
%     S2    A structure array.
%
% OUTPUTS
%     O     Structure array with S2 appended to S1 and fieldnames expanded
%           to cover all fields.
%
% EXAMPLES
%     A.a = 'a';
%     B.b = 'b';
%     O = structapp(A,B);
%

  % Determine which fields are already common
  common = intersect(fieldnames(S1), fieldnames(S2));

  % Create an empty set of the missing elements for S1 by duplicating the
  % fields which are unique to S2.
  zeroS1 = zerodup(rmfield(S2(1),common));
  % Do the same for S2.
  zeroS2 = zerodup(rmfield(S1(1),common));

  O = S1;
  % Now start merging and building the output array. We start with a copy of
  % S1 and merge in the missing fields.
  if ~isempty(zeroS1)
    zS1fields = fieldnames(zeroS1);
    for ii=1:length(S1)
      for ff=1:length(zS1fields)
        O(ii).(zS1fields{ff}) = zeroS1.(zS1fields{ff});
      end
    end
  end

  % Then for S2, we have to run through both sets of fieldnames to merge
  % in the structure.
  S2fields  = fieldnames(S2);
  N = length(S1);
  for ii=1:length(S2)
    nn = N + ii;
    for ff=1:length(S2fields)
      O(nn).(S2fields{ff}) = S2(ii).(S2fields{ff});
    end
  end
  if ~isempty(zeroS2)
    zS2fields = fieldnames(zeroS2);
    for ii=1:length(S2)
      nn = N + ii;
      for ff=1:length(zS2fields)
        O(nn).(zS2fields{ff}) = zeroS2.(zS2fields{ff});
      end
    end
  end

  if length(varargin) > 0
    O = structapp(O, varargin{1}, varargin{2:end});
  end
end

