function listing=ls2(varargin)

	% If there are no arguments, then use only -1 as a parameter	
	if nargin == 0
		params = {'-1'};
	% Otherwise include the parameters in the call to ls
	else
		params = {'-1' varargin{:}};
	end

	% Capture the output of ls
	output = ls(params{:});
	% Split along the newlines
	listing = regexp(output, '\n', 'split');
	% And then remove the extra empty string at the end
	listing = listing(1:end-1)';

end

