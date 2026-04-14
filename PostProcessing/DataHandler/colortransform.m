function Zt = colortransform(Z, ticks_orig, cbTicks)
%COLORTRANSFORM Map values in Z to discrete values in cbTicks
%
% Zt = colortransform(Z, ticks_orig, cbTicks)
%
% Inputs:
%   Z         - input vector / matrix
%   ticks_orig - threshold values in ascending order
%   cbTicks   - discrete output values, length = length(ticks_orig)+1
%
% Example:
%   ticks_orig = [-1e-8 -1e-9 -1e-10 1e-10 1e-9 1e-8];
%   cbTicks    = [-3 -2 -1 0 1 2 3];
%   Zt = colortransform(Z, ticks_orig, cbTicks);

    % Basic checks
    if ~isvector(ticks_orig) || ~isvector(cbTicks)
        error('ticks_orig and cbTicks must be vectors.');
    end

    ticks_orig = ticks_orig(:).';   % force row vector
    cbTicks    = cbTicks(:).';      % force row vector

    if numel(cbTicks) ~= numel(ticks_orig) + 1
        error('Length of cbTicks must be length(ticks_orig)+1.');
    end

    if any(diff(ticks_orig) <= 0)
        error('ticks_orig must be strictly increasing.');
    end

    % Build bin edges
    edges = [-inf, ticks_orig, inf];

    % Bin assignment:
    % (-inf, ticks_orig(1)]        -> cbTicks(1)
    % (ticks_orig(1), ticks_orig(2)] -> cbTicks(2)
    % ...
    % (ticks_orig(end), inf]       -> cbTicks(end)
    bin = discretize(Z, edges, 'IncludedEdge', 'right');

    % Map bin index to cbTicks value
    Zt = cbTicks(bin);
end
