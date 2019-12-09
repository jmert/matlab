function tex = num2powtex(v, ndigits, base)
% tex = num2powtex(v, ndigits, base)
%
% Converts the values in v to strings representing the value in scientific
% notation using TeX formatting. The fractional part will be shown using
% ndigits of decimal points (defaulting to 0), and the base may be given
% (defaulting to base 10).
%

  if ~exist('ndigits','var') || isempty(ndigits)
    ndigits = 0;
  end
  if ~exist('base','var') || isempty(base)
    base = 10;
  end

  v = cvec(v);
  tex = cell(length(v), 1);
  for ii = 1:length(v)
    if v(ii) == 0
      tex{ii} = '0';
      continue
    end
    pow = floor(log(abs(v(ii))) / log(base));
    frac = round(v(ii) / (base ^ pow), ndigits);
    if abs(frac) == base
      pow = pow + 1;
      frac = 1;
    end
    if abs(frac) == 1
      s = ifelse(frac < 0, '-', '');
      tex{ii} = sprintf('%s%i^{%i}', s, base, pow);
    else
      tex{ii} = sprintf('%0.*f \\cdot %i^{%i}', ndigits, frac, base, pow);
    end
  end

  if length(tex) == 1
    tex = tex{1};
  end
end
