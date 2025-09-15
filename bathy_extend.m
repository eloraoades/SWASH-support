% File: bathy_extend.m
function [Out, fig1, fig2] = bathy_extend(xIn, yIn, zIn, toggle)
% bathy_extend extends a bathymetric domain by 25% on either lateral side,
% mirroring the edge profiles, and plots original vs. extended fields.
%
% INPUTS
%   xIn, yIn, zIn : regularly spaced grids (ny x nx), e.g., from meshgrid
%   toggle        : index offset for picking inward surveys
%
% OUTPUT
%   Out   : struct with fields x, y, z (all size nyNew x nx)
%   fig1  : figure handle of pcolor + contours
%   fig2  : figure handle of edge profiles
%
% WHY CHANGES:
% - Original code mixed cell-count extension (nExt) with metric extension (lExt)
%   and used vector step (dely = diff(y)), making Out.y length drift from Out.z.
% - Here we derive y strictly from the row count and scalar dy so sizes match.

% --- Validate shapes and spacing ---
[ny, nx] = size(zIn);
assert(isequal(size(xIn), [ny, nx]) && isequal(size(yIn), [ny, nx]), ...
    'xIn, yIn, zIn must be same size (ny x nx)');

xvec = xIn(1, :);
yvec = yIn(:, 1);

% Scalar spacings; guard regular grids.
dx = xvec(2) - xvec(1);
dy = yvec(2) - yvec(1);
if any(abs(diff(xvec) - dx) > 1e-9) || any(abs(diff(yvec) - dy) > 1e-9)
    error('xIn and yIn must be regularly spaced.');
end

% --- Pick edge profiles ---
last = ny;
idxTop = 1 + toggle;
idxBot = last - toggle;
assert(idxTop >= 1 && idxBot <= ny && idxTop < idxBot, 'toggle out of range');
upshore   = zIn(idxBot, :);
downshore = zIn(idxTop, :);

% --- Build extension via linear interpolation between edge profiles ---
% Even number of rows so we can split perfectly in half.
nExt = 2 * round(0.25 * ny);            % 25%% per side => 50%% total
nExt = max(nExt, 2);                     % ensure at least two rows to interpolate

folded_grid = nan(nExt, nx);
folded_grid(1,  :) = downshore;
folded_grid(end, :) = upshore;
folded_grid = fillmissing(folded_grid, 'linear', 1);  % along rows (y)

half = nExt / 2;
fold_up   = flipud(folded_grid(half+1:end, :));  % mirror for north side
fold_down = flipud(folded_grid(1:half,    :));   % mirror for south side

% --- Assemble extended z ---
OutZ = [fold_down; zIn; fold_up];
nyNew = size(OutZ, 1);

% --- Build x/y grids that MATCH OutZ size ---
% Derive y purely from count and dy to avoid off-by-one.
y0 = yvec(1) - half * dy;                % start at extended south edge
yNew = y0 + (0:nyNew-1).' * dy;          % column vector length nyNew

Out.x = repmat(xvec, nyNew, 1);
Out.y = repmat(yNew, 1, nx);
Out.z = OutZ;

% --- Figures ---
V = -4:1:0;

fig1 = figure();
T = tiledlayout(1,2);
T.TileSpacing = 'loose';
T.Padding = 'compact';

ax1 = nexttile();
pcolor(xIn, yIn, zIn); shading flat;
axis tight; axis equal; hold on;
[C,h] = contour(xIn, yIn, zIn, V, 'LineWidth', 0.5, 'Color', 'k');
clabel(C,h, 'labelspacing', 700);
hold off
ax1.FontSize = 13;
title('Original Bathy', 'FontSize', 13, 'FontWeight', 'normal');
xlabel('x [m]'); ylabel('y [m]');
clim([-15 2]);
set(ax1, 'Layer', 'top')

ax2 = nexttile();
pcolor(ax2, Out.x, Out.y, Out.z); shading flat;
axis tight; axis equal; hold on
ax2.FontSize = 13;
[C,h] = contour(Out.x, Out.y, Out.z, V, 'LineWidth', 0.5, 'Color', 'k');
clabel(C,h, 'labelspacing', 700);
title('Extended Bathy', 'FontSize', 13, 'FontWeight', 'normal');
xlabel('x [m]'); ylabel('y [m]');
clim([-15 2]);
set(ax2, 'Layer', 'top')

fig2 = figure();
T = tiledlayout(1,2);
T.TileSpacing = 'loose';
T.Padding = 'compact';

ax3 = nexttile();
plot(ax3, xIn(1,:), zIn(1,:), 'k-'); hold on; grid on; box on;
plot(ax3, xIn(end,:), zIn(end,:), 'r-');
xlabel('x [m]'); ylabel('z [m]');
legend1 = sprintf('y = %4.0f m', yIn(1,1));
legend2 = sprintf('y = %4.0f m', yIn(end,1));
legend(legend1, legend2);
title('Original Bathy','FontSize', 13, 'FontWeight', 'normal');

ax4 = nexttile();
plot(ax4, Out.x(1,:), Out.z(1,:), 'k-'); hold on; grid on; box on;
plot(ax4, Out.x(end,:), Out.z(end,:), 'r-');
xlabel('x [m]'); ylabel('z [m]');
legend1 = sprintf('y = %4.0f m', Out.y(1,1));
legend2 = sprintf('y = %4.0f m', Out.y(end,1));
legend(ax4, legend1, legend2);
title('Extended Bathy','FontSize', 13, 'FontWeight', 'normal');

end
