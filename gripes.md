A list of my many gripes with Matlab.

# Product
- There is no supported method to disable Toolboxes:
  1. Function namespace clashes are likely as new Toolboxes are developed, so your code may spontaneously break, with no way to override/disable. (Hello `euler` from the Symbolic Toolbox...)
  2. There's no way to test that your code hasn't gained another Toolbox as a dependency without copying to another computer with a smaller installation and testing there.

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

# REPL
The **R**ead, **E**xecute, **P**rint **L**oop

- Proper functions cannot be created at the REPL. Instead, you **must** create
a file somewhere in the PATH to have anything that encapsulates more than a
single expression.

- The command history is line based, not statement based — multiline statements
are broken up and must be retrieved from the history one at a time.

- The REPL doesn't understand bracketed pasting (e.g. [bracketed-paste][]).
If there's a syntax anywhere within a block of pasted code, execution does not
stop but instead continues despite what may be guaranteed to be a continuing
slew of further errors. (The "work-around" is to manually type `if true` before
pasting and ending the `if`-block.)

- Matlab doesn't know how to filter out it's own prompt, so you cannot simply
copy-paste previous commands back into the REPL; the `>>` prefix must be manually
removed from every line.

- In recent versions of Matlab, the debug REPL will nest itself in an unclear
number of debug levels if any error occurs (while `dbstop if true`). This is
*not* reflected in the stack trace, so quitting to a specific state may involve
a sequence of `dbquit` and `dbstack` calls to see when you've finally reached
the desired state. (This is especially problematic given the bracketed paste
issue...)

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

# Plotting
- Dash length on dashed lines cannot be explicitly controlled; instead it
is implicitly decided by your current monitor DPI.

- Plotting is an order of magnitude or two slower when X11 is connected
versus startup with the `-nodisplay` option (or by setting `DISPLAY=`
in the environment before launching).

- Plots are not reproducable for the same script across computers of
different display DPIs. When a bug report was submitted to Mathworks, they
claimed this was a feature, not a bug (in the WYSIWYG sense).

- You cannot save a PDF with text using anything other than the base
PostScript fonts.

- Plots with text interpreted by the TeX interpreter will often have
weird spacing once saved to PDF. No clue why, and no apparent way to fix
or work around it.

- Setting a figure active with `figure(fig_handle)` steals your desktop's
focus from whatever already had it.

- You cannot create a figure larger than your display, even if it is a
`Visible = 'off'` figure. But it is allowed in no-display mode.

- `imagesc` seems to implicitly downsample any image you provide it after
some unspecified dimension threshold, even if you've contrived to form
a figure which would be big enough to show the data pixel-by-pixel.

- Sizing a figure works inconsistently if it's also being created for
the first time. Once fully shown, it often has a size that's only an
approximation of what was requested. See
[`plotting/setfigsize.m`](plotting/setfigsize.m).

# Miscellaneous
- `str2num` is apparently effectively implemented as
`try; num = eval(str); catch; num = []; end` since a string which
happens to be a function name is executed:

```matlab
>> str2num('struct')

ans =

  struct with no fields.
```

[bracketed-paste]: https://cirw.in/blog/bracketed-paste
