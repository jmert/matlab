A list of my many gripes with Matlab.

# Syntax

- No requirement for parentheses when no arguments passed, making the call
ambiguous with taking the value from a variable:

```matlab
f = figure
```

- Space-separated calls treat everything following the function name
implicitly as string arguments:

```matlab
who ans
who('ans')
```

- Array indexing and function calling use the same syntax, so you can't know
what the operation does without further context on the data itself:

```matlab
x = array_or_function(avariable)
```

- There are various restrictions on chaining operations. For eample, you cannot
index the output from any function without first assigning it to a variable:

```matlab
% Instead of
%   firstfield = fieldnames(astruct){1};
firstfield = fieldnames(astruct);
firstfield = firstfield{1};
```

Neither can you access the n-th output from a function without assigning to
variable (which makes the gripes later about functions worse), which motivates
[`extensions/take.m`](extensions/take.m) to exist:

```matlab
[~,idx] = max(aux);
val = data(idx);
% or
val = data(take(2, @max, aux));
```

* Splatting arguments (see [Julia](https://docs.julialang.org/en/v1/base/base/#...)
or [Python](https://www.python.org/dev/peps/pep-0448/) variations) is
inconsistent in Matlab. You can splat cell arrays,

```matlab
tmp = {-1, 1};
fprintf('%0.2f\n', -Inf, tmp{:}, Inf);
```

or fields from a struct array,

```matlab
S = struct('a', {-1, 1});        % length(S) == 2
fprintf('%0.2f\n', -Inf, S.a, Inf);
```

but you cannot do the same with numerical arrays. Furthermore, the lack of
unique syntax on the structure splatting is an easy way to generate bugs if
you expect `S` to be a scalar but it ends up being an array:

```matlab
S = struct('color', {'r', 'b'});   % Assumed to be scalar structure...
plot([0 1], [0 1], S.color)        % Errors!
```

# Functions

- Anonymous functions are limited to being single expressions. This motivates
stupid wrapper functions like [`extensions/ifelse.m`](extensions/ifelse.m) to
allow building up non-trivial anonymous functions:

```matlab
autoclim = @(scale,data) caxis([ ...
    ifelse(strcmpi(scale, 'log') & any(data(:) < 0), ...
        min(abs(data(:))), ...
        min(data(:)) ...
    ), ...
    max(data(:))]);
```

non-trivial anonoymous functions are only used because...

- Proper functions cannot be created at the REPL. Instead, you **must** create
a file somewhere in the PATH to have anything that encapsulates more than a
single expression.

- Lack of keyword arguments leads to the "key-value" convention used in many
functions, but it conflates keys with strings. This makes common constructs
like

```matlab
plot(x, y, '.', 'linewidth', 1)
plot(x, y, 'linewidth', 1)
```

which considers the first call to have (3, 1) positional/keyword versus the
second call to have (2,1) positional/keyword parameters hard to replicate
in user code.

# Arrays

- Cell arrays and normal arrays use different syntax. This leads to generic
code needing to duplicate nearly identical constructs for each possibility:

```matlab
function val=myfunc(val)
    % Recursively operate on arrays
    if length(val) > 1
        if iscell(val)
            for ii = 1:length(val)
                val{ii} = myfunc(val{ii});
            end
        else
            for ii = 1:length(val)
                val(ii) = myfunc(val(ii));
            end
        end
        return
    end
    % ... Processing scalar argument
end
```

- There is no such thing as a true vector, only 1×N or N×1 matrices. You
then end up with the ambiguity of what shape (column or row) any given
function may give you.

# Loops

- In many places, Matlab treats N×1 and 1×N matrices as the same thing, but
loop indexing cares. Therefore if you are unsure of the shape of a vector,
you must make sure it's a row vector first:

```matlab
for el = vals(:).'
    % ... do something with each el ...
end
```

- Iteration of cell arrays for some reason keeps the item wrapped in a cell
array, so you must still index into the loop item:

```matlab
fields = fieldnames(astruct);
for ff = fields(:)'
    ff = ff{1};
    astruct.(ff) = [];
end
```

# Strings

- Character arrays are strings. Until they weren't and real strings were
added to the language, but not until R2016b. So now you have to deal with
both `'string-ish'` and `"string"`...

- Unicode strings cannot be entered at the REPL. Try to copy-paste the
comment. Instead, you must construct the Unicode character via its
codepoint:

```matlab
% lbl = '90°'
lbl = ['90' char(176)];
```
