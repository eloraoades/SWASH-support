function fig = figHs(Xp, Yp, Hs, outFile, opts)
%FIGHS_SIMPLE  Minimal Hs quicklook; generic, student-friendly.
%
% Usage
%   figHs_simple(Xp, Yp, Hs)
%   figHs_simple(Xp, Yp, Hs, outFile)
%   figHs_simple(Xp, Yp, Hs, outFile, opts)
%
% Inputs
%   Xp, Yp : grid (same size as Hs)
%   Hs     : significant wave height [m], 2D
%   outFile: optional image path (PNG/JPG/PDF). If empty, no save.
%   opts   : struct (all optional)
%            .cmap      (default 'turbo')
%            .clim      (default [0, roundUp(max(Hs))])
%            .method    (default 'imagesc'; alt 'pcolor')
%            .equal     (default true)
%            .title     (default 'Significant Wave Height')
%            .refLineY  (default []) horizontal y(m) line(s)
%            .refLineX  (default []) vertical x(m) line(s)
%            .lineStyle (default '-')
%            .lineWidth (default 1)
%            .lineColor (default [0 0 0])
%            .res       (default 200) export resolution DPI
%
% Output
%   fig : figure handle

if nargin < 4, outFile = ''; end
if nargin < 5, opts = struct(); end
if ~isfield(opts,'cmap'),      opts.cmap = 'turbo'; end
if ~isfield(opts,'method'),    opts.method = 'imagesc'; end
if ~isfield(opts,'equal'),     opts.equal = true; end
if ~isfield(opts,'title'),     opts.title = 'Significant Wave Height'; end
if ~isfield(opts,'refLineY'),  opts.refLineY = []; end
if ~isfield(opts,'refLineX'),  opts.refLineX = []; end
if ~isfield(opts,'lineStyle'), opts.lineStyle = '-'; end
if ~isfield(opts,'lineWidth'), opts.lineWidth = 1; end
if ~isfield(opts,'lineColor'), opts.lineColor = [0 0 0]; end
if ~isfield(opts,'res'),       opts.res = 200; end

% Auto color limits rounded to neat 0.5 m (why: easier to compare figs)
if ~isfield(opts,'clim') || isempty(opts.clim)
    maxHS = max(Hs(:), [], 'omitnan');
    step = 0.5; vmax = step * ceil(maxHS/step);
    opts.clim = [0, max(0.5, vmax)];
end

fig = figure('Color','w');
ax = axes('Parent', fig); hold(ax,'on'); box(ax,'on');
colormap(ax, opts.cmap);

switch lower(opts.method)
    case 'pcolor'
        h = pcolor(ax, Xp, Yp, Hs); shading(ax,'interp');
    otherwise
        % Faster path for rectilinear grids
        h = imagesc(ax, 'XData', Xp(1,:), 'YData', Yp(:,1), 'CData', Hs);
        set(ax,'YDir','normal');
end
set(h,'AlphaData', ~isnan(Hs));                         % hide NaNs
clim(ax, opts.clim);
cb = colorbar(ax); cb.Label.String = 'H_s [m]';

if opts.equal, axis(ax,'equal'); end
axis(ax,'tight'); xlabel(ax,'x (m)'); ylabel(ax,'y (m)');

% Optional reference lines (why: transects/shoreline markers)
for yv = opts.refLineY(:)'
    line(ax, xlim(ax), [yv yv], 'Color', opts.lineColor, ...
        'LineStyle', opts.lineStyle, 'LineWidth', opts.lineWidth);
end
for xv = opts.refLineX(:)'
    line(ax, [xv xv], ylim(ax), 'Color', opts.lineColor, ...
        'LineStyle', opts.lineStyle, 'LineWidth', opts.lineWidth);
end

title(ax, sprintf('%s — %s', opts.title, datestr(now,'yyyy-mm-dd')));
set(ax,'Layer','top');

% Save if requested
if ~isempty(outFile)
    [p,~,~] = fileparts(outFile);
    if ~isempty(p) && ~exist(p,'dir'), mkdir(p); end
    try
        exportgraphics(ax, outFile, 'Resolution', opts.res);
    catch
        print(fig, outFile, sprintf('-r%d', opts.res), '-dpng');
    end
end
end