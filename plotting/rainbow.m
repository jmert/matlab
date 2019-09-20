function varargout=rainbow(n)
% cmap=rainbow(n)
%
% Generates the rainbow colormap from Python colorcet library.
%

  if ~exist('n','var') || isempty(n)
    n = 256;
  end

  %{
  import colorcet as cc
  import numpy as np

  def hex2rgb(h):
      h = h.lstrip('#')
      r = int(h[0:2], base = 16)
      g = int(h[2:4], base = 16)
      b = int(h[4:6], base = 16)
      return (r, g, b)

  for v in map(hex2rgb, cc.rainbow):
      print(f"{v[0]:3}, {v[1]:3}, {v[2]:3}")
  %}
  cmap = [
            0,  52, 248
            0,  55, 246
            0,  58, 243
            0,  61, 240
            0,  63, 237
            0,  65, 234
            0,  68, 231
            0,  70, 228
            0,  72, 225
            0,  74, 222
            0,  76, 219
            0,  79, 216
            0,  81, 213
            0,  83, 210
            0,  84, 208
            0,  86, 205
            0,  88, 202
            0,  90, 199
            0,  92, 196
            0,  94, 193
            0,  96, 190
            0,  97, 187
            0,  99, 184
            0, 101, 182
            0, 102, 179
            0, 104, 176
            0, 106, 173
            0, 107, 170
            0, 109, 167
            0, 110, 165
            0, 111, 162
            0, 113, 159
            0, 114, 157
            0, 115, 154
            0, 117, 152
            0, 118, 149
            7, 119, 147
           13, 120, 144
           19, 121, 142
           24, 122, 139
           28, 123, 137
           31, 124, 135
           35, 125, 132
           38, 126, 130
           40, 127, 127
           43, 128, 125
           45, 129, 123
           47, 130, 120
           49, 131, 118
           50, 132, 115
           52, 133, 113
           53, 134, 111
           54, 135, 108
           55, 136, 106
           56, 137, 103
           57, 138, 101
           58, 139,  98
           59, 140,  96
           60, 142,  93
           60, 143,  91
           61, 144,  88
           61, 145,  85
           62, 146,  83
           62, 147,  80
           62, 148,  77
           62, 149,  74
           62, 150,  71
           63, 151,  69
           63, 152,  66
           62, 153,  62
           62, 154,  59
           62, 155,  56
           62, 156,  53
           62, 157,  50
           62, 158,  46
           62, 159,  43
           63, 160,  39
           63, 161,  36
           64, 162,  33
           65, 163,  29
           66, 164,  26
           68, 165,  23
           69, 166,  21
           71, 167,  19
           74, 167,  17
           76, 168,  15
           79, 169,  14
           81, 169,  13
           84, 170,  13
           87, 171,  13
           90, 171,  13
           93, 172,  13
           95, 173,  13
           98, 173,  14
          101, 174,  14
          103, 174,  14
          106, 175,  15
          109, 176,  15
          111, 176,  15
          114, 177,  16
          116, 177,  16
          119, 178,  17
          121, 178,  17
          124, 179,  17
          126, 180,  18
          128, 180,  18
          131, 181,  18
          133, 181,  19
          136, 182,  19
          138, 182,  19
          140, 183,  20
          143, 184,  20
          145, 184,  21
          147, 185,  21
          149, 185,  21
          152, 186,  22
          154, 186,  22
          156, 187,  22
          159, 187,  23
          161, 188,  23
          163, 188,  24
          165, 189,  24
          167, 190,  24
          170, 190,  25
          172, 191,  25
          174, 191,  25
          176, 192,  26
          178, 192,  26
          181, 193,  27
          183, 193,  27
          185, 194,  27
          187, 194,  28
          189, 195,  28
          192, 195,  28
          194, 196,  29
          196, 196,  29
          198, 197,  29
          200, 197,  30
          202, 198,  30
          205, 198,  31
          207, 199,  31
          209, 199,  31
          211, 200,  32
          213, 200,  32
          215, 201,  32
          217, 201,  33
          220, 202,  33
          222, 202,  34
          224, 202,  34
          226, 203,  34
          228, 203,  35
          230, 204,  35
          232, 204,  35
          234, 204,  36
          236, 205,  36
          238, 205,  36
          240, 205,  36
          242, 205,  36
          243, 205,  36
          245, 204,  36
          246, 204,  36
          248, 203,  36
          249, 202,  36
          249, 201,  35
          250, 200,  35
          251, 199,  34
          251, 198,  34
          252, 197,  33
          252, 196,  33
          252, 194,  32
          253, 193,  32
          253, 192,  31
          253, 190,  31
          253, 189,  30
          254, 187,  29
          254, 186,  29
          254, 185,  28
          254, 183,  27
          254, 182,  27
          254, 181,  26
          255, 179,  26
          255, 178,  25
          255, 176,  24
          255, 175,  24
          255, 174,  23
          255, 172,  22
          255, 171,  22
          255, 169,  21
          255, 168,  21
          255, 167,  20
          255, 165,  19
          255, 164,  19
          255, 162,  18
          255, 161,  17
          255, 159,  16
          255, 158,  16
          255, 156,  15
          255, 155,  14
          255, 154,  14
          255, 152,  13
          255, 151,  12
          255, 149,  11
          255, 148,  11
          255, 146,  10
          255, 145,   9
          255, 143,   8
          255, 142,   8
          255, 140,   7
          255, 139,   6
          255, 137,   5
          255, 136,   5
          255, 134,   4
          255, 132,   4
          255, 131,   3
          255, 129,   2
          255, 128,   2
          255, 126,   1
          255, 124,   1
          255, 123,   0
          255, 121,   0
          255, 120,   0
          255, 118,   0
          255, 116,   0
          255, 114,   0
          255, 113,   0
          255, 111,   0
          255, 109,   0
          255, 108,   0
          255, 106,   0
          255, 104,   0
          255, 102,   0
          255, 100,   0
          255,  98,   0
          255,  97,   0
          255,  95,   0
          255,  93,   0
          255,  91,   0
          255,  89,   0
          255,  87,   0
          255,  85,   0
          255,  83,   0
          255,  80,   0
          255,  78,   0
          255,  76,   0
          255,  74,   0
          255,  71,   0
          255,  69,   0
          255,  66,   0
          255,  64,   0
          255,  61,   0
          255,  58,   0
          255,  55,   0
          255,  52,   0
          255,  49,   0
          255,  45,   0
          255,  42,   0
          ] ./ 255;

  if n ~= size(cmap, 1)
    cmap = colormap_interp(cmap, n);
  end
  if nargout == 0
    colormap(cmap);
  else
    varargout{1} = cmap;
  end
end

