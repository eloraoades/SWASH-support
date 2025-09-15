function fig = watlevMovie(etaAll, Xp, Yp, t, outFile, opts)
%WATLEVMOVIE_SIMPLE Water-level movie from SWASH outputs & 
% exports an MP4 via VideoWriter.
%
% Usage
% watlevMovie_simple(etaAll, Xp, Yp, t)
% watlevMovie_simple(etaAll, Xp, Yp, t, outFile)
% watlevMovie_simple(etaAll, Xp, Yp, t, outFile, opts)
%
% Inputs
% etaAll : [T x X x Y] water levels (meters)
% Xp,Yp : grid (same X,Y size as squeeze(etaAll(1,:,:)))
% t : time vector (seconds) length T (optional; used for title)
% outFile : MP4 path (default 'swash_watlev.mp4')
% opts : struct (all optional)
% .fps (default 20)
% .clim (default symmetric auto)
% .frames (default 1:T)
% .cmap (default 'parula')
% .method (default 'imagesc'; alt 'pcolor')
% .quality (default 75, MPEG-4)
%
% Output
% fig : figure handle


if nargin < 5 || isempty(outFile), outFile = 'swash_watlev.mp4'; end
if nargin < 6, opts = struct(); end
if ~isfield(opts,'fps'), opts.fps = 20; end
if ~isfield(opts,'cmap'), opts.cmap = 'parula'; end
if ~isfield(opts,'method'), opts.method = 'imagesc'; end
if ~isfield(opts,'quality'), opts.quality = 75; end

T = size(etaAll,1);
if ~isfield(opts,'frames') || isempty(opts.frames), opts.frames = 1:T; end
if nargin < 4 || isempty(t), t = (0:T-1)'; end

% Symmetric color limits around zero 
if ~isfield(opts,'clim') || isempty(opts.clim)
    maxabs = max(abs(etaAll(:)), [], 'omitnan');
    step = 0.5; % round to neat 0.5 m
    vmax = step * ceil(maxabs/step);
    opts.clim = [-vmax, vmax];
end


% Figure
fig = figure('Color', 'w');
ax = axes('Parent', fig); hold(ax,'on'); box(ax,'on');
axis(ax,'equal'); axis(ax,'tight');
colormap(ax, opts.cmap);
clim(ax, opts.clim);
xlabel(ax,'x (m)'); ylabel(ax,'y (m)');
cb = colorbar(ax); cb.Label.String = '\eta (m)';
set(fig, 'Renderer', 'zbuffer');

% First frame
F0 = squeeze(etaAll(opts.frames(1),:,:));

switch lower(opts.method)
    case 'pcolor'
        hImg = pcolor(ax, Xp, Yp, F0); shading(ax,'flat');
end