classdef asyncmatfile < handle
  properties (Access = private)
    hasworker
    hmatfile
    future
  end

  methods
    function self = asyncmatfile(path,varargin)
      self.hasworker = exist('gcp') && ~isempty(gcp('nocreate'));
      self.hmatfile = matfile(path, varargin{:});
      self.future = [];
    end

    function v = get(self, f)
      v = builtin('subsref', self, substruct('.', f));
    end

    function set(self, f, v)
      self = builtin('subsasgn', self, substruct('.', f), v);
    end

    function O = subsref(self,S)
      %% Special cases first
      %if S.type == '.' && length(S) == 1
      %  switch S.subs
      %    case {'hmatfile', 'future'}
      %      O = get(self, S.subs);
      %      return
      %    otherwise
      %      % Fall through to letting hmatfile handle anything else
      %  end
      %end

      hmatfile = get(self, 'hmatfile');
      if ~get(self, 'hasworker')
        O = subsref(hmatfile, S);
      else
        future = get(self, 'future');
        if ~isempty(future)
          error('Read or write unmatched by a wait.')
        end
        future = parfeval(@subsref, 1, hmatfile, S);
        set(self, 'future', future);
        O = future;
      end
    end

    function self = subsasgn(self, S, val)
      hmatfile = get(self, 'hmatfile');
      hasworker = get(self, 'hasworker');
      if ~hasworker
        subsasgn(hmatfile, S, val);
      else
        future = get(self, 'future');
        if ~isempty(future)
          error('Read or write unmatched by a wait.')
        end
        future = parfeval(@subsasgn, 1, hmatfile, S, val);
        set(self, 'future', future);
      end
    end

    function disp(self)
      if get(self, 'hasworker')
        async = 'asynchronous mode';
      else
        async = 'serial mode';
      end
      if ~isempty(get(self, 'future'))
        async = [async ' (has pending work)'];
      end
      fprintf('  asyncmatfile, %s\n  Wrapped', async)
      disp(get(self, 'hmatfile'))
    end

    function O = wait(self)
      if ~get(self, 'hasworker')
        warning('called wait in serial mode')
        O = [];
        return
      end
      future = get(self, 'future');
      if isempty(future)
        error('Wait called with no pending read or write operation.')
      end
      if ~wait(future)
        error('Error occurred while waiting for asynchronous IO.')
      end
      if isequal(future.Function, @subsref)
        O = fetchOutputs(future);
      elseif isequal(future.Function, @subsasgn)
        O = self;
      else
        error('Unknown future function %s', func2str(@future.Function))
      end
      delete(future)
      set(self, 'future', []);
    end
  end
end
